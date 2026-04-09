import ComposableArchitecture
import Foundation
import IdentifiedCollections

@ObservableState
public struct Route<State: Equatable>: Identifiable, Equatable, Hashable {
    public let id: UUID
    public var state: State
    public var embedInNavigationView: Bool

    public init(id: UUID = UUID(), _ state: State, embedInNavigationView: Bool = true) {
        self.id = id
        self.state = state
        self.embedInNavigationView = embedInNavigationView
    }

    public static func root(_ state: State, embedInNavigationView: Bool = true) -> Self {
        Self(state, embedInNavigationView: embedInNavigationView)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.state == rhs.state
            && lhs.embedInNavigationView == rhs.embedInNavigationView
    }
}

@ObservableState
public struct RouteStack<State: Equatable>: Equatable {
    public var routes: IdentifiedArrayOf<Route<State>>

    public init(_ routes: IdentifiedArrayOf<Route<State>> = []) {
        self.routes = routes
    }

    public init(_ routes: [Route<State>]) {
        self.routes = IdentifiedArray(uniqueElements: routes)
    }
}

extension RouteStack: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Route<State>...) {
        self.init(elements)
    }
}

extension RouteStack {
    public var currentRoute: Route<State>? {
        self.routes.currentRoute
    }

    public var rootRoute: Route<State>? {
        self.routes.rootRoute
    }

    public var depth: Int {
        self.routes.depth
    }

    public var count: Int {
        self.routes.count
    }

    public var isEmpty: Bool {
        self.routes.isEmpty
    }

    public mutating func push(_ state: State) {
        self.routes.push(state)
    }

    @discardableResult
    public mutating func pop() -> Route<State>? {
        self.routes.pop()
    }

    public mutating func popToRoot() {
        self.routes.popToRoot()
    }

    public mutating func replace(with state: State) {
        self.routes.replace(with: state)
    }

    public mutating func goTo(_ targetScreen: State) {
        self.routes.goTo(targetScreen)
    }

    public mutating func goBackTo(_ targetScreen: State) {
        self.routes.goBackTo(targetScreen)
    }
}

@CasePathable
public enum FlowAction<Screen: CaseReducer> {
    case routeAction(id: UUID, action: Screen.Action)
    case pathChanged([UUID])

    // MARK: - 하위 호환성을 위한 computed property

    /// 하위 호환성을 위한 기존 element property
    public var element: (id: UUID, action: Screen.Action)? {
        guard case let .routeAction(id, action) = self else { return nil }
        return (id, action)
    }

    // MARK: - 개선된 패턴 매칭을 위한 편의 메서드

    /// 특정 스크린 액션과 매칭하는지 확인
    public func isScreenAction<T>(_ action: T) -> Bool where T: Equatable {
        guard case let .routeAction(_, screenAction) = self,
              let typedAction = screenAction as? T else { return false }
        return typedAction == action
    }

    /// 스크린 액션 타입과 매칭하는지 확인
    public func isScreenActionType<T>(_: T.Type) -> Bool {
        guard case let .routeAction(_, screenAction) = self else { return false }
        return screenAction is T
    }

    /// 특정 ID의 스크린 액션과 매칭
    public func matchesRoute(id targetID: UUID, action targetAction: Screen.Action) -> Bool where Screen.Action: Equatable {
        guard case let .routeAction(id, action) = self else { return false }
        return id == targetID && action == targetAction
    }

    /// 스크린 액션만 추출 (ID 무시)
    public var screenAction: Screen.Action? {
        guard case let .routeAction(_, action) = self else { return nil }
        return action
    }

    /// 스크린 ID만 추출
    public var routeID: UUID? {
        guard case let .routeAction(id, _) = self else { return nil }
        return id
    }
}

// MARK: - 패턴 매칭을 위한 편의 확장

extension FlowAction {
    /// if case 문을 간단하게 만들어주는 정적 메서드들

    /// 특정 액션 타입으로 케스팅이 가능한지 확인
    public static func ~=<T>(pattern: T, value: FlowAction) -> Bool where T: Equatable {
        return value.isScreenAction(pattern)
    }
}

// MARK: - 매크로에서 생성된 Action과의 편의 매칭

