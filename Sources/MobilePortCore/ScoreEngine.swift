import Foundation

public struct ScoreEngine: Sendable {
    public init() {}

    public func placement(correct: Bool, secondsRemaining: Int, streak: Int, multiplier: Double = 1.0) -> PlacementResult {
        guard correct else { return PlacementResult(correct: false, points: 0) }
        let speed = max(0, secondsRemaining * 2)
        let streakBonus = min(streak, 10) * 25
        let points = Int(Double(100 + speed + streakBonus) * multiplier)
        return PlacementResult(correct: true, points: points)
    }

    public func roundScore(correct: Int, mistakes: Int, secondsRemaining: Int, multiplier: Double = 1.0) -> Int {
        let base = correct * 100
        let efficiency = correct > 0 ? max(0, 500 - mistakes * 100) : 0
        let speed = secondsRemaining * 10
        return Int(Double(base + efficiency + speed) * multiplier)
    }
}
