import SwiftUI
import Foundation
import MobilePortCore

@main
struct MobilePortApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}

struct MainMenuView: View {
    @State private var selectedMode: GameMode?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.09, green: 0.16, blue: 0.24).ignoresSafeArea()
                VStack(spacing: 22) {
                    Spacer()
                    Text("HAVENLOODS")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Placeholder haventerminal")
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

struct GameView: View {
    let mode: GameMode
    @Environment(\.dismiss) private var dismiss
    @State private var containers: [CargoContainer]
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

            HStack(spacing: 12) {
                ForEach(CargoType.allCases, id: \.self) { type in
                    dropZone(type)
                }
            }
            .frame(maxWidth: 720)
            .padding(.horizontal)

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
        }
        .frame(height: 120)
        .dropDestination(for: String.self) { items, _ in
            guard let idText = items.first,
                  let container = containers.first(where: { $0.id.uuidString == idText }) else {
                return false
            }
            place(container, in: type)
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
            Text(container.type.title)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .frame(width: 100, height: 130)
        .draggable(container.id.uuidString)
    }

    private func place(_ container: CargoContainer, in destination: CargoType) {
        guard status == .playing else { return }
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
        case .ship: return .cyan
        case .train: return .orange
        case .terminal: return .green
        }
    }

    private func containerColor(_ type: CargoType) -> Color {
        switch type {
        case .ship: return .blue
        case .train: return .orange
        case .terminal: return .green
        }
    }
}
