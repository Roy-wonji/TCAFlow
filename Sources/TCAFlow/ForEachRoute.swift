import ComposableArchitecture
import CasePaths
import Foundation

// MARK: - ForEach Route Reducers (Simplified for basic functionality)

extension Reducer {
    /// ForEach for indexed routes - simplified version without CaseReducerState dependency
    /// Usage: .forEachRoute(\.routes, action: \.router)
    public func forEachRoute<Screen, ScreenAction>(
        _ routesPath: WritableKeyPath<State, [Route<Screen>]>,
        action routerActionPath: AnyCasePath<Action, IndexedRouterAction<Screen, ScreenAction>>
    ) -> some ReducerOf<Self> {
        CombineReducers {
            self
            Reduce { state, action in
                guard let routerAction = routerActionPath.extract(from: action) else {
                    return .none
                }

                switch routerAction {
                case let .updateRoutes(newRoutes):
                    state[keyPath: routesPath] = newRoutes
                    return .none

                case let .routeAction(index, screenAction):
                    // Basic route action handling - this would need to be expanded
                    // for full functionality with actual screen reducers
                    runtimeWarn(
                        """
                        RouteAction received at index \(index) with action \(screenAction).
                        Full screen reducer integration not yet implemented.
                        """
                    )
                    return .none
                }
            }
        }
    }
}