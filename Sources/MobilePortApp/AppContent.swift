import SwiftUI
import Foundation
import Combine
import RealityKit

@main
struct MobilePortApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}

struct MainMenuView: View {
    @State private var selectedMode: GameMode?
    @State private var showingProfile = false
    @State private var profile = UserProfileStore.load()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.09, green: 0.16, blue: 0.24).ignoresSafeArea()
                VStack(spacing: 22) {
                    Spacer()
                    Button {
                        showingProfile = true
                    } label: {
                        HStack(spacing: 12) {
                            AvatarPreview(profile: profile)
                                .frame(width: 72, height: 72)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Eigen avatar")
                                    .font(.headline)
                                Text("Lokale profielfoto maken")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 420)
                        .padding(12)
                        .background(.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    Text("HAVENLOODS")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Industrial haventerminal")
                        .foregroundStyle(.cyan.opacity(0.9))

                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Button {
                            selectedMode = mode
                        } label: {
                            VStack(spacing: 4) {
                                Text(mode.title)
                                    .font(.headline)
                                Text(modeDescription(mode))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: 420)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }

                    Spacer()
                    Text("Eigen vormen en kleuren")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding()
            }
            .navigationDestination(item: $selectedMode) { mode in
                GameView(mode: mode)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileEditorView(profile: $profile)
            }
        }
    }

    private func modeDescription(_ mode: GameMode) -> String {
        switch mode {
        case .casual:
            return "Spel rustig door, zonder tijdsdruk"
        case .competitive:
            return "90 seconden, vaste startsituatie"
        case .roguelike:
            return "4-6 rondes met tijdelijke upgrades"
        }
    }
}

enum UserProfileStore {
    static let key = "mobilePortUserProfile"

    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    static func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

struct AvatarPreview: View {
    let profile: UserProfile

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)

            RoundedRectangle(cornerRadius: 7)
                .fill(containerColor)
                .frame(width: 34, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(.white.opacity(0.65), lineWidth: 1)
                )
                .offset(y: 10)

            Text(profile.initials.isEmpty ? "MP" : profile.initials)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .offset(y: 10)

            Image(systemName: profile.craneSymbol.sfSymbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(6)
                .background(.black.opacity(0.35), in: Circle())
                .offset(x: 21, y: -20)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var backgroundColor: Color {
        switch profile.background {
        case .harbor: return Color(red: 0.12, green: 0.34, blue: 0.43)
        case .asphalt: return Color(red: 0.20, green: 0.22, blue: 0.23)
        case .dusk: return Color(red: 0.28, green: 0.24, blue: 0.38)
        }
    }

    private var containerColor: Color {
        switch profile.containerColor {
        case .orange: return .orange
        case .blue: return .blue
        case .green: return .green
        case .graphite: return .gray
        }
    }
}

struct ProfileEditorView: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfile

    init(profile: Binding<UserProfile>) {
        _profile = profile
        _draft = State(initialValue: profile.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        AvatarPreview(profile: draft)
                            .frame(width: 180, height: 180)
                        Spacer()
                    }
                }

                Section("Initialen") {
                    TextField("Initialen", text: Binding(
                        get: { draft.initials },
                        set: { draft.initials = String($0.prefix(3)).uppercased() }
                    ))
                    .textInputAutocapitalization(.characters)
                }

