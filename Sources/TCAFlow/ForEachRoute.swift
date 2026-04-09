import ComposableArchitecture
import CasePaths
import Foundation

// MARK: - ForEach Route Reducers

extension Reducer {
    /// ForEach for indexed routes (using Int as ID)
    public func forEachRoute<Screen, ScreenReducer: Reducer>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IndexedRouterAction<Screen, ScreenReducer.Action>>,
        @ReducerBuilder<ScreenReducer.State, ScreenReducer.Action> screenReducer: @escaping () -> ScreenReducer
    ) -> some ReducerOf<Self>
    where ScreenReducer.State == Screen {
        self.forEachRoute(
            routesPath,
            action: routerActionPath,
            screenReducer: screenReducer,
            cancellationId: { _ in Int?.none }
        )
    }

    /// ForEach for indexed routes with cancellation ID
    public func forEachRoute<Screen, ScreenReducer: Reducer, CancellationID: Hashable>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IndexedRouterAction<Screen, ScreenReducer.Action>>,
        @ReducerBuilder<ScreenReducer.State, ScreenReducer.Action> screenReducer: @escaping () -> ScreenReducer,
        cancellationId: @escaping (Screen) -> CancellationID?
    ) -> some ReducerOf<Self>
    where ScreenReducer.State == Screen {
        CombineReducers {
            self
            ForEachIndexedRoute(
                coordinatorReducer: EmptyReducer<State, Action>(),
                screenReducer: screenReducer(),
                routesPath: routesPath,
                routerActionPath: routerActionPath,
                cancellationId: cancellationId
            )
        }
    }

    /// ForEach for identified routes
    public func forEachRoute<Screen: Identifiable, ScreenReducer: Reducer>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IdentifiedRouterAction<Screen, ScreenReducer.Action>>,
        @ReducerBuilder<ScreenReducer.State, ScreenReducer.Action> screenReducer: @escaping () -> ScreenReducer
    ) -> some ReducerOf<Self>
    where ScreenReducer.State == Screen {
        self.forEachRoute(
            routesPath,
            action: routerActionPath,
            screenReducer: screenReducer,
            cancellationId: { _ in Screen.ID?.none }
        )
    }

    /// ForEach for identified routes with cancellation ID
    public func forEachRoute<Screen: Identifiable, ScreenReducer: Reducer, CancellationID: Hashable>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IdentifiedRouterAction<Screen, ScreenReducer.Action>>,
        @ReducerBuilder<ScreenReducer.State, ScreenReducer.Action> screenReducer: @escaping () -> ScreenReducer,
        cancellationId: @escaping (Screen) -> CancellationID?
    ) -> some ReducerOf<Self>
    where ScreenReducer.State == Screen {
        CombineReducers {
            self
            ForEachIdentifiedRoute(
                coordinatorReducer: EmptyReducer<State, Action>(),
                screenReducer: screenReducer(),
                routesPath: routesPath,
                routerActionPath: routerActionPath,
                cancellationId: cancellationId
            )
        }
    }
}

// MARK: - ForEach Indexed Route

public struct ForEachIndexedRoute<
    CoordinatorState,
    CoordinatorAction,
    Screen,
    ScreenAction,
    ScreenReducer: Reducer,
    CancellationID: Hashable
