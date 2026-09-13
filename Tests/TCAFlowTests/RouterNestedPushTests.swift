#if os(iOS)
import ComposableArchitecture
import SwiftUI
import UIKit
import XCTest
import TCAFlow

@MainActor
final class RouterNestedPushTests: XCTestCase {
    func testNestedCoordinatorThreePushesConvergeOnOneNavigationStack() async throws {
        let parent = makeStore(routes: [.root(.home)])
        let child = makeStore(routes: [.root(.nestedRoot)])
        let expectations = makeScreenExpectations()
        let root = makeRootViewController(parent: parent, child: child, expectations: expectations)
        let window = mount(root)
        defer { unmount(window) }

        let homeResult = await XCTWaiter.fulfillment(of: [expectations.home], timeout: 5)
        XCTAssertEqual(homeResult, .completed)
        parent.send(.updateRoutes([.root(.home), .push(.nestedRoot)]))
        let nestedRootResult = await XCTWaiter.fulfillment(of: [expectations.nestedRoot], timeout: 5)
        XCTAssertEqual(nestedRootResult, .completed)

        child.send(.updateRoutes([.root(.nestedRoot), .push(.chat)]))
        let chatResult = await XCTWaiter.fulfillment(of: [expectations.chat], timeout: 5)
        XCTAssertEqual(chatResult, .completed)

        child.send(.updateRoutes([.root(.nestedRoot), .push(.chat), .push(.final)]))
        let finalResult = await XCTWaiter.fulfillment(of: [expectations.final], timeout: 5)
        XCTAssertEqual(finalResult, .completed)

        let navigation = try XCTUnwrap(findNavigationController(in: root))
        XCTAssertEqual(navigation.viewControllers.count, 4)
        XCTAssertEqual(countNavigationControllers(in: root), 1)
        XCTAssertEqual(parent.withState { $0.count }, 2)
        XCTAssertEqual(child.withState { $0.count }, 3)
    }

    func testInitialDeepLinkRendersNestedCoordinatorFinalRouteWithoutDuplicateStack() async throws {
        let parent = makeStore(routes: [.root(.home), .push(.nestedRoot)])
        var childRoutes: [Route<Screen>] = [.root(.nestedRoot)]
        let handled = childRoutes.handleDeepLink(
            URL(string: "tcaflow://final/nested/chat")!,
            handler: NestedDeepLinkHandler(),
            mode: .replace
        )
        XCTAssertTrue(handled)
        XCTAssertEqual(childRoutes.map(\.screen), [.nestedRoot, .chat, .final])

        let child = makeStore(routes: childRoutes)
        let expectations = makeScreenExpectations()
        let root = makeRootViewController(parent: parent, child: child, expectations: expectations)
        let window = mount(root)
        defer { unmount(window) }

        let finalResult = await XCTWaiter.fulfillment(of: [expectations.final], timeout: 5)
        XCTAssertEqual(finalResult, .completed)

        let navigation = try XCTUnwrap(findNavigationController(in: root))
        XCTAssertEqual(navigation.viewControllers.count, 4)
        XCTAssertEqual(countNavigationControllers(in: root), 1)
        XCTAssertEqual(navigation.topViewController?.viewIfLoaded?.window, window)
        XCTAssertEqual(child.withState { $0.count }, 3)
    }

    private enum Screen: Equatable, Sendable {
        case home
        case nestedRoot
        case chat
        case final
    }

    private struct NestedDeepLinkHandler: DeepLinkHandler {
        typealias Screen = RouterNestedPushTests.Screen

        func routes(for url: URL) -> [Route<Screen>]? {
            guard url.host == "final", url.deepLinkPathComponents == ["nested", "chat"] else {
                return nil
            }
            return [.root(.nestedRoot), .push(.chat), .push(.final)]
        }
    }

    private struct ScreenExpectations {
        let home: XCTestExpectation
        let nestedRoot: XCTestExpectation
        let chat: XCTestExpectation
        let final: XCTestExpectation
    }

    private func makeScreenExpectations() -> ScreenExpectations {
        ScreenExpectations(
            home: XCTestExpectation(description: "Home appeared"),
            nestedRoot: XCTestExpectation(description: "Nested root appeared"),
            chat: XCTestExpectation(description: "Chat appeared"),
            final: XCTestExpectation(description: "Final appeared")
        )
    }

    private func makeStore(
        routes: [Route<Screen>]
    ) -> Store<[Route<Screen>], IndexedRouterAction<Screen, Never>> {
        Store(initialState: routes) {
            Reduce { state, action in
                if case let .updateRoutes(routes) = action {
                    state = routes
                }
                return .none
            }
        }
    }

    private func makeRootViewController(
        parent: Store<[Route<Screen>], IndexedRouterAction<Screen, Never>>,
        child: Store<[Route<Screen>], IndexedRouterAction<Screen, Never>>,
        expectations: ScreenExpectations
    ) -> UIHostingController<some View> {
        UIHostingController(
            rootView: TCAFlowRouter(parent) { screen in
                switch screen.store.withState({ $0 }) {
                case .home:
                    Text("Home").onAppear { expectations.home.fulfill() }
                case .nestedRoot:
                    TCAFlowRouter(child) { nested in
                        let screen = nested.store.withState { $0 }
                        Text(String(describing: screen))
                            .onAppear {
                                switch screen {
                                case .nestedRoot: expectations.nestedRoot.fulfill()
                                case .chat: expectations.chat.fulfill()
                                case .final: expectations.final.fulfill()
                                case .home: break
                                }
                            }
                    }
                case .chat, .final:
                    Text("Unexpected parent route")
                }
            }
        )
    }

    private func mount(_ root: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        return window
    }

    private func unmount(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
    }

    private func findNavigationController(in controller: UIViewController) -> UINavigationController? {
        if let navigation = controller as? UINavigationController {
            return navigation
        }
        return controller.children.lazy.compactMap { findNavigationController(in: $0) }.first
    }

    private func countNavigationControllers(in controller: UIViewController) -> Int {
        (controller is UINavigationController ? 1 : 0)
            + controller.children.reduce(0) { $0 + countNavigationControllers(in: $1) }
    }
}
#endif
