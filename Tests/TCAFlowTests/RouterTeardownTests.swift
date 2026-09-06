#if os(iOS)
import ComposableArchitecture
import SwiftUI
import UIKit
import XCTest
@testable import TCAFlow

@MainActor
final class RouterTeardownTests: XCTestCase {
    @Reducer
    struct Feature {
        @ObservableState
        struct State {
            var parent: [Route<Int>]? = [.root(0), .push(1)]
            var child: [Route<Int>]? = [.root(0)]
            var lateActions = 0
            var appearances = 0
        }

        @CasePathable
        enum Action {
            case parent(IndexedRouterAction<Int, ScreenAction>)
            case child(IndexedRouterAction<Int, ScreenAction>)
            case signOut
        }

        enum ScreenAction { case appeared }

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .signOut:
                    state.parent = nil
                    state.child = nil
                case let .parent(.updateRoutes(routes)):
                    if state.parent != nil { state.parent = routes }
                    else { state.lateActions += 1 }
                case let .child(.updateRoutes(routes)):
                    if state.child != nil { state.child = routes }
                    else { state.lateActions += 1 }
                case .parent(.routeAction), .child(.routeAction):
                    if state.parent == nil { state.lateActions += 1 }
                    else { state.appearances += 1 }
                }
                return .none
            }
        }
    }

    struct RootView: View {
        let store: StoreOf<Feature>

        var body: some View {
            ZStack {
                if let parent = store.scope(\.parent, action: \.parent),
                   let child = store.scope(\.child, action: \.child) {
                    TCAFlowRouter(parent) { screen in
                        if screen.store.withState({ $0 }) == 0 {
                            Text("Home")
                        } else {
                            TCAFlowRouter(child) { nested in
                                Text("Profile")
                                    .onAppear { nested.store.send(.appeared) }
                            }
                        }
                    }
                    .transition(.opacity)
                } else {
                    Text("Auth")
                }
            }
            .animation(.easeInOut(duration: 0.2), value: store.parent == nil)
        }
    }

    func testAnimatedParentRemovalDoesNotSendActionsFromNestedRouter() async throws {
        let store = Store(initialState: Feature.State()) { Feature() }
        let root = UIHostingController(rootView: RootView(store: store))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        for _ in 0..<100 where store.appearances == 0 {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertGreaterThan(store.appearances, 0)
        store.send(.child(.updateRoutes([.root(0), .push(1)])))
        for _ in 0..<100 where store.appearances < 2 {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertGreaterThanOrEqual(store.appearances, 2)
        store.send(.signOut)
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertNil(store.parent)
        XCTAssertNil(store.child)
        XCTAssertEqual(store.lateActions, 0)
    }
}
#endif
