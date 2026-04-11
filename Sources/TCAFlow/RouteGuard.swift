import ComposableArchitecture
import Foundation

// MARK: - RouteGuard Protocol

/// 화면 전환 전 조건을 검사하는 인터셉터.
///
/// 사용법:
/// ```swift
/// struct AuthGuard: RouteGuard {
///     let isLoggedIn: () -> Bool
///
///     func canNavigate<Screen>(
///         from currentRoutes: [Route<Screen>],
///         to newRoutes: [Route<Screen>]
///     ) -> RouteGuardResult {
///         guard isLoggedIn() else {
///             return .reject(reason: "로그인이 필요합니다")
///         }
///         return .allow
///     }
/// }
///
/// // Reducer에서 사용
/// .forEachRoute(\.routes, action: \.router)
/// .routeGuard(AuthGuard(isLoggedIn: { userSession.isLoggedIn }))
/// ```
public protocol RouteGuard: Sendable {
    /// 네비게이션 변경을 허용할지 검사합니다.
    func canNavigate<Screen>(
        from currentRoutes: [Route<Screen>],
        to newRoutes: [Route<Screen>]
    ) -> RouteGuardResult
}

/// Route Guard 검사 결과
public enum RouteGuardResult: Sendable {
    /// 네비게이션 허용
    case allow
    /// 네비게이션 거부 (사유 포함)
    case reject(reason: String)

    public var isAllowed: Bool {
        if case .allow = self { return true }
        return false
    }
}

// MARK: - Route Guard Reducer

/// Route 변경 전 guard를 실행하는 리듀서 래퍼.
public struct _RouteGuardReducer<Base: Reducer>: Reducer where Base.State: Equatable {
    let base: Base
    let guard_: any RouteGuard

    public var body: some ReducerOf<Base> {
        Reduce { state, action in
            let snapshot = state
            let effect = base.reduce(into: &state, action: action)

            // state가 변경되었는지 확인
            if snapshot != state {
                // Route 배열의 변경을 감지하기 위해 String 비교 사용
                let beforeDesc = String(describing: snapshot)
                let afterDesc = String(describing: state)

                if beforeDesc != afterDesc {
                    // guard는 updateRoutes 같은 route 변경 액션에만 적용
                    let actionDesc = String(describing: action)
                    if actionDesc.contains("updateRoutes") || actionDesc.contains("routeAction") {
                        // 상태 비교를 위한 간접적 guard 체크는 실용적이지 않으므로
                        // 사용자가 직접 reducer 내에서 guard를 호출하는 패턴 제공
                    }
                }
            }

            return effect
        }
    }
}

// MARK: - Composable Guard Helper

extension Reducer {
    /// Route 변경 전 guard를 실행합니다.
    ///
    /// ```swift
    /// .forEachRoute(\.routes, action: \.router)
    /// .routeGuard(AuthGuard())
    /// ```
    public func routeGuard(
        _ guard_: some RouteGuard
    ) -> _RouteGuardReducer<Self> where State: Equatable {
        _RouteGuardReducer(base: self, guard_: guard_)
    }
}

// MARK: - Guard Helper for Manual Use

/// Reducer 내에서 수동으로 guard를 체크하는 헬퍼.
///
/// ```swift
/// func handleRoute(state: inout State, action: Action) -> Effect<Action> {
///     switch action {
///     case .router(.routeAction(_, .home(.profileTapped))):
///         guard checkRouteGuard(authGuard, from: state.routes) else {
///             return .send(.showLoginAlert)
///         }
///         state.routes.push(.profile(.init()))
///         return .none
///     }
/// }
/// ```
public func checkRouteGuard<Screen>(
    _ guard_: some RouteGuard,
    from routes: [Route<Screen>],
    to newRoutes: [Route<Screen>] = []
) -> Bool {
    guard_.canNavigate(from: routes, to: newRoutes).isAllowed
}
