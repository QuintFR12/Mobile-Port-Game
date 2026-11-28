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
    @Published var selectedContainerID: UUID?
    @Published var selectedDestination: HarborDestination?

    init(session: InProcessSandboxSession = InProcessSandboxSession(capacity: 2)) {
        self.session = session
    }

    func joinOrCreate() {
        room = session.joinOrCreate(playerName: playerName)
        statusMessage = "Neem de kraan in gebruik om te beginnen."
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
        statusMessage = "Kraan in gebruik. Kies een container bij een schip."
    }

    var playerID: String? { room?.world.players.first?.id }
    var crane: SandboxCrane? { room?.world.cranes.first }
    var hasCrane: Bool { playerID != nil && crane?.ownerPlayerID == playerID }
    var selectedContainer: SandboxContainer? {
        room?.world.containers.first(where: { $0.id == selectedContainerID })
    }

    func selectContainer(_ container: SandboxContainer) {
        guard hasCrane, crane?.heldContainerID == nil, case .source = container.location else { return }
        selectedContainerID = container.id
        selectedDestination = nil
        statusMessage = "Container van \(container.source.title) gekozen. Verplaats de kraan naar het schip."
    }

    func moveToSource() {
        guard let playerID, let container = selectedContainer,
              session.moveCrane(craneID: "kraan-1", playerID: playerID, to: container.location) else {
            statusMessage = "Kies eerst een beschikbare container en neem de kraan in gebruik."
            return
        }
        refresh()
        statusMessage = "Kraan bij \(container.source.title). Hef nu de container."
    }

    func lift() {
        guard let playerID, let container = selectedContainer,
              session.liftContainer(craneID: "kraan-1", playerID: playerID, containerID: container.id) else {
            statusMessage = "Verplaats de kraan eerst naar de gekozen container."
            return
        }
        refresh()
        statusMessage = "Container van \(container.source.title) hangt aan de kraan. Kies een bestemming."
    }

    func selectDestination(_ destination: HarborDestination) {
        guard hasCrane, crane?.heldContainerID != nil else { return }
        selectedDestination = destination
        statusMessage = "Bestemming \(destination.title) gekozen. Verplaats de kraan met de container."
    }

    func moveToDestination() {
        guard let playerID, let destination = selectedDestination,
              session.moveCrane(craneID: "kraan-1", playerID: playerID, to: .destination(destination)) else {
            statusMessage = "Hef eerst een container en kies een bestemming."
            return
        }
        refresh()
        statusMessage = "Container bij \(destination.title). Los de container."
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

    func lower() {
        guard let playerID, let destination = selectedDestination,
              session.lowerContainer(craneID: "kraan-1", playerID: playerID, destination: destination) else {
            statusMessage = "Verplaats de container eerst naar de gekozen bestemming."
            return
        }
        refresh()
        selectedContainerID = nil
        selectedDestination = nil
        statusMessage = "Container gelost op \(destination.title). Kies een volgende container."
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
                .font(.subheadline)
                .foregroundStyle(.yellow)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 40)
                .padding(.horizontal)

            HarborScene(world: room.world)
                .frame(maxWidth: 720, minHeight: 180, maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

            if !model.hasCrane {
                Button("1. Neem kraan in gebruik") { model.claimCrane() }
                    .buttonStyle(.borderedProminent)
            } else if model.crane?.heldContainerID == nil {
                Text("2. Kies een container bij een schip")
                    .foregroundStyle(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(room.world.containers.filter {
                            if case .source = $0.location { return true }
                            return false
                        }) { container in
                            Button(model.selectedContainerID == container.id
                                   ? "Gekozen: \(container.source.title)"
                                   : "Container: \(container.source.title)") {
                                model.selectContainer(container)
                            }
                            .buttonStyle(.bordered)
                            .tint(model.selectedContainerID == container.id ? .yellow : .cyan)
                        }
                    }
                    .padding(.horizontal)
                }
                .fixedSize(horizontal: false, vertical: true)
                if let container = model.selectedContainer, let position = container.location.position {
                    if model.crane?.positionX == position.x && model.crane?.positionZ == position.z {
                        Button("3. Hef container") { model.lift() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("3. Verplaats kraan naar \(container.source.title)") { model.moveToSource() }
                            .buttonStyle(.borderedProminent)
                    }
                } else if !room.world.containers.contains(where: {
                    if case .source = $0.location { return true }
                    return false
                }) {
                    Text("Alle containers zijn gelost.").foregroundStyle(.white)
                }
            } else {
                Text("4. Kies een bestemming voor de container")
                    .foregroundStyle(.white)
                HStack(spacing: 12) {
                    ForEach(HarborDestination.allCases, id: \.self) { destination in
                        Button(model.selectedDestination == destination ? "Gekozen: \(destination.title)" : destination.title) {
                            model.selectDestination(destination)
                        }
                            .buttonStyle(.bordered)
                            .tint(model.selectedDestination == destination ? .yellow : .cyan)
                    }
                }
                if let destination = model.selectedDestination,
                   let position = SandboxLocation.destination(destination).position {
                    if model.crane?.phase == .moving,
                       model.crane?.positionX == position.x && model.crane?.positionZ == position.z {
                        Button("6. Los container op \(destination.title)") { model.lower() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("5. Verplaats container naar \(destination.title)") { model.moveToDestination() }
                            .buttonStyle(.borderedProminent)
                    }
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
                Button("Vraag hulp") {
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
            let craneZ = world.cranes.first?.positionZ ?? -1
            worldEntity.addChild(HarborScene.makeCrane(positionX: Float(cranePosition), positionZ: Float(craneZ)))
            content.add(worldEntity)
        } update: { content in
            guard let worldEntity = content.entities.first(where: { $0.name == "sandbox-world" }) else { return }
            worldEntity.children.removeAll {
                $0.name.hasPrefix("container-") ||
                $0.name == "live-crane" ||
                $0.name == "command-board"
            }

            let cranePosition = world.cranes.first?.positionX ?? 0
            let craneZ = world.cranes.first?.positionZ ?? -1
            worldEntity.addChild(HarborScene.makeCrane(positionX: Float(cranePosition), positionZ: Float(craneZ)))
            worldEntity.addChild(HarborScene.makeCommandBoard(metrics: world.metrics))

            var destinationCounts: [HarborDestination: Int] = [:]
            for container in world.containers {
                let position: SIMD3<Float>
                switch container.location {
                case .source:
                    guard let point = container.location.position else { continue }
                    position = [Float(point.x), 0.45, Float(point.z)]
                case .crane:
                    position = [Float(cranePosition), 1.55, Float(craneZ)]
                case .destination(let destination):
                    guard let point = container.location.position else { continue }
                    let count = destinationCounts[destination, default: 0]
                    destinationCounts[destination] = count + 1
                    position = [Float(point.x), 0.38 + Float(count) * 0.55, Float(point.z)]
                }
                let entity = HarborScene.makeBox([1.0, 0.55, 0.55], position, HarborScene.containerColor(container.source))
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

    static func makeCrane(positionX: Float, positionZ: Float) -> Entity {
        let crane = Entity()
        crane.name = "live-crane"
        crane.position = [positionX, 0, positionZ]
        crane.addChild(makeBox([0.16, 2.2, 0.16], [-0.8, 1.1, 0], UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1)))
        crane.addChild(makeBox([0.16, 2.2, 0.16], [0.8, 1.1, 0], UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1)))
        crane.addChild(makeBox([2.2, 0.18, 0.18], [0, 2.15, 0], UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1)))
        crane.addChild(makeBox([0.05, 0.24, 0.05], [0, 1.96, 0], .lightGray))
        return crane
    }

    static func sourceColor(_ source: HarborSource) -> UIColor {
        switch source {
        case .barge: return UIColor(red: 0.38, green: 0.50, blue: 0.55, alpha: 1)
        case .shortsea: return UIColor(red: 0.11, green: 0.34, blue: 0.50, alpha: 1)
        case .deepsea: return UIColor(red: 0.16, green: 0.25, blue: 0.31, alpha: 1)
        }
    }

    static func containerColor(_ source: HarborSource) -> UIColor {
        switch source {
        case .barge: return UIColor(red: 0.71, green: 0.83, blue: 0.86, alpha: 1)
        case .shortsea: return UIColor(red: 0.23, green: 0.66, blue: 0.88, alpha: 1)
        case .deepsea: return UIColor(red: 0.56, green: 0.64, blue: 0.76, alpha: 1)
        }
    }

    static func destinationColor(_ destination: HarborDestination) -> UIColor {
        switch destination {
        case .train: return UIColor(red: 0.70, green: 0.36, blue: 0.13, alpha: 1)
        case .truck: return UIColor(red: 0.62, green: 0.18, blue: 0.12, alpha: 1)
        }
    }
}
