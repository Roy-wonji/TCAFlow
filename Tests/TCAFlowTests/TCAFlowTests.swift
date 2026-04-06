import XCTest
@testable import TCAFlow
import ComposableArchitecture

final class TCAFlowTests: XCTestCase {

    func testRouteCreation() {
        // Route 생성 테스트
        let route = Route("test")
        XCTAssertEqual(route.state, "test")
        XCTAssertNotNil(route.id)
    }

    func testRouteEquality() {
        // Route 동등성 테스트 (ID 기반)
        let route1 = Route("test")
        let route2 = Route("test")

        // 같은 내용이지만 다른 ID이므로 다름
        XCTAssertNotEqual(route1, route2)

        // 같은 Route는 같음
        XCTAssertEqual(route1, route1)
    }

    func testIdentifiedArrayPushPop() {
        // 네비게이션 기본 기능 테스트
        var routes: IdentifiedArrayOf<Route<String>> = []

        // push 테스트
        routes.push("home")
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes.currentScreen, "home")

        routes.push("detail")
        XCTAssertEqual(routes.count, 2)
        XCTAssertEqual(routes.currentScreen, "detail")

        // pop 테스트
        let poppedRoute = routes.pop()
        XCTAssertEqual(poppedRoute?.state, "detail")
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes.currentScreen, "home")

        // popToRoot 테스트
        routes.push("profile")
        routes.push("settings")
        XCTAssertEqual(routes.count, 3)

        routes.popToRoot()
        XCTAssertEqual(routes.count, 0)
        XCTAssertNil(routes.currentScreen)
    }

    func testSpecificScreenNavigation() {
        // 특정 화면 이동 테스트
        var routes: IdentifiedArrayOf<Route<TestScreen>> = []

        // goTo 테스트
        routes.goTo(.home)
        XCTAssertEqual(routes.count, 1)
        XCTAssertTrue(routes.has(.home))

        routes.goTo(.detail)
        XCTAssertEqual(routes.count, 2)

        // 이미 있는 화면으로 이동
        routes.goTo(.home)
        XCTAssertEqual(routes.count, 1) // home까지 pop됨
        XCTAssertEqual(routes.currentScreen, .home)

        // goBackTo 테스트
        routes.push(.detail)
        routes.push(.profile)
        routes.goBackTo(.home)
        XCTAssertEqual(routes.currentScreen, .home)
    }

    func testUtilityMethods() {
        // 유틸리티 메서드 테스트
        var routes: IdentifiedArrayOf<Route<TestScreen>> = []

        routes.push(.home)
        routes.push(.detail)
        routes.push(.profile)

        // depth 테스트
        XCTAssertEqual(routes.depth, 3)

        // rootScreen 테스트
        XCTAssertEqual(routes.rootScreen, .home)

        // currentScreen 테스트
        XCTAssertEqual(routes.currentScreen, .profile)

        // replace 테스트
        routes.replace(with: .detail)
        XCTAssertEqual(routes.currentScreen, .detail)
        XCTAssertEqual(routes.depth, 3) // 개수는 그대로
    }
}

// MARK: - 테스트용 Screen enum
enum TestScreen: Equatable {
    case home
    case detail
    case profile
}