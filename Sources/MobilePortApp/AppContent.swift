import SwiftUI
import RealityKit

@main
struct MobilePortApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            SandboxLobbyView()
        }
    }
}

@MainActor
final class SandboxViewModel: ObservableObject {
    @Published var room: SandboxRoom?
    let session: InProcessSandboxSession
    @Published var playerName = "Speler"
    @Published var roomCode = ""
    @Published var statusMessage = "Kies een kamer"

    init(session: InProcessSandboxSession = InProcessSandboxSession(capacity: 2)) {
        self.session = session
    }

    func joinOrCreate() {
        room = session.joinOrCreate(playerName: playerName)
        statusMessage = "Kamer \(room?.id ?? "") is gereed"
    }

    func joinCode() {
        guard !roomCode.isEmpty,
              let joined = session.join(roomID: roomCode.uppercased(), playerName: playerName) else {
            statusMessage = "Kamer niet gevonden of vol"
            return
        }
        room = joined
        statusMessage = "Verbonden met \(joined.id)"
    }

    func refresh() {
        room = session.roomSnapshot()
    }

    func claimCrane() {
        guard let player = room?.world.players.first,
              session.claimCrane(playerID: player.id) else {
            statusMessage = "Kraan is bezet"
            return
        }
        refresh()
        statusMessage = "Kraan geclaimed"
    }

    func lift(_ container: SandboxContainer) {
        guard session.liftContainer(craneID: "kraan-1", containerID: container.id) else {
            statusMessage = "Claim eerst de kraan en kies een bron"
            return
        }
        refresh()
        statusMessage = "\(container.source.title) opgetild"
    }

    func moveLeft() {
        guard let room else { return }
        session.setCranePhase(craneID: "kraan-1", phase: .moving)
        if var crane = room.world.cranes.first {
            crane.positionX = max(-3.5, crane.positionX - 0.8)
            crane.phase = .moving
            var world = room.world
            world.cranes[0] = crane
            session.updateWorld(world)
        }
        refresh()
        statusMessage = "Kraan beweegt"
    }

    func moveRight() {
        guard let room else { return }
        session.setCranePhase(craneID: "kraan-1", phase: .moving)
        if var crane = room.world.cranes.first {
            crane.positionX = min(3.5, crane.positionX + 0.8)
            crane.phase = .moving
            var world = room.world
            world.cranes[0] = crane
            session.updateWorld(world)
        }
        refresh()
        statusMessage = "Kraan beweegt"
    }

    func requestHelp(_ kind: HelpRequestKind) {
        guard let player = room?.world.players.first else { return }
        if session.addHelpRequest(playerID: player.id, kind: kind) {
            refresh()
            statusMessage = "Behoefte gedeeld: \(kind.title)"
        } else {
            statusMessage = "Maximum van twee actieve verzoeken bereikt"
        }
    }

    func vote(_ decision: HarborUpgradeDecision) {
        if session.voteUpgrade(decisionID: decision.id) {
            refresh()
            statusMessage = "Stem toegevoegd: \(decision.title)"
        }
    }

    func verifyLower(_ destination: HarborDestination) {
        guard let room else { return }
        guard var crane = room.world.cranes.first,
              crane.heldContainerID != nil else {
            statusMessage = "Til eerst een container"
            return
        }
        crane.phase = .verifying
        var world = room.world
        world.cranes[0] = crane
        session.updateWorld(world)
        guard session.lowerContainer(craneID: "kraan-1", destination: destination) else {
            statusMessage = "Losactie is niet geldig"
            return
        }
        refresh()
        statusMessage = "Container gelost op \(destination.title)"
    }
}

struct SandboxLobbyView: View {
    @StateObject private var model = SandboxViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.13, blue: 0.17).ignoresSafeArea()
                if let room = model.room {
                    SandboxWorldView(model: model, room: room)
                } else {
                    LobbyView(model: model)
                }
            }
        }
        .task {
            if model.room == nil {
                model.joinOrCreate()
            }
        }
    }
}

struct LobbyView: View {
    @ObservedObject var model: SandboxViewModel

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("HAVENWERK")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Cooperatieve haven")
                .foregroundStyle(.cyan)

            TextField("Spelernaam", text: $model.playerName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)

            Button("Nieuwe of vrije kamer") {
                model.joinOrCreate()
            }
            .buttonStyle(.borderedProminent)

