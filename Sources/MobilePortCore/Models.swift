import Foundation

public enum GameMode: String, Codable, Sendable, CaseIterable {
    case casual
    case competitive
    case roguelike

    public var title: String {
        switch self {
        case .casual: return "Casual"
        case .competitive: return "Competitief"
        case .roguelike: return "Run"
        }
    }
}

public enum CargoType: String, Codable, Sendable, CaseIterable {
    case ship
    case train
    case terminal

    public var title: String {
        switch self {
        case .ship: return "Schip"
        case .train: return "Trein"
        case .terminal: return "Terminal"
        }
    }

    public var symbol: String {
        switch self {
        case .ship: return "S"
        case .train: return "T"
        case .terminal: return "P"
        }
    }
}

public struct CargoContainer: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let type: CargoType

    public init(id: UUID = UUID(), type: CargoType) {
        self.id = id
        self.type = type
    }
}

public struct PlacementResult: Equatable, Sendable {
    public let correct: Bool
    public let points: Int

    public init(correct: Bool, points: Int) {
        self.correct = correct
        self.points = points
    }
}

public enum RoundStatus: Equatable, Sendable {
    case ready
    case playing
    case upgradeChoice
    case finished
}
