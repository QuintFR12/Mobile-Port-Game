import Foundation

public enum HarborSource: String, Codable, Sendable, CaseIterable {
    case barge
    case shortsea
    case deepsea

    public var title: String {
        switch self {
        case .barge: return "Barge"
        case .shortsea: return "Shortsea"
        case .deepsea: return "Deepsea"
        }
    }
}

public enum HarborDestination: String, Codable, Sendable, CaseIterable {
    case train
    case truck

    public var title: String {
        switch self {
        case .train: return "Treinwagon"
        case .truck: return "Vrachtwagen"
        }
    }
}

public enum SandboxLocation: Hashable, Codable, Sendable {
    case source(HarborSource)
    case crane
    case destination(HarborDestination)

    public var title: String {
        switch self {
        case .source(let source): return source.title
        case .crane: return "Kraan"
        case .destination(let destination): return destination.title
        }
    }
}

public enum CranePhase: String, Codable, Sendable {
    case idle
    case selected
    case lifting
    case moving
    case lowering
    case verifying
}

public struct SandboxContainer: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let source: HarborSource
    public var location: SandboxLocation
    public var loadingStatus: String

    public init(id: UUID = UUID(), source: HarborSource, location: SandboxLocation) {
        self.id = id
        self.source = source
        self.location = location
        self.loadingStatus = "Beschikbaar"
    }
}

public struct SandboxCrane: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var ownerPlayerID: String?
    public var positionX: Double
    public var phase: CranePhase
    public var heldContainerID: UUID?

    public init(id: String, ownerPlayerID: String? = nil, positionX: Double = 0, phase: CranePhase = .idle) {
        self.id = id
        self.ownerPlayerID = ownerPlayerID
        self.positionX = positionX
        self.phase = phase
        self.heldContainerID = nil
    }
}

public struct SandboxPlayer: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var positionX: Double

    public init(id: String, name: String, positionX: Double = 0) {
        self.id = id
        self.name = name
        self.positionX = positionX
    }
}

public enum HelpRequestKind: String, Codable, Sendable, CaseIterable {
    case shortseaShortage
    case deepseaCrane
    case trainOrder
    case freeCrane

    public var title: String {
        switch self {
        case .shortseaShortage: return "Tekort shortsea"
        case .deepseaCrane: return "Deepsea-kraan nodig"
        case .trainOrder: return "Treinvolgorde"
        case .freeCrane: return "Vrije kraan gezocht"
        }
    }

    public var symbolName: String {
        switch self {
        case .shortseaShortage: return "shippingbox"
        case .deepseaCrane: return "crane"
        case .trainOrder: return "tram.fill"
        case .freeCrane: return "person.crop.circle.badge.checkmark"
        }
    }
}

public struct HelpRequest: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let playerID: String
    public let kind: HelpRequestKind
    public let expiresAt: Date

    public init(playerID: String, kind: HelpRequestKind, validSeconds: TimeInterval = 90) {
        id = UUID()
        self.playerID = playerID
        self.kind = kind
        expiresAt = Date().addingTimeInterval(validSeconds)
    }

    public var isActive: Bool {
        expiresAt > Date()
    }
}

public struct HarborMetrics: Codable, Equatable, Sendable {
    public var throughput: Int
    public var averageWaitSeconds: Int
    public var energyUsed: Int
    public var incidents: Int
    public var harborReward: Int

    public init(throughput: Int = 0, averageWaitSeconds: Int = 0, energyUsed: Int = 0, incidents: Int = 0, harborReward: Int = 0) {
        self.throughput = throughput
        self.averageWaitSeconds = averageWaitSeconds
        self.energyUsed = energyUsed
        self.incidents = incidents
        self.harborReward = harborReward
    }

    public var harborScore: Int {
        max(0, throughput * 100 - averageWaitSeconds * 2 - energyUsed - incidents * 250 + harborReward)
    }
}

public struct SharedContract: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let target: Int
    public var progress: Int
    public let expiresAt: Date

    public init(title: String, target: Int, validMinutes: Int = 10) {
        id = UUID()
        self.title = title
        self.target = target
        progress = 0
        expiresAt = Date().addingTimeInterval(TimeInterval(validMinutes * 60))
    }
}

public struct HarborUpgradeDecision: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public var votes: Int

    public init(title: String) {
        id = UUID()
        self.title = title
        votes = 0
    }
}

public struct SandboxWorld: Codable, Equatable, Sendable {
    public var players: [SandboxPlayer]
    public var cranes: [SandboxCrane]
    public var containers: [SandboxContainer]
    public var deliveredCount: Int
    public var helpRequests: [HelpRequest]
    public var metrics: HarborMetrics
    public var contracts: [SharedContract]
    public var upgradeDecisions: [HarborUpgradeDecision]

    public init() {
        players = []
        cranes = [SandboxCrane(id: "kraan-1", positionX: 0)]
        containers = [
            SandboxContainer(source: .barge, location: .source(.barge)),
            SandboxContainer(source: .shortsea, location: .source(.shortsea)),
            SandboxContainer(source: .deepsea, location: .source(.deepsea))
        ]
        deliveredCount = 0
        helpRequests = []
        metrics = HarborMetrics()
        contracts = [SharedContract(title: "Los 3 containers", target: 3)]
        upgradeDecisions = [
            HarborUpgradeDecision(title: "Efficienter kraanlicht"),
            HarborUpgradeDecision(title: "Snellere treinzone")
        ]
    }
}

public enum LoadingValidation: Equatable, Sendable {
    case valid
    case noContainer
    case craneNotReady
    case destinationUnavailable
}

public struct SandboxWorldMutation {
    public static func validateDrop(world: SandboxWorld, craneID: String, destination: HarborDestination) -> LoadingValidation {
        guard let crane = world.cranes.first(where: { $0.id == craneID }) else {
            return .craneNotReady
        }
        guard crane.phase == .verifying, crane.heldContainerID != nil else {
            return .craneNotReady
        }
        guard HarborDestination.allCases.contains(destination) else {
            return .destinationUnavailable
        }
        return .valid
    }
}
