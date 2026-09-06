import XCTest
@testable import TCAFlow

@MainActor
final class RouteScreenStateTests: XCTestCase {
    func testRemovedRouteRetainsLatestStateEvenWhenAllRoutesAreCleared() {
        let cache = _RouteScreenStateCache<Int>()
        let detail = cache.state(at: 1, routes: [.root(0), .push(1)])
        cache.update([.root(0), .push(2)])
        cache.update([])
        XCTAssertEqual(detail.read(from: []), 2)
        XCTAssertFalse(detail.isAttached)
    }

    func testRouteUpdatePrewarmsStateForDestinationTeardown() {
        let cache = _RouteScreenStateCache<Int>()
        cache.update([.root(0), .push(1)])
        cache.update([.root(0)])

        let detail = cache.state(at: 1, routes: [.root(0)])

        XCTAssertEqual(detail.read(from: [.root(0)]), 1)
        XCTAssertFalse(detail.isAttached)
    }

    func testPushPopCyclesReuseScopeKeys() {
        let cache = _RouteScreenStateCache<Int>()
        let detail = cache.state(at: 1, routes: [.root(0), .push(1)])
        for value in 2...100 {
            cache.update([.root(0)])
            let next = cache.state(at: 1, routes: [.root(0), .push(value)])
            XCTAssertTrue(detail === next)
            XCTAssertEqual(next.read(from: [.root(0), .push(value)]), value)
        }
    }
}
