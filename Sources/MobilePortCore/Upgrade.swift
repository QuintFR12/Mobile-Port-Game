import Foundation

public enum UpgradeKind: String, Codable, Sendable, CaseIterable {
    case extraTime
    case scoreBoost
    case mistakeShield
    case hintVision

    public var title: String {
        switch self {
        case .extraTime: return "Extra tijd"
        case .scoreBoost: return "Sterkere score"
        case .mistakeShield: return "Feilenscherm"
        case .hintVision: return "Gidslicht"
        }
    }

    public var detail: String {
        switch self {
        case .extraTime: return "+15 seconden bij de volgende ronde"
        case .scoreBoost: return "+20% punten voor deze run"
        case .mistakeShield: return "Een fout per ronde kost geen penalty"
        case .hintVision: return "De volgende container krijgt een hint"
        }
    }
}

public struct UpgradeEffect: Equatable, Codable, Sendable {
    public var bonusSeconds: Int
    public var scoreMultiplier: Double
    public var mistakeShields: Int
    public var hintVision: Bool

    public init(
        bonusSeconds: Int = 0,
        scoreMultiplier: Double = 1.0,
        mistakeShields: Int = 0,
        hintVision: Bool = false
    ) {
        self.bonusSeconds = bonusSeconds
        self.scoreMultiplier = scoreMultiplier
        self.mistakeShields = mistakeShields
        self.hintVision = hintVision
    }

    public mutating func apply(_ upgrade: UpgradeKind) {
        switch upgrade {
        case .extraTime:
            bonusSeconds += 15
        case .scoreBoost:
            scoreMultiplier = min(scoreMultiplier + 0.20, 3.0)
        case .mistakeShield:
            mistakeShields += 1
        case .hintVision:
            hintVision = true
        }
    }
}

public struct RoguelikeRun: Equatable, Sendable {
    public let roundCount: Int
    public var currentRound: Int
    public var totalScore: Int
    public var effects: UpgradeEffect
    public var completed: Bool

    public init(roundCount: Int = 4) {
        self.roundCount = min(max(roundCount, 4), 6)
        self.currentRound = 1
        self.totalScore = 0
        self.effects = UpgradeEffect()
        self.completed = false
    }

    public mutating func applyRoundScore(_ points: Int) {
        totalScore += points
        if currentRound >= roundCount {
            completed = true
        } else {
            currentRound += 1
        }
    }

    public mutating func choose(_ upgrade: UpgradeKind) {
        effects.apply(upgrade)
    }
}
