import ComposableArchitecture
import CasePaths
import Foundation

// MARK: - ForEach Route Reducers (TCACoordinators style)

extension Reducer {
    /// ForEach for indexed routes - TCACoordinators simple API
    /// Usage: .forEachRoute(\.routes, action: \.router)
    public func forEachRoute<Screen: CaseReducerState>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IndexedRouterAction<Screen, Screen.StateReducer.Action>>
    ) -> some ReducerOf<Self>
    where Screen.StateReducer.State == Screen {
        CombineReducers {
            self
            ForEachIndexedRoute(
                routesPath: routesPath,
                routerActionPath: routerActionPath
            )
        }
    }

    /// ForEach for identified routes - TCACoordinators simple API
    /// Usage: .forEachRoute(\.routes, action: \.router)
    public func forEachRoute<Screen: CaseReducerState & Identifiable>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IdentifiedRouterAction<Screen, Screen.StateReducer.Action>>
    ) -> some ReducerOf<Self>
    where Screen.StateReducer.State == Screen {
        CombineReducers {
            self
            ForEachIdentifiedRoute(
                routesPath: routesPath,
                routerActionPath: routerActionPath
            )
        }
    }
}

// MARK: - ForEach Indexed Route (Simplified)

public struct ForEachIndexedRoute<
    CoordinatorState,
    CoordinatorAction,
    Screen: CaseReducerState
>: Reducer where Screen.StateReducer.State == Screen {

    let routesPath: WritableKeyPath<CoordinatorState, [Route<Screen>]>
    let routerActionPath: AnyCasePath<CoordinatorAction, IndexedRouterAction<Screen, Screen.StateReducer.Action>>

    public func reduce(
        into state: inout CoordinatorState,
        action: CoordinatorAction
    ) -> Effect<CoordinatorAction> {
        guard let routerAction = routerActionPath.extract(from: action) else {
            return .none
        }

        switch routerAction {
        case let .updateRoutes(newRoutes):
            state[keyPath: routesPath] = newRoutes
            return .none

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
            let screenReducer = Screen.StateReducer()
            let screenEffect = screenReducer.reduce(into: &screenState, action: screenAction)

            state[keyPath: routesPath][index].screen = screenState

            return screenEffect
                .map { routerActionPath.embed(.routeAction(index, $0)) }
        }
    }
}

// MARK: - ForEach Identified Route (Simplified)

public struct ForEachIdentifiedRoute<
    CoordinatorState,
    CoordinatorAction,
    Screen: CaseReducerState & Identifiable
>: Reducer where Screen.StateReducer.State == Screen {

    let routesPath: WritableKeyPath<CoordinatorState, [Route<Screen>]>
    let routerActionPath: AnyCasePath<CoordinatorAction, IdentifiedRouterAction<Screen, Screen.StateReducer.Action>>

    public func reduce(
        into state: inout CoordinatorState,
        action: CoordinatorAction
    ) -> Effect<CoordinatorAction> {
        guard let routerAction = routerActionPath.extract(from: action) else {
            return .none
        }

        switch routerAction {
        case let .updateRoutes(newRoutes):
            state[keyPath: routesPath] = newRoutes
            return .none

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
            let screenReducer = Screen.StateReducer()
            let screenEffect = screenReducer.reduce(into: &screenState, action: screenAction)

            state[keyPath: routesPath][index].screen = screenState

            return screenEffect
                .map { routerActionPath.embed(.routeAction(screenId, $0)) }
        }
    }
}