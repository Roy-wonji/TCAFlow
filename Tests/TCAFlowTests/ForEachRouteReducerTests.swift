import ComposableArchitecture
import XCTest
@testable import TCAFlow

@MainActor
final class ForEachRouteReducerTests: XCTestCase {
    @Reducer
    struct ScreenFeature {
        @ObservableState
        struct State: Equatable {
            var count = 0
        }

        @CasePathable
        enum Action {
            case increment
            case incrementLater
        }

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .increment:
                    state.count += 1
                    return .none

                case .incrementLater:
                    return .send(.increment)
                }
            }
        }
    }

    @Reducer
    struct Coordinator {
        @ObservableState
        struct State: Equatable {
            var routes: [Route<ScreenFeature.State>] = [
                .root(ScreenFeature.State(), embedInNavigationView: true)
            ]
        }

        @CasePathable
        enum Action {
            case router(IndexedRouterActionOf<ScreenFeature>)
        }

        var body: some ReducerOf<Self> {
            Reduce { _, _ in .none }
                .forEachRoute(\.routes, action: \.router) {
                    ScreenFeature()
                }
        }
    }

    func testForEachRouteRunsChildReducerForMatchingRouteIndex() async {
        let store = TestStore(initialState: Coordinator.State()) {
            Coordinator()
        }

        await store.send(.router(.routeAction(id: 0, action: .increment))) {
            $0.routes[0].screen.count = 1
        }
    }

    func testForEachRouteEmbedsChildEffectsBackIntoIndexedRouteAction() async {
        let store = TestStore(initialState: Coordinator.State()) {
            Coordinator()
        }

        await store.send(.router(.routeAction(id: 0, action: .incrementLater)))
        await store.receive {
            guard case .router(.routeAction(id: 0, action: .increment)) = $0 else {
                return false
            }
            return true
        } assert: {
            $0.routes[0].screen.count = 1
        }
    }

    func testForEachRouteIgnoresRouteActionForMissingIndex() async {
        let store = TestStore(initialState: Coordinator.State()) {
            Coordinator()
        }

        await store.send(.router(.routeAction(id: 1, action: .increment)))
    }
}
