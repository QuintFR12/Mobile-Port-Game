import Foundation

public struct SandboxRoom: Codable, Equatable, Sendable {
    public let id: String
    public let capacity: Int
    public var world: SandboxWorld

    public init(id: String, capacity: Int = 2, world: SandboxWorld = SandboxWorld()) {
        self.id = id
        self.capacity = capacity
        self.world = world
    }

    public var isFull: Bool {
        world.players.count >= capacity
    }
}

public protocol SandboxSessionProtocol: AnyObject {
    var activeRoomID: String? { get }
    var capacity: Int { get }
    func joinOrCreate(playerName: String) -> SandboxRoom
    func join(roomID: String, playerName: String) -> SandboxRoom?
    func roomSnapshot() -> SandboxRoom?
}

public final class InProcessSandboxSession: SandboxSessionProtocol, @unchecked Sendable {
    public var activeRoomID: String?
    public let capacity: Int
    private var rooms: [String: SandboxRoom]
    private var nextRoomNumber: Int

    public init(capacity: Int = 2) {
        self.capacity = max(1, capacity)
        rooms = [:]
        nextRoomNumber = 1
    }

    public func joinOrCreate(playerName: String) -> SandboxRoom {
        if let room = rooms.values.first(where: { !$0.isFull }),
           let joined = join(roomID: room.id, playerName: playerName) {
            return joined
        }
        let roomID = String(format: "PORT-%03d", nextRoomNumber)
        nextRoomNumber += 1
        var room = SandboxRoom(id: roomID, capacity: capacity)
        room.world.players.append(SandboxPlayer(id: UUID().uuidString, name: playerName, positionX: -1.5))
        rooms[roomID] = room
        activeRoomID = roomID
        return room
    }

    public func join(roomID: String, playerName: String) -> SandboxRoom? {
        guard var room = rooms[roomID], !room.isFull else { return nil }
        let position = room.world.players.count == 0 ? -1.5 : 1.5
        room.world.players.append(SandboxPlayer(id: UUID().uuidString, name: playerName, positionX: position))
        rooms[roomID] = room
        activeRoomID = roomID
        return room
    }

    public func roomSnapshot() -> SandboxRoom? {
        guard let activeRoomID else { return nil }
        guard var room = rooms[activeRoomID] else { return nil }
        room.world.helpRequests.removeAll { !$0.isActive }
        rooms[activeRoomID] = room
        return room
    }

    public func updateWorld(_ world: SandboxWorld) {
        guard let activeRoomID, var room = rooms[activeRoomID] else { return }
        room.world = world
        rooms[activeRoomID] = room
    }

    public func claimCrane(playerID: String) -> Bool {
        guard let activeRoomID, var room = rooms[activeRoomID] else { return false }
        guard var crane = room.world.cranes.first else { return false }
        guard room.world.players.contains(where: { $0.id == playerID }),
              crane.ownerPlayerID == nil || crane.ownerPlayerID == playerID else { return false }
        if crane.ownerPlayerID == playerID { return true }
        crane.ownerPlayerID = playerID
        crane.phase = .selected
        room.world.cranes[0] = crane
        rooms[activeRoomID] = room
        return true
    }

    public func moveCrane(craneID: String, playerID: String, to location: SandboxLocation) -> Bool {
        guard let activeRoomID, var room = rooms[activeRoomID],
              let index = room.world.cranes.firstIndex(where: { $0.id == craneID }),
              room.world.cranes[index].ownerPlayerID == playerID,
              let position = location.position else { return false }
        let crane = room.world.cranes[index]
        switch location {
        case .source:
            guard crane.heldContainerID == nil, crane.phase == .selected else { return false }
        case .destination:
            guard crane.heldContainerID != nil,
                  crane.phase == .lifting || crane.phase == .moving else { return false }
        case .crane:
            return false
        }
        room.world.cranes[index].positionX = position.x
        room.world.cranes[index].positionZ = position.z
        if crane.heldContainerID != nil { room.world.cranes[index].phase = .moving }
        rooms[activeRoomID] = room
        return true
    }

    public func liftContainer(craneID: String, playerID: String, containerID: UUID) -> Bool {
        guard let activeRoomID, var room = rooms[activeRoomID] else { return false }
        guard var crane = room.world.cranes.first(where: { $0.id == craneID }),
              crane.ownerPlayerID == playerID,
              crane.phase == .selected,
              crane.heldContainerID == nil,
              var container = room.world.containers.first(where: { $0.id == containerID }),
              case .source = container.location,
              let position = container.location.position,
              crane.positionX == position.x, crane.positionZ == position.z else { return false }
        crane.phase = .lifting
        crane.heldContainerID = containerID
        container.location = .crane
        container.loadingStatus = "Opgetild"
        if let craneIndex = room.world.cranes.firstIndex(where: { $0.id == craneID }) {
            room.world.cranes[craneIndex] = crane
        }
        if let containerIndex = room.world.containers.firstIndex(where: { $0.id == containerID }) {
            room.world.containers[containerIndex] = container
        }
        rooms[activeRoomID] = room
        return true
    }

    public func addHelpRequest(playerID: String, kind: HelpRequestKind) -> Bool {
        guard let activeRoomID, var room = rooms[activeRoomID] else { return false }
        room.world.helpRequests.removeAll { !$0.isActive }
        let activeCount = room.world.helpRequests.filter { $0.playerID == playerID }.count
        guard activeCount < 2 else { return false }
        room.world.helpRequests.append(HelpRequest(playerID: playerID, kind: kind))
        rooms[activeRoomID] = room
        return true
    }

    public func voteUpgrade(decisionID: UUID) -> Bool {
        guard let activeRoomID, var room = rooms[activeRoomID] else { return false }
        guard let index = room.world.upgradeDecisions.firstIndex(where: { $0.id == decisionID }) else { return false }
        room.world.upgradeDecisions[index].votes += 1
        rooms[activeRoomID] = room
        return true
    }

    public func lowerContainer(craneID: String, playerID: String, destination: HarborDestination) -> Bool {
        guard let activeRoomID, var room = rooms[activeRoomID] else { return false }
        let validation = SandboxWorldMutation.validateDrop(world: room.world, craneID: craneID, destination: destination)
        guard validation == .valid,
              var crane = room.world.cranes.first(where: { $0.id == craneID }),
              crane.ownerPlayerID == playerID,
              let containerID = crane.heldContainerID,
              var container = room.world.containers.first(where: { $0.id == containerID }) else { return false }
        crane.phase = .selected
        crane.heldContainerID = nil
        container.location = .destination(destination)
        container.loadingStatus = "Gelost"
        room.world.deliveredCount += 1
        room.world.metrics.throughput += 1
        room.world.metrics.energyUsed += 2
        room.world.metrics.harborReward += 100
        for index in room.world.contracts.indices {
            room.world.contracts[index].progress = min(
                room.world.contracts[index].target,
                room.world.contracts[index].progress + 1
            )
        }
        if let craneIndex = room.world.cranes.firstIndex(where: { $0.id == craneID }) {
            room.world.cranes[craneIndex] = crane
        }
        if let containerIndex = room.world.containers.firstIndex(where: { $0.id == containerID }) {
            room.world.containers[containerIndex] = container
        }
        rooms[activeRoomID] = room
        return true
    }
}
