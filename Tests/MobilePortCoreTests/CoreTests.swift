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

final class UserProfileTests: XCTestCase {
    func testProfileInitialsAreTrimmedAndUppercased() {
        let profile = UserProfile(initials: "abcde")
        XCTAssertEqual(profile.initials, "ABC")
    }

    func testProfileCanBeEncodedAndDecoded() throws {
        let profile = UserProfile(initials: "HX", background: .dusk, containerColor: .graphite, craneSymbol: .anchor)
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded, profile)
    }

    func testTransportPlaceholderPropertiesAreDistinct() {
        XCTAssertLessThan(CargoType.barge.placeholderWaitSeconds, CargoType.deepsea.placeholderWaitSeconds)
        XCTAssertGreaterThan(CargoType.deepsea.placeholderCapacity, CargoType.barge.placeholderCapacity)
        XCTAssertEqual(CargoType.train.transportFamily, .land)
        XCTAssertEqual(CargoType.barge.transportFamily, .water)
    }
}

final class SandboxWorldTests: XCTestCase {
    func testHelpRequestsAreCappedAtTwoPerPlayer() {
        let session = InProcessSandboxSession(capacity: 2)
        let room = session.joinOrCreate(playerName: "A")
        let playerID = room.world.players[0].id
        XCTAssertTrue(session.addHelpRequest(playerID: playerID, kind: .freeCrane))
        XCTAssertTrue(session.addHelpRequest(playerID: playerID, kind: .trainOrder))
        XCTAssertFalse(session.addHelpRequest(playerID: playerID, kind: .deepseaCrane))
        XCTAssertEqual(session.roomSnapshot()?.world.helpRequests.count, 2)
    }

    func testExpiredHelpRequestsArePruned() {
        let playerID = "A"
        var request = HelpRequest(playerID: playerID, kind: .shortseaShortage, validSeconds: -1)
        XCTAssertFalse(request.isActive)
        request = HelpRequest(playerID: playerID, kind: .shortseaShortage, validSeconds: 90)
        XCTAssertTrue(request.isActive)
    }