                Section("Havenachtergrond") {
                    Picker("Achtergrond", selection: $draft.background) {
                        ForEach(AvatarBackground.allCases, id: \.self) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Containerkleur") {
                    Picker("Kleur", selection: $draft.containerColor) {
                        ForEach(AvatarContainerColor.allCases, id: \.self) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Kraansymbool") {
                    Picker("Symbool", selection: $draft.craneSymbol) {
                        ForEach(AvatarCraneSymbol.allCases, id: \.self) { value in
                            Label(value.title, systemImage: value.sfSymbolName).tag(value)
                        }
                    }
                }
            }
            .navigationTitle("Avatar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
                        profile = draft
                        UserProfileStore.save(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HarborRealityView: View {
    let containers: [CargoContainer]
    var craneX: Float = 0
    var craneLoaded: Bool = false

    var body: some View {
        RealityView { content in
            let world = Entity()
            world.name = "harbor-world"

            let camera = PerspectiveCamera()
            camera.position = [0.0, 7.2, 8.8]
            camera.transform.rotation = simd_quatf(angle: -.pi / 4.8, axis: [1, 0, 0])
            world.addChild(camera)

            let sun = DirectionalLight()
            sun.light.intensity = 1800
            sun.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
            world.addChild(sun)

            let asphalt = HarborRealityView.makeBox(
                size: [12.0, 0.12, 7.2],
                position: [0.0, -0.06, 0.0],
                color: UIColor(red: 0.17, green: 0.19, blue: 0.20, alpha: 1),
                metallic: false
            )
            asphalt.name = "asphalt"
            world.addChild(asphalt)

            let water = HarborRealityView.makeBox(
                size: [12.0, 0.08, 2.8],
                position: [0.0, -0.02, -4.8],
                color: UIColor(red: 0.12, green: 0.34, blue: 0.43, alpha: 1),
                metallic: true
            )
            water.name = "havenwater"
            world.addChild(water)

            let quay = HarborRealityView.makeBox(
                size: [12.0, 0.35, 0.35],
                position: [0.0, 0.12, -3.35],
                color: UIColor(red: 0.46, green: 0.48, blue: 0.48, alpha: 1),
                metallic: true
            )
            world.addChild(quay)

            let terminal = HarborRealityView.makeBox(
                size: [2.8, 0.55, 1.7],
                position: [-4.2, 0.28, 2.2],
                color: UIColor(red: 0.25, green: 0.31, blue: 0.34, alpha: 1),
                metallic: true
            )
            world.addChild(terminal)
            world.addChild(HarborRealityView.makeBox(
                size: [2.2, 0.12, 0.12],
                position: [-4.2, 0.62, 1.38],
                color: UIColor(red: 0.78, green: 0.56, blue: 0.22, alpha: 1),
                metallic: false
            ))

            for (index, type) in CargoType.allCases.enumerated() {
                let x = Float(index) * 2.0 - 5.0
                let zoneColor = HarborRealityView.zoneColor(type)
                let zone = HarborRealityView.makeBox(
                    size: [1.55, 0.08, 1.25],
                    position: [x, 0.04, 1.55],
                    color: zoneColor,
                    metallic: false
                )
                zone.name = "zone-\(type.rawValue)"
                world.addChild(zone)
            }

            let gantryCrane = HarborRealityView.makeCrane(position: [-2.7, 0.0, -2.25])
            gantryCrane.name = "gantry-crane"
            world.addChild(gantryCrane)
            world.addChild(HarborRealityView.makeCrane(position: [2.7, 0.0, -2.25]))
            world.addChild(HarborRealityView.makeTruck(position: [-4.4, 0.0, -0.8], color: UIColor(red: 0.62, green: 0.18, blue: 0.12, alpha: 1)))
            world.addChild(HarborRealityView.makeTruck(position: [4.2, 0.0, -0.55], color: UIColor(red: 0.20, green: 0.32, blue: 0.42, alpha: 1)))
            world.addChild(HarborRealityView.makeTrain(position: [3.9, 0.0, 2.45]))
            world.addChild(HarborRealityView.makeVessel(type: .barge, position: [-3.8, 0.0, -4.75]))
            world.addChild(HarborRealityView.makeVessel(type: .shortsea, position: [0.0, 0.0, -4.75]))
            world.addChild(HarborRealityView.makeVessel(type: .deepsea, position: [3.8, 0.0, -4.75]))

            let stackTypes: [CargoType] = [.barge, .shortsea, .deepsea, .train, .truck, .terminal]
            for (index, type) in stackTypes.enumerated() {
                let x = -4.5 + Float(index) * 1.8
                let stack = HarborRealityView.makeContainer(
                    type: type,
                    position: [x, 0.35, -1.75]
                )
                world.addChild(stack)
            }

            content.add(world)
        } update: { content in
            if let world = content.entities.first(where: { $0.name == "harbor-world" }),
               let crane = world.children.first(where: { $0.name == "gantry-crane" }) {
                crane.position.x = craneX
            }
            if let world = content.entities.first(where: { $0.name == "harbor-world" }),
               world.children.contains(where: { $0.name == "active-container-stack" }) {
                world.children.removeAll { $0.name == "active-container-stack" }
            }
            if let world = content.entities.first(where: { $0.name == "harbor-world" }) {
                for (index, container) in containers.prefix(6).enumerated() {
                    let x = -3.2 + Float(index % 3) * 1.55
                    let z = -0.15 - Float(index / 3) * 1.15
                    let entity = HarborRealityView.makeContainer(
                        type: container.type,
                        position: [x, 0.38, z]
                    )
                    entity.name = "active-container-stack"
                    world.addChild(entity)
                }
            }
        }
    }

    static func makeBox(size: SIMD3<Float>, position: SIMD3<Float>, color: UIColor, metallic: Bool) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size)
        let material = UnlitMaterial(color: color)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }

    static func makeContainer(type: CargoType, position: SIMD3<Float>) -> ModelEntity {
        let entity = makeBox(
            size: [1.05, 0.55, 0.55],
            position: position,
            color: containerColor(type),
            metallic: true
        )
        entity.name = "container-\(type.rawValue)"
        return entity
    }

    static func makeCrane(position: SIMD3<Float>) -> Entity {
        let crane = Entity()
        crane.position = position
        let left = makeBox(size: [0.16, 2.2, 0.16], position: [-0.8, 1.1, 0], color: UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1), metallic: true)
        let right = makeBox(size: [0.16, 2.2, 0.16], position: [0.8, 1.1, 0], color: UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1), metallic: true)
        let beam = makeBox(size: [2.2, 0.18, 0.18], position: [0, 2.15, 0], color: UIColor(red: 0.72, green: 0.43, blue: 0.16, alpha: 1), metallic: true)
        crane.addChild(left)
        crane.addChild(right)
        crane.addChild(beam)
        return crane
    }