extension FlowAction {
    /// 매크로에서 생성된 스크린 액션과 매칭하기 위한 헬퍼 (CasePaths 지원)
    public func matches<ScreenAction, Value>(_ casePath: AnyCasePath<ScreenAction, Value>) -> Value? {
        guard let screenAction = self.screenAction as? ScreenAction else { return nil }
        return casePath.extract(from: screenAction)
    }

    /// 특정 케이스인지 확인
    public func isCase<ScreenAction, Value>(_ casePath: AnyCasePath<ScreenAction, Value>) -> Bool {
        return matches(casePath) != nil
    }
}

// MARK: - 간편한 패턴 매칭을 위한 케이스 분해 메서드

extension FlowAction {
    /// 화면 액션과 ID를 분해하여 클로저에 전달 - 깔끔한 API
    @discardableResult
    public func ifRouteAction<T>(
        _ handler: (UUID, Screen.Action) -> T
    ) -> T? {
        guard case let .routeAction(id, action) = self else { return nil }
        return handler(id, action)
    }

    /// 특정 화면의 액션인 경우에만 클로저 실행
    @discardableResult
    public func ifScreenAction<T, ScreenAction>(
        as screenActionType: ScreenAction.Type,
        _ handler: (UUID, ScreenAction) -> T
    ) -> T? {
        guard case let .routeAction(id, action) = self,
              let screenAction = action as? ScreenAction else { return nil }
        return handler(id, screenAction)
    }

    /// ID는 무시하고 화면 액션만 처리
    @discardableResult
    public func ifScreenAction<T>(
        _ handler: (Screen.Action) -> T
    ) -> T? {
        guard let action = screenAction else { return nil }
        return handler(action)
    }

    // MARK: - 하위 호환성을 위한 별칭 메서드
    @discardableResult
    public func ifElement<T>(
        _ handler: (UUID, Screen.Action) -> T
    ) -> T? {
        return ifRouteAction(handler)
    }
}

public typealias FlowActionOf<Screen: CaseReducer> = FlowAction<Screen>

public protocol FlowCoordinating: Reducer {
    associatedtype ScreenReducer: CaseReducer where ScreenReducer.State: Equatable

    static var flowRoutes: KeyPath<State, RouteStack<ScreenReducer.State>> { get }
    static func flowAction(_ action: FlowAction<ScreenReducer>) -> Action
}

extension IdentifiedArray where ID == UUID {
    public var currentRoute: Element? {
        self.last
    }

    public var rootRoute: Element? {
        self.first
    }

    public var depth: Int {
        self.count
    }
}

extension IdentifiedArray where ID == UUID {
    public mutating func push<S: Equatable>(_ state: S) where Element == Route<S> {
        self.append(Route(state))
    }

    @discardableResult
    public mutating func pop() -> Element? {
        guard !self.isEmpty else { return nil }
        return self.removeLast()
    }

    public mutating func popToRoot() {
        while self.count > 1 {
            self.removeLast()
        }
    }

    public mutating func replace<S: Equatable>(with state: S) where Element == Route<S> {
        guard let currentRoute else {
            self.push(state)
            return
        }
        self[id: currentRoute.id]?.state = state
    }

    public func currentScreen<S: Equatable>() -> S? where Element == Route<S> {
        self.last?.state
    }

    public func rootScreen<S: Equatable>() -> S? where Element == Route<S> {
        self.first?.state
    }

    public func has<S: Equatable>(_ targetScreen: S) -> Bool where Element == Route<S> {
        self.contains { $0.state.matchesCase(of: targetScreen) }
    }

    public mutating func goTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        if let index = self.firstIndex(where: { $0.state.matchesCase(of: targetScreen) }) {
            while self.count > index + 1 {
                self.removeLast()
            }
        } else {
            self.append(Route(targetScreen))
        }
    }

    public mutating func goBackTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        while let last = self.last, !last.state.matchesCase(of: targetScreen) {
            self.removeLast()
        }
    }

}

private extension Equatable {
    func matchesCase(of other: Self) -> Bool {
        String(describing: self).split(separator: "(").first
            == String(describing: other).split(separator: "(").first
    }
}

// MARK: - RouteStack Utilities

