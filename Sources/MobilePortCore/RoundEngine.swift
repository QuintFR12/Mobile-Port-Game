import Foundation

public struct RoundEngine: Sendable {
    public let durationSeconds: Int

    public init(durationSeconds: Int = 90) {
        self.durationSeconds = durationSeconds
    }

    public func shouldEnd(secondsRemaining: Int, remainingContainers: Int) -> Bool {
        secondsRemaining <= 0 || remainingContainers == 0
    }

    public func fixedContainers(count: Int = 9) -> [CargoContainer] {
        let sequence: [CargoType] = [.ship, .train, .terminal, .ship, .terminal, .train, .terminal, .ship, .train]
        return (0..<min(count, sequence.count)).map {
            let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", $0 + 1))!
            return CargoContainer(id: id, type: sequence[$0])
        }
    }

    public func generatedContainers(seed: UInt64, count: Int = 9) -> [CargoContainer] {
        var state = seed
        return (0..<count).map { index in
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let index = Int(state % UInt64(CargoType.allCases.count))
            let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", index + 1))!
            return CargoContainer(id: id, type: CargoType.allCases[index])
        }
    }
}
