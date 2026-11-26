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
    case barge
    case shortsea
    case deepsea
    case train
    case truck
    case terminal

    public var title: String {
        switch self {
        case .barge: return "Barge"
        case .shortsea: return "Shortsea"
        case .deepsea: return "Deepsea"
        case .train: return "Trein"
        case .truck: return "Truck"
        case .terminal: return "Terminalperron"
        }
    }

    public var symbol: String {
        switch self {
        case .barge: return "B"
        case .shortsea: return "S"
        case .deepsea: return "D"
        case .train: return "T"
        case .truck: return "V"
        case .terminal: return "P"
        }
    }

    public var transportFamily: TransportFamily {
        switch self {
        case .barge, .shortsea, .deepsea:
            return .water
        case .train, .truck:
            return .land
        case .terminal:
            return .terminal
        }
    }

    public var placeholderCapacity: Int {
        switch self {
        case .barge: return 2
        case .shortsea: return 4
        case .deepsea: return 8
        case .train: return 3
        case .truck: return 1
        case .terminal: return 2
        }
    }

    public var placeholderWaitSeconds: Int {
        switch self {
        case .barge: return 15
        case .shortsea: return 30
        case .deepsea: return 45
        case .train: return 25
        case .truck: return 12
        case .terminal: return 20
        }
    }
}

public enum TransportFamily: String, Codable, Sendable, CaseIterable {
    case water
    case land
    case terminal

    public var title: String {
        switch self {
        case .water: return "Water"
        case .land: return "Land"
        case .terminal: return "Terminal"
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

public enum AvatarBackground: String, Codable, Sendable, CaseIterable {
    case harbor
    case asphalt
    case dusk

    public var title: String {
        switch self {
        case .harbor: return "Haven"
        case .asphalt: return "Asfalt"
        case .dusk: return "Schemer"
        }
    }
}

public enum AvatarContainerColor: String, Codable, Sendable, CaseIterable {
    case orange
    case blue
    case green
    case graphite

    public var title: String {
        switch self {
        case .orange: return "Oranje"
        case .blue: return "Blauw"
        case .green: return "Groen"
        case .graphite: return "Grafiet"
        }
    }
}

public enum AvatarCraneSymbol: String, Codable, Sendable, CaseIterable {
    case crane
    case anchor
    case box

    public var title: String {
        switch self {
        case .crane: return "Kraan"
        case .anchor: return "Anker"
        case .box: return "Container"
        }
    }

    public var sfSymbolName: String {
        switch self {
        case .crane: return "crane"
        case .anchor: return "sailboat.fill"
        case .box: return "shippingbox.fill"
        }
    }
}

public struct UserProfile: Codable, Equatable, Sendable {
    public var initials: String
    public var background: AvatarBackground
    public var containerColor: AvatarContainerColor
    public var craneSymbol: AvatarCraneSymbol

    public init(
        initials: String = "MP",
        background: AvatarBackground = .harbor,
        containerColor: AvatarContainerColor = .orange,
        craneSymbol: AvatarCraneSymbol = .crane
    ) {
        self.initials = String(initials.prefix(3)).uppercased()
        self.background = background
        self.containerColor = containerColor
        self.craneSymbol = craneSymbol
    }
}

public enum RoundStatus: Equatable, Sendable {
    case ready
    case playing
    case upgradeChoice
    case finished
}