    static func makeTruck(position: SIMD3<Float>, color: UIColor) -> Entity {
        let truck = Entity()
        truck.position = position
        truck.addChild(makeBox(size: [1.45, 0.42, 0.68], position: [0, 0.21, 0], color: color, metallic: true))
        truck.addChild(makeBox(size: [0.55, 0.55, 0.68], position: [0.72, 0.49, 0], color: color, metallic: true))
        for x in [Float(-0.55), Float(0.55)] {
            let wheel = ModelEntity(
                mesh: .generateSphere(radius: 0.16),
                materials: [UnlitMaterial(color: .black)]
            )
            wheel.position = [x, 0.12, 0.38]
            truck.addChild(wheel)
        }
        return truck
    }

    static func makeTrain(position: SIMD3<Float>) -> Entity {
        let train = Entity()
        train.position = position
        for index in 0..<3 {
            let wagon = makeBox(
                size: [0.9, 0.42, 0.62],
                position: [Float(index) * 1.0 - 1.0, 0.21, 0],
                color: index == 0
                    ? UIColor(red: 0.38, green: 0.42, blue: 0.44, alpha: 1)
                    : UIColor(red: 0.62, green: 0.30, blue: 0.15, alpha: 1),
                metallic: true
            )
            train.addChild(wagon)
        }
        return train
    }

    static func makeVessel(type: CargoType, position: SIMD3<Float>) -> Entity {
        let vessel = Entity()
        vessel.position = position
        let length: Float
        let capacity: Int
        switch type {
        case .barge:
            length = 2.0
            capacity = 2
        case .shortsea:
            length = 3.0
            capacity = 4
        case .deepsea:
            length = 4.2
            capacity = 8
        default:
            length = 2.0
            capacity = 2
        }
        vessel.addChild(makeBox(
            size: [length, 0.28, 0.72],
            position: [0, 0.14, 0],
            color: UIColor(red: 0.24, green: 0.27, blue: 0.29, alpha: 1),
            metallic: true
        ))
        let visiblePlaces = min(capacity, 4)
        for index in 0..<visiblePlaces {
            let x = -length * 0.35 + Float(index) * (length * 0.22)
            vessel.addChild(makeBox(
                size: [0.38, 0.22, 0.38],
                position: [x, 0.43, 0],
                color: containerColor(.terminal),
                metallic: true
            ))
        }
        return vessel
    }