extension Reducer {
    /// 🚀 TCAFlow 개선: RouteStack의 pathChanged 액션을 자동으로 처리합니다.
    /// 기본 버전 - pathChanged만 처리
    public func forEachRoute<Screen: CaseReducer>(
        _ routeStackKeyPath: WritableKeyPath<State, RouteStack<Screen.State>>,
        action routeActionKeyPath: AnyCasePath<Action, FlowAction<Screen>>
    ) -> some ReducerOf<Self> {
        CombineReducers {
            self

            // pathChanged 자동 처리
            Reduce<State, Action> { state, action in
                guard let flowAction = routeActionKeyPath.extract(from: action),
                      case let .pathChanged(path) = flowAction else {
                    return .none
                }

                // 경로 변경 자동 처리
                let routeIDs = [state[keyPath: routeStackKeyPath].routes.first?.id].compactMap { $0 } + path
                while let last = state[keyPath: routeStackKeyPath].routes.last,
                      !routeIDs.contains(last.id) {
                    state[keyPath: routeStackKeyPath].pop()
                }
                return .none
            }
        }
    }

    /// 🚀 TCAFlow 개선: RouteStack의 child reducer들을 자동으로 연결하고 pathChanged도 처리합니다.
    /// 이제 각 route의 액션이 자동으로 해당 Feature reducer에서 처리됩니다!
    ///
    /// 사용법:
    /// ```swift
    /// var body: some ReducerOf<Self> {
    ///   Reduce { state, action in
    ///     switch action {
    ///     case .route(.routeAction(let id, let screenAction)):
    ///       // Coordinator 레벨에서 처리할 액션들만 여기서 처리
    ///       // (navigation, delegation 등)
    ///       return handleScreenAction(screenAction, id: id, state: &state)
    ///     case .route:
    ///       return .none  // pathChanged는 자동 처리됨
    ///     }
    ///   }
    ///   .forEachRoute(\.routes, action: \.route) { Screen() }  // 🎯 child reducer 자동 연결!
    /// }
    /// ```
    public func forEachRoute<Screen: CaseReducer>(
        _ routeStackKeyPath: WritableKeyPath<State, RouteStack<Screen.State>>,
        action routeActionKeyPath: AnyCasePath<Action, FlowAction<Screen>>,
        @ReducerBuilder<Screen.State, Screen.Action> destination: @escaping () -> Screen
    ) -> some ReducerOf<Self> {
        CombineReducers {
            self

            // 🎯 Child reducer들을 자동으로 연결
            Reduce<State, Action> { state, action in
                guard let flowAction = routeActionKeyPath.extract(from: action) else {
                    return .none
                }

                switch flowAction {
                case let .routeAction(id, screenAction):
                    // child reducer로 액션 전달을 위한 준비
                    // 실제 처리는 .forEach에서 담당
                    return .none

                case let .pathChanged(path):
                    // 경로 변경 자동 처리
                    let routeIDs = [state[keyPath: routeStackKeyPath].routes.first?.id].compactMap { $0 } + path
                    while let last = state[keyPath: routeStackKeyPath].routes.last,
                          !routeIDs.contains(last.id) {
                        state[keyPath: routeStackKeyPath].pop()
                    }
                    return .none
                }
            }
            .forEach(
                routeStackKeyPath.appending(path: \.routes),
                action: routeActionKeyPath.appending(path: /FlowAction<Screen>.routeAction)
            ) {
                destination()
            }
        }
    }
}

// MARK: - RouteStack Action Helpers

extension FlowAction {
    /// RouteAction에서 ID와 액션을 추출하는 헬퍼
    public var routeInfo: (id: UUID, action: Screen.Action)? {
        guard case let .routeAction(id, action) = self else { return nil }
        return (id: id, action: action)
    }

    /// PathChanged인지 확인하는 헬퍼
    public var isPathChanged: Bool {
        if case .pathChanged = self { return true }
        return false
    }

    /// PathChanged의 경로를 추출하는 헬퍼
    public var pathChangeRoute: [UUID]? {
        guard case let .pathChanged(path) = self else { return nil }
        return path
    }
}

// MARK: - 🚀 Enhanced RouteStack with Child Reducer Auto-Connection

extension FlowAction {
    /// 편리한 case path 구문을 위한 static property
    public static var routeAction: AnyCasePath<FlowAction<Screen>, (UUID, Screen.Action)> {
        AnyCasePath(
            embed: FlowAction.routeAction,
            extract: { flowAction in
                guard case let .routeAction(id, action) = flowAction else { return nil }
                return (id, action)
            }
        )
    }
}