    func testSuccessfulDropUpdatesSharedHarborMetrics() {
        let session = InProcessSandboxSession(capacity: 2)
        let room = session.joinOrCreate(playerName: "A")
        let playerID = room.world.players[0].id
        XCTAssertTrue(session.claimCrane(playerID: playerID))
        let container = room.world.containers[0]
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: playerID, to: container.location))
        XCTAssertTrue(session.liftContainer(craneID: "kraan-1", playerID: playerID, containerID: container.id))
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: playerID, to: .destination(.truck)))
        XCTAssertTrue(session.lowerContainer(craneID: "kraan-1", playerID: playerID, destination: .truck))
        let snapshot = session.roomSnapshot()
        XCTAssertEqual(snapshot?.world.metrics.throughput, 1)
        XCTAssertGreaterThan(snapshot?.world.metrics.harborScore ?? 0, 0)
        XCTAssertEqual(snapshot?.world.contracts[0].progress, 1)
    }

    func testLiftAndDropStateMachine() {
        let session = InProcessSandboxSession(capacity: 2)
        let room = session.joinOrCreate(playerName: "A")
        let playerID = room.world.players[0].id
        XCTAssertTrue(session.claimCrane(playerID: playerID))

        let container = room.world.containers[0]
        XCTAssertFalse(session.liftContainer(craneID: "kraan-1", playerID: playerID, containerID: container.id))
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: playerID, to: container.location))
        XCTAssertTrue(session.liftContainer(craneID: "kraan-1", playerID: playerID, containerID: container.id))
        XCTAssertTrue(session.claimCrane(playerID: playerID))
        XCTAssertFalse(session.lowerContainer(craneID: "kraan-1", playerID: playerID, destination: .truck))
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: playerID, to: .destination(.truck)))
        XCTAssertFalse(session.lowerContainer(craneID: "kraan-1", playerID: playerID, destination: .train))
        XCTAssertTrue(session.lowerContainer(craneID: "kraan-1", playerID: playerID, destination: .truck))

        let snapshot = session.roomSnapshot()
        XCTAssertEqual(snapshot?.world.deliveredCount, 1)
        XCTAssertEqual(snapshot?.world.containers[0].location, .destination(.truck))
        XCTAssertEqual(snapshot?.world.containers[0].loadingStatus, "Gelost")
        XCTAssertEqual(snapshot?.world.cranes[0].phase, .selected)
        XCTAssertNil(snapshot?.world.cranes[0].heldContainerID)
        let next = room.world.containers[1]
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: playerID, to: next.location))
        XCTAssertTrue(session.liftContainer(craneID: "kraan-1", playerID: playerID, containerID: next.id))
    }

    func testContainerCannotDropBeforeVerifying() {
        let session = InProcessSandboxSession(capacity: 2)
        let room = session.joinOrCreate(playerName: "A")
        XCTAssertFalse(session.lowerContainer(craneID: "kraan-1", playerID: room.world.players[0].id, destination: .train))
    }

    func testOnlyOwnerCanOperateCraneOrReplaceHeldContainer() {
        let session = InProcessSandboxSession()
        let room = session.joinOrCreate(playerName: "A")
        let owner = room.world.players[0].id
        let other = session.join(roomID: room.id, playerName: "B")!.world.players[1].id
        let container = room.world.containers[0]
        XCTAssertFalse(session.claimCrane(playerID: "unknown"))
        XCTAssertTrue(session.claimCrane(playerID: owner))
        XCTAssertFalse(session.claimCrane(playerID: other))
        XCTAssertFalse(session.moveCrane(craneID: "kraan-1", playerID: other, to: container.location))
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: owner, to: container.location))
        XCTAssertFalse(session.liftContainer(craneID: "kraan-1", playerID: other, containerID: container.id))
        XCTAssertTrue(session.liftContainer(craneID: "kraan-1", playerID: owner, containerID: container.id))
        XCTAssertFalse(session.liftContainer(craneID: "kraan-1", playerID: owner, containerID: room.world.containers[1].id))
        XCTAssertFalse(session.moveCrane(craneID: "kraan-1", playerID: owner, to: .source(.shortsea)))
        XCTAssertTrue(session.moveCrane(craneID: "kraan-1", playerID: owner, to: .destination(.train)))
        XCTAssertFalse(session.lowerContainer(craneID: "kraan-1", playerID: other, destination: .train))
        XCTAssertEqual(session.roomSnapshot()?.world.containers[0].location, .crane)
    }

    func testRoomCapacityRejectsThirdPlayer() {
        let session = InProcessSandboxSession(capacity: 2)
        let first = session.joinOrCreate(playerName: "A")
        let second = session.join(roomID: first.id, playerName: "B")
        XCTAssertNotNil(second)
        XCTAssertTrue(second?.isFull ?? false)
        XCTAssertNil(session.join(roomID: first.id, playerName: "C"))
    }

    func testMatchmakingCreatesRoomWhenNoRoomIsAvailable() {
        let session = InProcessSandboxSession(capacity: 1)
        let first = session.joinOrCreate(playerName: "A")
        let second = session.joinOrCreate(playerName: "B")
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(second.world.players.count, 1)
    }

    func testMatchmakingJoinsExistingOpenRoom() {
        let session = InProcessSandboxSession(capacity: 2)
        let first = session.joinOrCreate(playerName: "A")
        let second = session.joinOrCreate(playerName: "B")
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(second.world.players.count, 2)
    }

    func testDestinationValidationRequiresReadyCrane() {
        var world = SandboxWorld()
        world.cranes[0].phase = .idle
        XCTAssertEqual(
            SandboxWorldMutation.validateDrop(world: world, craneID: "kraan-1", destination: .train),
            .noContainer
        )
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
