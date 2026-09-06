#if os(iOS)
import ComposableArchitecture
import SwiftUI
import UIKit
import XCTest
@testable import TCAFlow

@MainActor
final class RouterSafeAreaTests: XCTestCase {
    func testRootContainerFillsBoundsAndPreservesScreenSafeArea() async throws {
        try await assertSafeAreaLayout(routes: [.root(0)], visibleScreen: 0)
    }

    func testPushedContainerFillsBoundsAndPreservesScreenSafeArea() async throws {
        try await assertSafeAreaLayout(routes: [.root(0), .push(1)], visibleScreen: 1)
    }

    func testStorePushAndUIKitPopStaySynchronized() async throws {
        try await assertSafeAreaLayout(
            routes: [.root(0), .push(1)], visibleScreen: 1, pushAfterMount: true
        )
    }

    func testNestedRouterPushUsesParentStackAndPopUpdatesOnlyChild() async throws {
        let parent = makeStore(routes: [.root(0)])
        let child = makeStore(routes: [.root(0)])
        let rootAppeared = XCTestExpectation(description: "Nested root appeared")
        let detailAppeared = XCTestExpectation(description: "Nested detail appeared")
        let root = UIHostingController(rootView: TCAFlowRouter(parent) { _ in
            TCAFlowRouter(child) { screen in
                Text("Child")
                    .swipeBackButtonHidden()
                    .onAppear {
                        if screen.store.withState({ $0 }) == 0 {
                            rootAppeared.fulfill()
                        } else {
                            detailAppeared.fulfill()
                        }
                    }
            }
        })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let initialResult = await XCTWaiter.fulfillment(of: [rootAppeared], timeout: 5)
        XCTAssertEqual(initialResult, .completed)
        child.send(.updateRoutes([.root(0), .push(1)]))
        let detailResult = await XCTWaiter.fulfillment(of: [detailAppeared], timeout: 5)
        XCTAssertEqual(detailResult, .completed)

        let navigation = try XCTUnwrap(findNavigationController(in: root))
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertNil(navigation.topViewController.flatMap { controller in
            controller.children.compactMap { findNavigationController(in: $0) }.first
        })
        let popped = XCTestExpectation(description: "Nested pop updates child")
        let subscription = child.publisher.sink { routes in
            if routes.count == 1 { popped.fulfill() }
        }
        navigation.popViewController(animated: false)
        let popResult = await XCTWaiter.fulfillment(of: [popped], timeout: 5)
        XCTAssertEqual(popResult, .completed)
        XCTAssertEqual(child.withState { $0.count }, 1)
        XCTAssertEqual(parent.withState { $0.count }, 1)
        subscription.cancel()
    }

    private func makeStore(routes: [Route<Int>]) -> Store<[Route<Int>], IndexedRouterAction<Int, Never>> {
        Store(initialState: routes) {
            Reduce { state, action in
                if case let .updateRoutes(routes) = action { state = routes }
                return .none
            }
        }
    }

    private func assertSafeAreaLayout(
        routes: [Route<Int>],
        visibleScreen: Int,
        pushAfterMount: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let appeared = XCTestExpectation(description: "Visible route appeared")
        let rootAppeared = XCTestExpectation(description: "Root route appeared")
        let initialRoutes = pushAfterMount ? Array(routes.prefix(1)) : routes
        let store = Store<[Route<Int>], IndexedRouterAction<Int, Never>>(initialState: initialRoutes) {
            Reduce { state, action in
                if case let .updateRoutes(routes) = action {
                    state = routes
                }
                return .none
            }
        }
        let root = UIHostingController(
            rootView: TCAFlowRouter(store) { screen in
                Text("Screen")
                    .swipeBackButtonHidden()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red.ignoresSafeArea())
                    .onAppear {
                        if screen.store.withState({ $0 }) == 0 {
                            rootAppeared.fulfill()
                        }
                        if screen.store.withState({ $0 }) == visibleScreen {
                            appeared.fulfill()
                        }
                    }
            }
        )
        // Deterministic nonzero insets, including on a simulator without a home indicator.
        root.additionalSafeAreaInsets = UIEdgeInsets(top: 31, left: 0, bottom: 29, right: 0)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        if pushAfterMount {
            let rootResult = await XCTWaiter.fulfillment(of: [rootAppeared], timeout: 5)
            XCTAssertEqual(rootResult, .completed, file: file, line: line)
            store.send(.updateRoutes(routes))
        }

        let result = await XCTWaiter.fulfillment(of: [appeared], timeout: 5)
        XCTAssertEqual(result, .completed, file: file, line: line)
        window.layoutIfNeeded()
        root.view.layoutIfNeeded()

        let navigation = try XCTUnwrap(findNavigationController(in: root), file: file, line: line)
        // SwiftUI can call onAppear before UIKit finishes installing a seeded path.
        for _ in 0..<100 where navigation.viewControllers.count != routes.count {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        navigation.view.layoutIfNeeded()
        let containerFrame = navigation.view.convert(navigation.view.bounds, to: root.view)
        XCTAssertEqual(containerFrame.minY, root.view.bounds.minY, accuracy: 1, file: file, line: line)
        XCTAssertEqual(containerFrame.maxY, root.view.bounds.maxY, accuracy: 1, file: file, line: line)
        XCTAssertEqual(navigation.viewControllers.count, routes.count, file: file, line: line)

        let screen = try XCTUnwrap(navigation.topViewController, file: file, line: line)
        screen.view.layoutIfNeeded()
        // Filling the container must not remove the hosted screen's content protection.
        XCTAssertGreaterThan(screen.view.safeAreaInsets.top, 0, file: file, line: line)
        XCTAssertGreaterThan(screen.view.safeAreaInsets.bottom, 0, file: file, line: line)

        if routes.count > 1 {
            let popped = XCTestExpectation(description: "UIKit pop updates route state")
            let subscription = store.publisher.sink { routes in
                if routes.count == 1 { popped.fulfill() }
            }
            navigation.popViewController(animated: false)
            let popResult = await XCTWaiter.fulfillment(of: [popped], timeout: 5)
            XCTAssertEqual(popResult, .completed, file: file, line: line)
            XCTAssertEqual(store.withState { $0.count }, 1, file: file, line: line)
            subscription.cancel()
        }
    }

    private func findNavigationController(in controller: UIViewController) -> UINavigationController? {
        if let navigation = controller as? UINavigationController {
            return navigation
        }
        return controller.children.lazy.compactMap { self.findNavigationController(in: $0) }.first
    }
}
#endif
