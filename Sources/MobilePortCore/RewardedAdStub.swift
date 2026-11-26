import Foundation

public enum RewardType: String, CaseIterable, Sendable {
    case extraHint
    case extraChoice
    case doubleReward
}

public final class RewardedAdStub: @unchecked Sendable {
    public var isEnabled: Bool

    public init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    public func canReward(_ reward: RewardType) -> Bool {
        isEnabled
    }

    public func grantReward(_ reward: RewardType) -> Bool {
        guard isEnabled else { return false }
        return true
    }
}