            HStack {
                TextField("Kamercode", text: $model.roomCode)
                    .textInputAutocapitalization(.characters)
                    .textFieldStyle(.roundedBorder)
                Button("Join") {
                    model.joinCode()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: 420)

            Text(model.statusMessage)
                .foregroundStyle(.yellow)
                .frame(minHeight: 24)
            Spacer()
        }
        .padding()
    }
}

struct SandboxWorldView: View {
    @ObservedObject var model: SandboxViewModel
    let room: SandboxRoom
    @State private var showHelp = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label(room.id, systemImage: "person.3.fill")
                Spacer()
                Label("\(room.world.players.count)/\(room.capacity)", systemImage: "person.fill")
                Label("\(room.world.deliveredCount)", systemImage: "shippingbox.fill")
            }
            .foregroundStyle(.white)
            .padding(.horizontal)

            Text(model.statusMessage)
                .foregroundStyle(.yellow)
                .frame(height: 24)

            HarborScene(world: room.world)
                .frame(maxWidth: 720, minHeight: 280, maxHeight: 420)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

            HStack {
                Button("Claim kraan") { model.claimCrane() }
                Button("Links") { model.moveLeft() }
                Button("Rechts") { model.moveRight() }
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 10) {
                ForEach(room.world.containers.filter {
                    if case .source = $0.location { return true }
                    return false
                }) { container in
                    Button(container.source.title) {
                        model.lift(container)
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 12) {
                ForEach(HarborDestination.allCases, id: \.self) { destination in
                    Button("Los op \(destination.title)") {
                        model.verifyLower(destination)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    dashboardItem("Doorvoer", "\(room.world.metrics.throughput)")
                    dashboardItem("Wacht", "\(room.world.metrics.averageWaitSeconds)s")
                    dashboardItem("Energie", "\(room.world.metrics.energyUsed)")
                    dashboardItem("Storingen", "\(room.world.metrics.incidents)")
                    dashboardItem("Score", "\(room.world.metrics.harborScore)")
                }
                .padding(.horizontal)
            }

            HStack {
                Button("Request Help") {
                    showHelp = true
                }
                .buttonStyle(.bordered)

                ForEach(room.world.helpRequests.prefix(4)) { request in
                    Label(request.kind.title, systemImage: request.kind.symbolName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.yellow.opacity(0.18))
                        .clipShape(Capsule())
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.bottom, 10)
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                List {
                    ForEach(HelpRequestKind.allCases, id: \.self) { kind in
                        Button {
                            model.requestHelp(kind)
                            showHelp = false
                        } label: {
                            Label(kind.title, systemImage: kind.symbolName)
                        }
                    }
                }
                .navigationTitle("Behoefte melden")
            }
        }
    }

    @ViewBuilder
    private func dashboardItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
            Text(value)
                .font(.headline)
        }
        .foregroundStyle(.white)
        .frame(width: 82, height: 44)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HarborScene: View {
    let world: SandboxWorld

    var body: some View {
        RealityView { content in
            let worldEntity = Entity()
            worldEntity.name = "sandbox-world"
            let camera = PerspectiveCamera()
            camera.position = [0, 7.2, 8.8]
            camera.transform.rotation = simd_quatf(angle: -.pi / 4.8, axis: [1, 0, 0])
            worldEntity.addChild(camera)

            let asphalt = HarborScene.makeBox([12, 0.12, 7], [0, -0.06, 0], .init(red: 0.18, green: 0.19, blue: 0.20, alpha: 1))
            worldEntity.addChild(asphalt)
            worldEntity.addChild(HarborScene.makeBox([12, 0.08, 2.8], [0, -0.02, -4.8], .init(red: 0.12, green: 0.34, blue: 0.43, alpha: 1)))
            worldEntity.addChild(HarborScene.makeBox([12, 0.35, 0.35], [0, 0.12, -3.35], .init(red: 0.46, green: 0.48, blue: 0.48, alpha: 1)))

            for (index, source) in HarborSource.allCases.enumerated() {
                let x = Float(index) * 3.5 - 3.5
                worldEntity.addChild(HarborScene.makeBox([2.4, 0.22, 0.7], [x, 0.12, -4.75], HarborScene.sourceColor(source)))
            }

            worldEntity.addChild(HarborScene.makeBox([2.2, 0.10, 1.4], [-2.8, 0.04, 2.2], HarborScene.destinationColor(.train)))
            worldEntity.addChild(HarborScene.makeBox([2.2, 0.10, 1.4], [2.8, 0.04, 2.2], HarborScene.destinationColor(.truck)))
            worldEntity.addChild(HarborScene.makeCommandBoard(metrics: world.metrics))

            let cranePosition = world.cranes.first?.positionX ?? 0
            worldEntity.addChild(HarborScene.makeCrane(positionX: Float(cranePosition)))
            content.add(worldEntity)
        } update: { content in
            guard let worldEntity = content.entities.first(where: { $0.name == "sandbox-world" }) else { return }
            worldEntity.children.removeAll {
                $0.name.hasPrefix("container-") ||
                $0.name == "live-crane" ||
                $0.name == "command-board"
            }

            let cranePosition = world.cranes.first?.positionX ?? 0
            worldEntity.addChild(HarborScene.makeCrane(positionX: Float(cranePosition)))
            worldEntity.addChild(HarborScene.makeCommandBoard(metrics: world.metrics))

            for container in world.containers {
                let position: SIMD3<Float>
                switch container.location {
                case .source(let source):
                    let sourceIndex = HarborSource.allCases.firstIndex(of: source) ?? 0
                    position = [Float(sourceIndex) * 3.5 - 3.5, 0.45, -4.2]
                case .crane:
                    position = [Float(cranePosition), 1.15, -1.5]
                case .destination(let destination):
                    position = destination == .train ? [-2.8, 0.45, 1.7] : [2.8, 0.45, 1.7]
                }
                let entity = HarborScene.makeBox([1.0, 0.55, 0.55], position, HarborScene.sourceColor(container.source))
                entity.name = "container-\(container.id.uuidString)"
                worldEntity.addChild(entity)
            }
        }
    }

    static func makeBox(_ size: SIMD3<Float>, _ position: SIMD3<Float>, _ color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size)
        let material = UnlitMaterial(color: color)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }

    static func makeCommandBoard(metrics: HarborMetrics) -> Entity {
        let board = Entity()
        board.name = "command-board"
        board.position = [0, 0.55, 3.0]
        board.addChild(makeBox([4.6, 0.12, 1.15], [0, 0.8, 0], UIColor(red: 0.16, green: 0.20, blue: 0.22, alpha: 1)))

        let scoreColor = UIColor(red: 0.38, green: 0.58, blue: 0.42, alpha: 1)
        let score = makeBox([1.2, 0.08, 0.18], [-1.2, 1.42, 0], scoreColor)
        board.addChild(score)

        let throughput = makeBox([1.2, 0.08, 0.18], [0, 1.42, 0], HarborScene.destinationColor(.train))
        board.addChild(throughput)

        let energy = makeBox([1.2, 0.08, 0.18], [1.2, 1.42, 0], HarborScene.destinationColor(.truck))
        board.addChild(energy)
        return board
    }

    static func makeCrane(positionX: Float) -> Entity {
        let crane = Entity()
        crane.name = "live-crane"
        crane.position = [positionX, 0, -1.0]
        crane.addChild(makeBox([0.16, 2.2, 0.16], [-0.8, 1.1, 0], UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1)))
        crane.addChild(makeBox([0.16, 2.2, 0.16], [0.8, 1.1, 0], UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1)))
        crane.addChild(makeBox([2.2, 0.18, 0.18], [0, 2.15, 0], UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1)))
        return crane
    }

    static func sourceColor(_ source: HarborSource) -> UIColor {
        switch source {
        case .barge: return UIColor(red: 0.38, green: 0.50, blue: 0.55, alpha: 1)
        case .shortsea: return UIColor(red: 0.11, green: 0.34, blue: 0.50, alpha: 1)
        case .deepsea: return UIColor(red: 0.16, green: 0.25, blue: 0.31, alpha: 1)
        }
    }

    static func destinationColor(_ destination: HarborDestination) -> UIColor {
        switch destination {
        case .train: return UIColor(red: 0.70, green: 0.36, blue: 0.13, alpha: 1)
        case .truck: return UIColor(red: 0.62, green: 0.18, blue: 0.12, alpha: 1)
        }
    }
}
