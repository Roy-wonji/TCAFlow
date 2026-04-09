import ComposableArchitecture
import SwiftUI
import Perception

/// A SwiftUI view that renders a navigation flow based on an array of routes.
/// Usage: TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screens in ... }
@MainActor
public struct TCAFlowRouter<Screen: CaseReducer, ScreenContent: View>: View {
    private let store: Store<[Route<Screen.State>], IndexedRouterAction<Screen.State, Screen.Action>>
    private let screenView: (Screen.CaseScope) -> ScreenContent

    public init(
        _ store: Store<[Route<Screen.State>], IndexedRouterAction<Screen.State, Screen.Action>>,
        @ViewBuilder screenView: @escaping (Screen.CaseScope) -> ScreenContent
    ) {
        self.store = store
        self.screenView = screenView
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.state

            if let rootRoute = routes.first {
                if rootRoute.embedInNavigationView {
                    NavigationStack {
                        makeScreen(for: rootRoute, at: 0)
                            .navigationDestination(for: Int.self) { index in
                                if index > 0 && index < routes.count {
                                    makeScreen(for: routes[index], at: index)
                                }
                            }
                    }
                    .overlay {
                        presentedScreens(routes: routes)
                    }
                } else {
                    makeScreen(for: rootRoute, at: 0)
                        .overlay {
                            presentedScreens(routes: routes)
                        }
                }
            } else {
                Text("No Routes")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func makeScreen(for route: Route<Screen.State>, at index: Int) -> some View {
        let caseScope = Screen.scope(
            store.scope(
                state: { _ in route.screen },
                action: { RouterAction.routeAction(index, $0) }
            )
        )
        screenView(caseScope)
    }

    @ViewBuilder
    private func presentedScreens(routes: [Route<Screen.State>]) -> some View {
        ForEach(routes.indices, id: \.self) { index in
            let route = routes[index]
            if route.isPresented {
                Color.clear
                    .sheet(isPresented: .constant(route.isSheet)) {
                        presentedContent(for: route, at: index)
                    }
                    #if !os(macOS)
                    .fullScreenCover(isPresented: .constant(route.isCover)) {
                        presentedContent(for: route, at: index)
                    }
                    #endif
            }
        }
    }

    @ViewBuilder
    private func presentedContent(for route: Route<Screen.State>, at index: Int) -> some View {
        let content = makeScreen(for: route, at: index)

        if route.embedInNavigationView {
            NavigationStack {
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                store.send(.updateRoutes(Array(store.state.dropLast())))
                            }
                        }
                    }
            }
        } else {
            content
        }
    }
}

// MARK: - Route Helpers

extension Route {
    /// Whether this route is a sheet presentation.
    public var isSheet: Bool {
        if case .sheet = self { return true }
        return false
    }

    /// Whether this route is a cover presentation.
    public var isCover: Bool {
        if case .cover = self { return true }
        return false
    }
}

// MARK: - Type Aliases

/// Convenience type alias for indexed router actions.
public typealias IndexedRouterAction<Screen, ScreenAction> = RouterAction<Int, Screen, ScreenAction>

/// Convenience type alias for indexed router actions with reducer.
public typealias IndexedRouterActionOf<R: Reducer> = RouterAction<Int, R.State, R.Action>

/// Convenience type alias for identified router actions.
public typealias IdentifiedRouterAction<Screen: Identifiable, ScreenAction> = RouterAction<Screen.ID, Screen, ScreenAction>

/// Convenience type alias for identified router actions with reducer.
public typealias IdentifiedRouterActionOf<R: Reducer> = RouterAction<R.State.ID, R.State, R.Action> where R.State: Identifiable