    static func containerColor(_ type: CargoType) -> UIColor {
        switch type {
        case .barge: return UIColor(red: 0.38, green: 0.50, blue: 0.55, alpha: 1)
        case .shortsea: return UIColor(red: 0.11, green: 0.34, blue: 0.50, alpha: 1)
        case .deepsea: return UIColor(red: 0.16, green: 0.25, blue: 0.31, alpha: 1)
        case .train: return UIColor(red: 0.70, green: 0.36, blue: 0.13, alpha: 1)
        case .truck: return UIColor(red: 0.62, green: 0.18, blue: 0.12, alpha: 1)
        case .terminal: return UIColor(red: 0.24, green: 0.48, blue: 0.31, alpha: 1)
        }
    }

    static func zoneColor(_ type: CargoType) -> UIColor {
        switch type {
        case .barge: return UIColor(red: 0.38, green: 0.50, blue: 0.55, alpha: 1)
        case .shortsea: return UIColor(red: 0.14, green: 0.43, blue: 0.61, alpha: 1)
        case .deepsea: return UIColor(red: 0.16, green: 0.25, blue: 0.31, alpha: 1)
        case .train: return UIColor(red: 0.72, green: 0.43, blue: 0.18, alpha: 1)
        case .truck: return UIColor(red: 0.62, green: 0.18, blue: 0.12, alpha: 1)
        case .terminal: return UIColor(red: 0.30, green: 0.55, blue: 0.37, alpha: 1)
        }
    }
}

struct GameView: View {
    let mode: GameMode
    @Environment(\.dismiss) private var dismiss
    @State private var containers: [CargoContainer]
    @State private var selectedContainerID: UUID?
    @State private var craneX: Float = -2.7
    @State private var craneLoaded = false
    @State private var craneTarget: CargoType?
    @State private var secondsRemaining = 90
    @State private var score = 0
    @State private var streak = 0
    @State private var mistakes = 0
    @State private var status: RoundStatus = .playing
    @State private var run = RoguelikeRun(roundCount: 4)
    @State private var upgradeChoices: [UpgradeKind] = [.extraTime, .scoreBoost, .mistakeShield]
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var lastMessage = "Sleep een container naar de juiste plek"
    @State private var adEnabled = false
    @State private var realityReady = false
    private let scoreEngine = ScoreEngine()
    private let roundEngine = RoundEngine()

