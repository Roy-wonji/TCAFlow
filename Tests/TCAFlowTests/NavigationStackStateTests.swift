import Foundation
import XCTest
@testable import TCAFlow

final class NavigationStackStateTests: XCTestCase {
    func testIdenticalSnapshotsDoNotStartTransitions() {
        var state = _NavigationStackState<Int>()
        state.update([0, 1])
        let transition = state.begin()!
        XCTAssertTrue(state.complete(transition, actual: [0, 1]).isEmpty)
        for _ in 0..<1_000 {
            state.update([0, 1])
            XCTAssertNil(state.begin())
        }
    }

    func testUpdatesDuringTransitionCoalesce() {
        var state = _NavigationStackState<Int>()
        state.update([0])
        let first = state.begin()!
        state.update([0, 1])
        state.update([0, 2, 3])
        XCTAssertNil(state.begin())
        XCTAssertTrue(state.complete(first, actual: [0]).isEmpty)
        XCTAssertEqual(state.begin()?.destination, [0, 2, 3])
    }

    func testCancelledUserPopDoesNotRemoveEntries() {
        var state = mounted([0, 1, 2])
        let pop = state.beginUserTransition()!
        XCTAssertTrue(state.complete(pop, actual: [0, 1, 2]).isEmpty)
        XCTAssertEqual(state.desired, [0, 1, 2])
        XCTAssertNil(state.begin())
    }

    func testCompletedUserPopReportsRemovedSuffixOnce() {
        var state = mounted([0, 1, 2])
        let pop = state.beginUserTransition()!
        XCTAssertEqual(state.complete(pop, actual: [0]), [1, 2])
        XCTAssertEqual(state.desired, [0])
        XCTAssertTrue(state.complete(pop, actual: [0]).isEmpty)
        XCTAssertNil(state.begin())
    }

    func testCancellationSignalNeverWritesBackAnIntermediateStack() {
        var state = mounted([0, 1, 2])
        let pop = state.beginUserTransition()!
        XCTAssertTrue(state.complete(pop, actual: [0, 1], cancelled: true).isEmpty)
        XCTAssertEqual(state.desired, [0, 1, 2])
    }

    func testStoreResetWinsOverStaleUserPop() {
        var state = mounted([0, 1, 2])
        let pop = state.beginUserTransition()!
        state.update([3, 4])
        XCTAssertTrue(state.complete(pop, actual: [0, 1]).isEmpty)
        XCTAssertEqual(state.begin()?.destination, [3, 4])
    }

    func testUnexpectedExternalStackDoesNotBecomeStoreState() {
        var state = mounted([0, 1])
        let transition = state.beginUserTransition()!
        XCTAssertTrue(state.complete(transition, actual: [0, 9]).isEmpty)
        XCTAssertEqual(state.desired, [0, 1])
    }

    func testInvalidationRejectsCallbacksAndFutureUpdates() {
        var state = mounted([0, 1])
        let pop = state.beginUserTransition()!
        state.invalidate()
        state.update([4])
        XCTAssertTrue(state.complete(pop, actual: [0]).isEmpty)
        XCTAssertNil(state.begin())
        XCTAssertNil(state.beginUserTransition())
        XCTAssertTrue(state.desired.isEmpty)
    }

    private func mounted(_ entries: [Int]) -> _NavigationStackState<Int> {
        var state = _NavigationStackState<Int>()
        state.update(entries)
        let transition = state.begin()!
        _ = state.complete(transition, actual: entries)
        return state
    }
}
