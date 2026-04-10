import XCTest
@testable import TCAFlow

final class TCAFlowTests: XCTestCase {

    enum TestScreen: Equatable {
        case home
        case detail
        case profile
    }

    func testRouteCreation() {
        let route = Route<TestScreen>.push(.home)
        XCTAssertEqual(route.screen, .home)
        XCTAssertFalse(route.isPresented)
        XCTAssertTrue(route.isPush)
    }

    func testRouteEquality() {
        let route1 = Route<TestScreen>.push(.home)
        let route2 = Route<TestScreen>.push(.home)
        XCTAssertEqual(route1, route2)
    }

    func testPushAndGoBack() {
        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.push(.detail)
        XCTAssertEqual(routes.count, 2)

        routes.goBack()
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes.first?.screen, .home)
    }

    func testGoBackToRoot() {
        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.push(.detail)
        routes.push(.profile)
        XCTAssertEqual(routes.count, 3)

        routes.goBackToRoot()
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes.first?.screen, .home)
    }

    func testSheet() {
        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.presentSheet(.detail)
        XCTAssertEqual(routes.count, 2)
        XCTAssertTrue(routes.last!.isSheet)
    }
}