>: Reducer where ScreenReducer.State == Screen, ScreenReducer.Action == ScreenAction {

    let coordinatorReducer: any Reducer<CoordinatorState, CoordinatorAction>
    let screenReducer: ScreenReducer
    let routesPath: WritableKeyPath<CoordinatorState, [Route<Screen>]>
    let routerActionPath: AnyCasePath<CoordinatorAction, IndexedRouterAction<Screen, ScreenAction>>
    let cancellationId: (Screen) -> CancellationID?

    public func reduce(
        into state: inout CoordinatorState,
        action: CoordinatorAction
    ) -> Effect<CoordinatorAction> {
        guard let routerAction = routerActionPath.extract(from: action) else {
            return .none
        }

        switch routerAction {
        case let .updateRoutes(newRoutes):
            let oldRoutes = state[keyPath: routesPath]
            state[keyPath: routesPath] = newRoutes

            // Cancel effects for removed screens
            var effects: [Effect<CoordinatorAction>] = []
            for (index, route) in oldRoutes.enumerated() {
                if index >= newRoutes.count || newRoutes[safe: index]?.screen != route.screen {
                    if let id = cancellationId(route.screen) {
                        effects.append(.cancel(id: id))
                    }
                }
            }

            return .merge(effects)

        case let .routeAction(index, screenAction):
            let routes = state[keyPath: routesPath]
            guard let route = routes[safe: index] else {
                runtimeWarn(
                    """
                    A "routeAction" at index \(index) was received, but there is no screen at that index. \
                    There are \(routes.count) screens in the stack.
                    """
                )
                return .none
            }

            var screenState = route.screen
            let screenEffect = screenReducer.reduce(into: &screenState, action: screenAction)

            state[keyPath: routesPath][index].screen = screenState

            return screenEffect
                .map { routerActionPath.embed(.routeAction(index, $0)) }
                .cancellable(id: cancellationId(screenState), cancelInFlight: true)
        }
    }
}

// MARK: - ForEach Identified Route

public struct ForEachIdentifiedRoute<
    CoordinatorState,
    CoordinatorAction,
    Screen: Identifiable,
    ScreenAction,
    ScreenReducer: Reducer,
    CancellationID: Hashable
>: Reducer where ScreenReducer.State == Screen, ScreenReducer.Action == ScreenAction {

    let coordinatorReducer: any Reducer<CoordinatorState, CoordinatorAction>
    let screenReducer: ScreenReducer
    let routesPath: WritableKeyPath<CoordinatorState, [Route<Screen>]>
    let routerActionPath: AnyCasePath<CoordinatorAction, IdentifiedRouterAction<Screen, ScreenAction>>
    let cancellationId: (Screen) -> CancellationID?

    public func reduce(
        into state: inout CoordinatorState,
        action: CoordinatorAction
    ) -> Effect<CoordinatorAction> {
        guard let routerAction = routerActionPath.extract(from: action) else {
            return .none
        }

        switch routerAction {
        case let .updateRoutes(newRoutes):
            let oldRoutes = state[keyPath: routesPath]
            state[keyPath: routesPath] = newRoutes

            // Cancel effects for removed screens
            var effects: [Effect<CoordinatorAction>] = []
            let oldIds = Set(oldRoutes.map { $0.screen.id })
            let newIds = Set(newRoutes.map { $0.screen.id })

            for route in oldRoutes {
                if !newIds.contains(route.screen.id) {
                    if let id = cancellationId(route.screen) {
                        effects.append(.cancel(id: id))
                    }
                }
            }

            return .merge(effects)

        case let .routeAction(screenId, screenAction):
            let routes = state[keyPath: routesPath]
            guard let index = routes.firstIndex(where: { $0.screen.id == screenId }) else {
                runtimeWarn(
                    """
                    A "routeAction" for screen with id \(screenId) was received, but there is no screen with that id in the stack.
                    """
                )
                return .none
            }

            var screenState = routes[index].screen
            let screenEffect = screenReducer.reduce(into: &screenState, action: screenAction)

            state[keyPath: routesPath][index].screen = screenState

            return screenEffect
                .map { routerActionPath.embed(.routeAction(screenId, $0)) }
                .cancellable(id: cancellationId(screenState), cancelInFlight: true)
        }
    }
}

// MARK: - Cancellation Helpers

extension ForEachIndexedRoute {
    /// Cancel effects for a specific screen
    public func cancelEffects(for screen: Screen) -> Effect<CoordinatorAction> {
        guard let id = cancellationId(screen) else { return .none }
        return .cancel(id: id)
    }
}

extension ForEachIdentifiedRoute {
    /// Cancel effects for a specific screen
    public func cancelEffects(for screen: Screen) -> Effect<CoordinatorAction> {
        guard let id = cancellationId(screen) else { return .none }
        return .cancel(id: id)
    }
}