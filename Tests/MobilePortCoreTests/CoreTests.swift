import XCTest
@testable import MobilePortCore

final class ScoreEngineTests: XCTestCase {
    func testCorrectPlacementAddsScore() {
        let result = ScoreEngine().placement(correct: true, secondsRemaining: 30, streak: 2)
        XCTAssertTrue(result.correct)
        XCTAssertGreaterThan(result.points, 100)
    }

    func testIncorrectPlacementAddsNoPoints() {
        let result = ScoreEngine().placement(correct: false, secondsRemaining: 30, streak: 5)
        XCTAssertFalse(result.correct)
        XCTAssertEqual(result.points, 0)
    }

    func testRoundScoreRewardsEfficiencyAndSpeed() {
        let score = ScoreEngine().roundScore(correct: 9, mistakes: 0, secondsRemaining: 30)
        XCTAssertEqual(score, 1700)
    }

    func testScoreMultiplierIsApplied() {
        let score = ScoreEngine().roundScore(correct: 9, mistakes: 0, secondsRemaining: 30, multiplier: 1.20)
        XCTAssertEqual(score, 2040)
    }
}

final class RoundEngineTests: XCTestCase {
    func testRoundEndsAtZeroSeconds() {
        XCTAssertTrue(RoundEngine().shouldEnd(secondsRemaining: 0, remainingContainers: 3))
    }

    func testRoundEndsWhenContainersAreEmpty() {
        XCTAssertTrue(RoundEngine().shouldEnd(secondsRemaining: 30, remainingContainers: 0))
    }

    func testRoundContinuesWithTimeAndContainers() {
        XCTAssertFalse(RoundEngine().shouldEnd(secondsRemaining: 30, remainingContainers: 3))
    }

    func testCompetitiveSeedIsStable() {
        let engine = RoundEngine()
        XCTAssertEqual(engine.generatedContainers(seed: 20261126, count: 9),
                       engine.generatedContainers(seed: 20261126, count: 9))
    }
}

final class UpgradeTests: XCTestCase {
    func testExtraTimeAddsSeconds() {
        var effect = UpgradeEffect()
        effect.apply(.extraTime)
        XCTAssertEqual(effect.bonusSeconds, 15)
    }

    func testScoreBoostStacksToTwentyPercent() {
        var effect = UpgradeEffect()
        effect.apply(.scoreBoost)
        XCTAssertEqual(effect.scoreMultiplier, 1.20, accuracy: 0.001)
    }

    func testMistakeShieldAndHintStack() {
        var effect = UpgradeEffect()
        effect.apply(.mistakeShield)
        effect.apply(.hintVision)
        XCTAssertEqual(effect.mistakeShields, 1)
        XCTAssertTrue(effect.hintVision)
    }

    func testRoguelikeRunCompletesAfterConfiguredRounds() {
        var run = RoguelikeRun(roundCount: 4)
        for _ in 1...4 {
            run.applyRoundScore(100)
        }
        XCTAssertTrue(run.completed)
        XCTAssertEqual(run.totalScore, 400)
    }

    func testRoguelikeRoundCountIsCappedBetweenFourAndSix() {
        XCTAssertEqual(RoguelikeRun(roundCount: 1).roundCount, 4)
        XCTAssertEqual(RoguelikeRun(roundCount: 99).roundCount, 6)
    }
}
