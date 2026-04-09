import ComposableArchitecture
import SwiftUI
import Perception

/// A SwiftUI view that renders a navigation flow based on an array of routes.
/// Based on TCACoordinators TCARouter but using NavigationStack directly.
@MainActor
public struct TCARouter<Screen, ScreenAction, ID: Hashable, ScreenContent: View>: View {
    private let store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>
    private let screenView: (Store<Screen, ScreenAction>) -> ScreenContent

    public init(
        _ store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>,
        @ViewBuilder screenView: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
    ) {
        self.store = store
        self.screenView = screenView
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.withState { $0 }

            if let rootRoute = routes.first {
                NavigationStack {
                    makeScreen(for: rootRoute, at: 0)
                        .navigationDestination(for: RouteDestination<Screen>.self) { destination in
                            makeScreen(for: destination.route, at: destination.index)
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
    private func makeScreen(for route: Route<Screen>, at index: Int) -> some View {
        let childStore = store.scope(
            state: { _ in route.screen },
            action: { RouterAction.routeAction(self.routeID(for: index), $0) }
        )
        screenView(childStore)
    }

    @ViewBuilder
    private func presentedScreens(routes: [Route<Screen>]) -> some View {
        ForEach(Array(routes.enumerated()), id: \.offset) { index, route in
            if route.isPresented {
                Color.clear
                    .sheet(isPresented: .constant(route.isSheet)) {
                        presentedContent(for: route, at: index)
                    }
                    .fullScreenCover(isPresented: .constant(route.isCover)) {
                        presentedContent(for: route, at: index)
                    }
            }
        }
    }

    @ViewBuilder
    private func presentedContent(for route: Route<Screen>, at index: Int) -> some View {
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

    // Helper to determine route ID based on index
    private func routeID(for index: Int) -> ID {
        if ID.self == Int.self {
            return index as! ID
        } else {
            // For non-Int IDs, we need additional logic
            // This is a simplified implementation
            fatalError("Non-Int ID types not yet supported in this implementation")
        }
    }
}

// MARK: - RouteDestination

/// A wrapper type for NavigationStack destinations
public struct RouteDestination<Screen>: Hashable where Screen: Hashable {
    public let route: Route<Screen>
    public let index: Int

    public init(route: Route<Screen>, index: Int) {
        self.route = route
        self.index = index
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }

    public static func == (lhs: RouteDestination<Screen>, rhs: RouteDestination<Screen>) -> Bool {
        return lhs.index == rhs.index
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

// MARK: - Indexed TCARouter

/// Convenience initializer for indexed routing (using Int as ID)
public struct IndexedTCARouter<Screen, ScreenAction, ScreenContent: View>: View {
    private let tcaRouter: TCARouter<Screen, ScreenAction, Int, ScreenContent>

    public init(
        _ store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
        @ViewBuilder screenView: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
    ) {
        self.tcaRouter = TCARouter(store, screenView: screenView)
    }

    public var body: some View {
        tcaRouter
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

// MARK: - Observation Support

extension TCARouter {
    /// Alternative implementation for when Screen is not ObservableState
    public init<LocalState, LocalAction>(
        _ store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>,
        @ViewBuilder screenView: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
    ) where Screen == LocalState, ScreenAction == LocalAction {
        self.store = store
        self.screenView = screenView
    }
}

// MARK: - Router Action Extensions

extension RouterAction.AllCasePaths {
    /// Subscript for accessing route actions by ID
    public subscript<ID: Hashable, Screen, ScreenAction>(
        id: ID
    ) -> AnyCasePath<RouterAction<ID, Screen, ScreenAction>, ScreenAction> {
        AnyCasePath(
            embed: { RouterAction.routeAction(id, $0) },
            extract: {
                guard case let .routeAction(routeId, action) = $0, routeId == id else { return nil }
                return action
            }
        )
    }
}

// MARK: - Convenience Functions

extension Store where State == [Route<some Any>] {
    /// Pushes a new screen onto the navigation stack
    public func push<Screen>(_ screen: Screen) where State == [Route<Screen>] {
        var routes = self.state
        routes.push(screen)
        self.send(.updateRoutes(routes) as! Action)
    }

    /// Presents a screen as a sheet
    public func presentSheet<Screen>(_ screen: Screen, withNavigation: Bool = false) where State == [Route<Screen>] {
        var routes = self.state
        routes.presentSheet(screen, withNavigation: withNavigation)
        self.send(.updateRoutes(routes) as! Action)
    }

    /// Presents a screen as a full screen cover
    public func presentCover<Screen>(_ screen: Screen, withNavigation: Bool = false) where State == [Route<Screen>] {
        var routes = self.state
        routes.presentCover(screen, withNavigation: withNavigation)
        self.send(.updateRoutes(routes) as! Action)
    }

    /// Pops the topmost route
    public func pop() {
        var routes = self.state
        routes.pop()
        self.send(.updateRoutes(routes) as! Action)
    }

    /// Pops to root
    public func popToRoot() {
        var routes = self.state
        routes.popToRoot()
        self.send(.updateRoutes(routes) as! Action)
    }

    /// Dismisses the topmost presented route
    public func dismiss() {
        var routes = self.state
        routes.dismiss()
        self.send(.updateRoutes(routes) as! Action)
    }
}