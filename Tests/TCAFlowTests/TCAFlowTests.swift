import XCTest
import SwiftUI
@testable import TCAFlow

final class TCAFlowTests: XCTestCase {

    enum TestScreen: Equatable, Codable {
        case home
        case detail
        case profile
        case settings
    }

    // MARK: - Route 기본 테스트

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

    // MARK: - Feature 1: Sheet Detent 테스트

    func testSheetWithDetentConfiguration() {
        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.presentSheet(.detail, configuration: .halfAndFull)

        XCTAssertEqual(routes.count, 2)
        XCTAssertTrue(routes.last!.isSheet)

        let config = routes.last!.sheetConfiguration
        XCTAssertNotNil(config)
        XCTAssertTrue(config!.detents.contains(.medium))
        XCTAssertTrue(config!.detents.contains(.large))
        XCTAssertTrue(config!.showDragIndicator)
    }

    func testSheetWithHalfDetent() {
        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.presentSheet(.settings, configuration: .half)

        let config = routes.last!.sheetConfiguration
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.detents, [.medium])
    }

    func testSheetDefaultConfiguration() {
        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.presentSheet(.detail)

        let config = routes.last!.sheetConfiguration
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.detents, [.large])
    }

    func testPushHasNoSheetConfiguration() {
        let route = Route<TestScreen>.push(.detail)
        XCTAssertNil(route.sheetConfiguration)
    }

    // MARK: - Feature 3: Route Guard 테스트

    func testRouteGuardAllow() {
        struct AlwaysAllowGuard: RouteGuard {
            func canNavigate<Screen>(
                from currentRoutes: [Route<Screen>],
                to newRoutes: [Route<Screen>]
            ) -> RouteGuardResult {
                .allow
            }
        }

        let routes: [Route<TestScreen>] = [.root(.home)]
        let result = checkRouteGuard(AlwaysAllowGuard(), from: routes)
        XCTAssertTrue(result)
    }

    func testRouteGuardReject() {
        struct AlwaysRejectGuard: RouteGuard {
            func canNavigate<Screen>(
                from currentRoutes: [Route<Screen>],
                to newRoutes: [Route<Screen>]
            ) -> RouteGuardResult {
                .reject(reason: "테스트 거부")
            }
        }

        let routes: [Route<TestScreen>] = [.root(.home)]
        let result = checkRouteGuard(AlwaysRejectGuard(), from: routes)
        XCTAssertFalse(result)
    }

    // MARK: - Feature 4: DeepLink 테스트

    func testDeepLinkReplace() {
        struct TestDeepLinkHandler: DeepLinkHandler {
            typealias Screen = TestScreen
            func routes(for url: URL) -> [Route<TestScreen>]? {
                guard url.host == "profile" else { return nil }
                return [
                    .root(.home, embedInNavigationView: true),
                    .push(.profile)
                ]
            }
        }

        var routes: [Route<TestScreen>] = [.root(.home)]
        let handled = routes.handleDeepLink(
            URL(string: "app://profile")!,
            handler: TestDeepLinkHandler(),
            mode: .replace
        )

        XCTAssertTrue(handled)
        XCTAssertEqual(routes.count, 2)
        XCTAssertEqual(routes.last?.screen, .profile)
    }

    func testDeepLinkKeepRoot() {
        struct TestDeepLinkHandler: DeepLinkHandler {
            typealias Screen = TestScreen
            func routes(for url: URL) -> [Route<TestScreen>]? {
                return [
                    .root(.home, embedInNavigationView: true),
                    .push(.detail),
                    .push(.profile)
                ]
            }
        }

        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.push(.settings) // 기존 스택

        routes.handleDeepLink(
            URL(string: "app://test")!,
            handler: TestDeepLinkHandler(),
            mode: .keepRoot
        )

        // root는 기존 유지, 나머지는 딥링크 경로
        XCTAssertEqual(routes.count, 3)
        XCTAssertEqual(routes[0].screen, .home) // 기존 root 유지
        XCTAssertEqual(routes[1].screen, .detail)
        XCTAssertEqual(routes[2].screen, .profile)
    }

    func testDeepLinkUnhandledURL() {
        struct TestDeepLinkHandler: DeepLinkHandler {
            typealias Screen = TestScreen
            func routes(for url: URL) -> [Route<TestScreen>]? {
                return nil // 처리 불가
            }
        }

        var routes: [Route<TestScreen>] = [.root(.home)]
        let handled = routes.handleDeepLink(
            URL(string: "app://unknown")!,
            handler: TestDeepLinkHandler()
        )

        XCTAssertFalse(handled)
        XCTAssertEqual(routes.count, 1) // 변경 없음
    }

    func testURLDeepLinkParameters() {
        let url = URL(string: "app://profile?userId=123&tab=settings")!
        let params = url.deepLinkParameters

        XCTAssertEqual(params["userId"], "123")
        XCTAssertEqual(params["tab"], "settings")
    }

    func testURLDeepLinkPathComponents() {
        let url = URL(string: "app://host/users/123/profile")!
        let components = url.deepLinkPathComponents

        XCTAssertEqual(components, ["users", "123", "profile"])
    }

    // MARK: - Feature 6: RouteAnimation 테스트

    func testRouteAnimationDefault() {
        let anim = RouteAnimation.default
        XCTAssertNotNil(anim.animation)
    }

    func testRouteAnimationNone() {
        let anim = RouteAnimation.none
        XCTAssertNil(anim.animation)
    }

    func testRouteAnimationEquality() {
        XCTAssertEqual(RouteAnimation.fade(), RouteAnimation.fade())
        XCTAssertNotEqual(RouteAnimation.fade(), RouteAnimation.spring())
    }

    // MARK: - Feature 7: Route Persistence 테스트

    func testRouteCodable() throws {
        let routes: [Route<TestScreen>] = [
            .root(.home, embedInNavigationView: true),
            .push(.detail),
            .push(.profile)
        ]

        let data = try JSONEncoder().encode(routes)
        let decoded = try JSONDecoder().decode([Route<TestScreen>].self, from: data)

        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded[0].screen, .home)
        XCTAssertEqual(decoded[1].screen, .detail)
        XCTAssertEqual(decoded[2].screen, .profile)
        XCTAssertTrue(decoded[0].embedInNavigationView)
        XCTAssertTrue(decoded[1].isPush)
    }

    func testRoutePersistenceSaveAndLoad() {
        let defaults = UserDefaults(suiteName: "TCAFlowTest")!
        defaults.removePersistentDomain(forName: "TCAFlowTest")

        let routes: [Route<TestScreen>] = [
            .root(.home, embedInNavigationView: true),
            .push(.detail)
        ]

        RoutePersistence.save(routes, key: "test_nav", defaults: defaults)

        let loaded: [Route<TestScreen>]? = RoutePersistence.load(key: "test_nav", defaults: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].screen, .home)
        XCTAssertEqual(loaded?[1].screen, .detail)

        // 정리
        RoutePersistence.clear(key: "test_nav", defaults: defaults)
        let cleared: [Route<TestScreen>]? = RoutePersistence.load(key: "test_nav", defaults: defaults)
        XCTAssertNil(cleared)
    }

    func testArraySaveAndLoadRoutes() {
        let defaults = UserDefaults(suiteName: "TCAFlowTest2")!
        defaults.removePersistentDomain(forName: "TCAFlowTest2")

        var routes: [Route<TestScreen>] = [.root(.home)]
        routes.push(.profile)
        routes.saveRoutes(to: "test_array", defaults: defaults)

        let loaded: [Route<TestScreen>]? = .loadRoutes(from: "test_array", defaults: defaults)
        XCTAssertEqual(loaded?.count, 2)

        RoutePersistence.clear(key: "test_array", defaults: defaults)
    }

    func testSheetRouteCodable() throws {
        let routes: [Route<TestScreen>] = [
            .root(.home),
            .sheet(.settings, embedInNavigationView: true)
        ]

        let data = try JSONEncoder().encode(routes)
        let decoded = try JSONDecoder().decode([Route<TestScreen>].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertTrue(decoded[1].isSheet)
        XCTAssertTrue(decoded[1].embedInNavigationView)
    }
}