    init(mode: GameMode) {
        self.mode = mode
        let seed: UInt64 = mode == .competitive ? 20261126 : UInt64.random(in: 1...UInt64.max)
        _containers = State(initialValue: RoundEngine().generatedContainers(seed: seed))
        _secondsRemaining = State(initialValue: 90)
    }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.13, blue: 0.18).ignoresSafeArea()
            if status == .upgradeChoice {
                upgradeView
            } else if status == .finished {
                roundResultView
            } else {
                playView
            }
        }
        .navigationTitle(mode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Menu") { dismiss() }
                    .disabled(status == .playing)
            }
        }
        #endif
        .onReceive(timer) { _ in
            guard status == .playing else { return }
            if mode != .casual && secondsRemaining > 0 {
                secondsRemaining -= 1
            }
            if roundEngine.shouldEnd(secondsRemaining: mode == .casual ? 1 : secondsRemaining, remainingContainers: containers.count) {
                finishRound()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            realityReady = true
        }
    }

    private var playView: some View {
        VStack(spacing: 16) {
            HStack {
                Label(mode == .casual ? "Geen timer" : "\(secondsRemaining)s", systemImage: "clock")
                Spacer()
                Label("\(score)", systemImage: "star.fill")
                if mode == .roguelike {
                    Label("Ronde \(run.currentRound)/\(run.roundCount)", systemImage: "arrow.3.trianglepath")
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal)

            Text(lastMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.yellow)
                .frame(height: 28)

            if realityReady {
                HarborRealityView(
                    containers: containers,
                    craneX: craneX,
                    craneLoaded: craneLoaded
                )
                    .frame(maxWidth: 720, minHeight: 280, maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
                    .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.12, green: 0.18, blue: 0.21))
                    .frame(maxWidth: 720, minHeight: 280, maxHeight: 420)
                    .padding(.horizontal)
            }

            HStack(spacing: 10) {
                Button {
                    craneX = max(-5.5, craneX - 1.0)
                } label: {
                    Label("Links", systemImage: "arrow.left")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)

                Button {
                    if craneLoaded, let craneTarget {
                        placeContainerWithCrane(at: craneTarget)
                    } else if let selectedContainerID,
                             let container = containers.first(where: { $0.id == selectedContainerID }),
                             abs(craneX - cranePosition(for: container.type)) <= 1.05 {
                        craneLoaded = true
                        craneTarget = container.type
                        lastMessage = "\(container.type.title)-container geladen"
                    } else if let selectedContainerID,
                              let container = containers.first(where: { $0.id == selectedContainerID }) {
                        craneX = cranePosition(for: container.type)
                        lastMessage = "Kraan rijdt naar \(container.type.title)"
                    } else {
                        lastMessage = "Tik eerst een container aan"
                    }
                } label: {
                    Text(craneLoaded ? "Lossen" : "Laden")
                        .frame(maxWidth: 90)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    craneX = min(5.5, craneX + 1.0)
                } label: {
                    Label("Rechts", systemImage: "arrow.right")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CargoType.allCases, id: \.self) { type in
                        dropZone(type)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: 720)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(containers) { container in
                        cargoCard(container)
                    }
                }
                .padding(.horizontal)
            }

            if adEnabled {
                Button("Hint (stubbeloning)") {
                    lastMessage = "Hint: containers horen bij hun overeenkomstige plek"
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func dropZone(_ type: CargoType) -> some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(zoneColor(type).opacity(0.25))
                    .stroke(zoneColor(type), lineWidth: 3)
                Text(type.symbol)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(type.title)
                .foregroundStyle(.white)
            Text("\(type.placeholderCapacity) plaatsen")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: 112, height: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            craneTarget = type
            craneX = cranePosition(for: type)
            lastMessage = craneLoaded
                ? "Rijd met geladen kraan naar \(type.title)"
                : "Bestemming \(type.title) gekozen"
        }
        .dropDestination(for: String.self) { items, _ in
            guard let idText = items.first,
                  let container = containers.first(where: { $0.id.uuidString == idText }) else {
                return false
            }
            selectedContainerID = container.id
            craneLoaded = true
            craneTarget = type
            craneX = cranePosition(for: type)
            placeContainerWithCrane(at: type)
            return true
        }
    }

    private func cargoCard(_ container: CargoContainer) -> some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(containerColor(container.type))
                .overlay(
                    Text(container.type.symbol)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.yellow, lineWidth: selectedContainerID == container.id ? 4 : 0)
                )
            Text(container.type.title)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .frame(width: 100, height: 130)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedContainerID = container.id
            craneLoaded = false
            craneTarget = nil
            craneX = cranePosition(for: container.type)
            lastMessage = "Container \(container.type.title) gekozen; druk op Laden"
        }
        .draggable(container.id.uuidString)
    }

    private func cranePosition(for type: CargoType) -> Float {
        switch type {
        case .barge: return -4.8
        case .shortsea: return -2.4
        case .deepsea: return 0.0
        case .train: return 2.4
        case .truck: return 4.8
        case .terminal: return 5.0
        }
    }

    private func placeContainerWithCrane(at destination: CargoType) {
        guard craneLoaded,
              abs(craneX - cranePosition(for: destination)) <= 1.05,
              let selectedContainerID,
              let container = containers.first(where: { $0.id == selectedContainerID }) else {
            lastMessage = "Beweeg de kraan eerst naar de juiste plek"
            return
        }
        place(container, in: destination)
        craneLoaded = false
        craneTarget = nil
    }

    private func place(_ container: CargoContainer, in destination: CargoType) {
        guard status == .playing else { return }
        selectedContainerID = nil
        if container.type == destination {
            streak += 1
            let result = scoreEngine.placement(
                correct: true,
                secondsRemaining: secondsRemaining,
                streak: streak,
                multiplier: mode == .roguelike ? run.effects.scoreMultiplier : 1.0
            )
            score += result.points
            containers.removeAll { $0.id == container.id }
            lastMessage = "+\(result.points) punten"
            if containers.isEmpty {
                finishRound()
            }
        } else {
            mistakes += 1
            streak = 0
            if mode == .roguelike && run.effects.mistakeShields > 0 {
                run.effects.mistakeShields -= 1
                lastMessage = "Feilenscherm heeft de fout opgevangen"
            } else {
                score = max(0, score - 50)
                lastMessage = "Niet de juiste plek (-50)"
            }
        }
    }

    private var roundResultView: some View {
        VStack(spacing: 20) {
            Text("Ronde klaar")
                .font(.largeTitle.bold())
            Text("\(score) punten")
                .font(.title)
            Text("\(mistakes) fouten")
                .foregroundStyle(.secondary)
            if mode == .competitive {
                Text("Persoonlijk beste: \(UserDefaults.standard.integer(forKey: "mobilePortPersonalBest"))")
                    .foregroundStyle(.cyan)
            }

            if mode == .roguelike && !run.completed {
                Button("Kies upgrade") {
                    status = .upgradeChoice
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Opnieuw spelen") {
                restart()
            }
            .buttonStyle(.bordered)

            Button("Terug naar menu") { dismiss() }
        }
        .foregroundStyle(.white)
        .padding()
    }

    private var upgradeView: some View {
        VStack(spacing: 16) {
            Text("Kies een tijdelijke upgrade")
                .font(.title.bold())
                .foregroundStyle(.white)

            ForEach(upgradeChoices, id: \.self) { upgrade in
                Button {
                    run.choose(upgrade)
                    run.applyRoundScore(score)
                    restart()
                    status = run.completed ? .finished : .playing
                } label: {
                    VStack(alignment: .leading) {
                        Text(upgrade.title).font(.headline)
                        Text(upgrade.detail).font(.caption)
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding()
    }

    private func finishRound() {
        guard status == .playing else { return }
        timer.upstream.connect().cancel()
        if mode == .competitive {
            savePersonalBest(score)
        }
        if mode == .roguelike {
            status = run.completed ? .finished : .upgradeChoice
        } else {
            status = .finished
        }
    }

    private func restart() {
        let seed: UInt64 = mode == .competitive ? 20261126 : UInt64.random(in: 1...UInt64.max)
        containers = roundEngine.generatedContainers(
            seed: seed,
            count: mode == .roguelike ? 9 : 9
        )
        secondsRemaining = roundEngine.durationSeconds + (mode == .roguelike ? run.effects.bonusSeconds : 0)
        streak = 0
        mistakes = 0
        lastMessage = "Sleep een container naar de juiste plek"
        selectedContainerID = nil
        craneLoaded = false
        craneTarget = nil
        craneX = -2.7
        score = mode == .roguelike ? run.totalScore : 0
        status = .playing
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    private func savePersonalBest(_ points: Int) {
        let key = "mobilePortPersonalBest"
        let best = UserDefaults.standard.integer(forKey: key)
        if points > best {
            UserDefaults.standard.set(points, forKey: key)
        }
    }

    private func zoneColor(_ type: CargoType) -> Color {
        switch type {
        case .barge: return .teal
        case .shortsea: return .cyan
        case .deepsea: return .blue
        case .train: return .orange
        case .truck: return .red
        case .terminal: return .green
        }
    }

    private func containerColor(_ type: CargoType) -> Color {
        switch type {
        case .barge: return .teal
        case .shortsea: return .cyan
        case .deepsea: return .blue
        case .train: return .orange
        case .truck: return .red
        case .terminal: return .green
        }
    }
}
