import ComposableArchitecture
import SwiftUI
import Perception

/// A SwiftUI view that renders a navigation flow based on an array of routes.
/// Usage: TCAFlowRouter(store) { screens in switch screens.case { ... } }
@MainActor
public struct TCAFlowRouter<Screen: CaseReducer, ScreenContent: View>: View {
    private let store: Store<[Route<Screen.State>], IndexedRouterAction<Screen.State, Screen.Action>>
    private let screenView: (CaseScope<Screen>) -> ScreenContent

    public init(
        _ store: Store<[Route<Screen.State>], IndexedRouterAction<Screen.State, Screen.Action>>,
        @ViewBuilder screenView: @escaping (CaseScope<Screen>) -> ScreenContent
    ) {
        self.store = store
        self.screenView = screenView
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.state

            if let rootRoute = routes.first {
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
                Text("No Routes")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func makeScreen(for route: Route<Screen.State>, at index: Int) -> some View {
        let caseScope = CaseScope<Screen>(
            route: route,
            index: index,
            store: store
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

        if route.withNavigation {
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

// MARK: - CaseScope (TCACoordinators style)

/// Provides TCACoordinators-style case access pattern
/// Usage: switch screens.case { case .login(let store): ... }
public struct CaseScope<Screen: CaseReducer> {
    private let route: Route<Screen.State>
    private let index: Int
    private let store: Store<[Route<Screen.State>], IndexedRouterAction<Screen.State, Screen.Action>>

    internal init(
        route: Route<Screen.State>,
        index: Int,
        store: Store<[Route<Screen.State>], IndexedRouterAction<Screen.State, Screen.Action>>
    ) {
        self.route = route
        self.index = index
        self.store = store
    }

    /// The screen case for pattern matching
    /// Usage: switch screens.case { case .login(let store): ... }
    public var `case`: Screen {
        return Screen.scope(
            store.scope(
                state: { _ in self.route.screen },
                action: { RouterAction.routeAction(self.index, $0) }
            )
        )
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