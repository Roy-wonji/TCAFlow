import ComposableArchitecture
import CasePaths
import Foundation
import LogMacro

// MARK: - SafeRoutingEnvironment

/// 안전한 라우팅을 위한 환경 설정
public struct SafeRoutingEnvironment {
    /// Effect 취소를 위한 ID 생성기
    public static func routingEffectID<State: Hashable>(for state: State) -> String {
        "routing_\(String(describing: state))_\(state.hashValue)"
    }

    /// State별 Effect ID 컬렉션
    public static func effectIDs<State>(for state: State) -> [String] {
        // State type을 기반으로 관련된 effect ID들을 생성
        let baseID = String(describing: type(of: state))
        return [
            "\(baseID)_navigation",
            "\(baseID)_loading",
            "\(baseID)_network",
            "\(baseID)_animation"
        ]
    }
}

// MARK: - SafeCoordinatorReducer

/// ifCaseLet 오류를 방지하는 안전한 코디네이터 리듀서
public struct SafeCoordinatorReducer<ChildState, ChildAction>: Reducer {

    public typealias State = ChildState
    public typealias Action = ChildAction

    private let childReducer: any Reducer<ChildState, ChildAction>

    public init<R: Reducer<ChildState, ChildAction>>(childReducer: R) {
        self.childReducer = childReducer
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        // State 변경 전에 현재 state를 기록
        let previousState = state

        // Child reducer 실행
        let effects = childReducer.reduce(into: &state, action: action)

        // State가 변경된 경우 관련 effects 취소
        if String(describing: previousState) != String(describing: state) {
            let cancelEffects = SafeRoutingEnvironment.effectIDs(for: previousState)
                .map { Effect<Action>.cancel(id: $0) }

            return .merge([effects] + cancelEffects)
        }

        return effects
    }
}

// MARK: - IfCaseLetSafeReducer

/// ifCaseLet을 안전하게 처리하는 리듀서 래퍼
public struct IfCaseLetSafeReducer<ParentState, ParentAction, ChildState, ChildAction>: Reducer
where ChildState: Equatable {

    public typealias State = ParentState
    public typealias Action = ParentAction

    private let toChildState: WritableKeyPath<ParentState, ChildState?>
    private let toChildAction: AnyCasePath<ParentAction, ChildAction>
    private let childReducer: any Reducer<ChildState, ChildAction>
    private let onStateChange: ((ChildState?, ChildState?) -> [String])?

    public init<R: Reducer<ChildState, ChildAction>>(
        state: WritableKeyPath<ParentState, ChildState?>,
        action: CaseKeyPath<ParentAction, ChildAction>,
        childReducer: R,
        onStateChange: ((ChildState?, ChildState?) -> [String])? = nil
    ) {
        self.toChildState = state
        self.toChildAction = AnyCasePath(action)
        self.childReducer = childReducer
        self.onStateChange = onStateChange
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        guard let childAction = toChildAction.extract(from: action) else {
            return .none
        }

        guard var childState = state[keyPath: toChildState] else {
            #if DEBUG
            IfCaseLetDebugger.logMismatch(
                expectedState: String(describing: ChildState.self),
                actualState: state[keyPath: toChildState] as Any,
                action: action
            )
            #endif
            // Child state가 nil이면 action을 무시하고 빈 effect 반환
            return .none
        }

        let previousChildState = childState
        let childEffects = childReducer.reduce(into: &childState, action: childAction)

        // State 변경사항 적용
        state[keyPath: toChildState] = childState

        // State 변경 시 effect 취소
        if previousChildState != childState,
           let effectsToCancel = onStateChange?(previousChildState, childState) {
            let cancelEffects = effectsToCancel.map { Effect<Action>.cancel(id: $0) }
            return .merge([childEffects.map(toChildAction.embed)] + cancelEffects)
        }

        return childEffects.map(toChildAction.embed)
    }
}

// MARK: - SafeNavigationAction

/// 안전한 네비게이션을 위한 액션 래퍼
@CasePathable
public enum SafeNavigationAction<Action> {
    case safeDispatch(Action, stateValidator: String)
    case cancelEffects([String])
    case wrapped(Action)
}

extension SafeNavigationAction: Sendable where Action: Sendable {}
extension SafeNavigationAction: Equatable where Action: Equatable {}

// MARK: - SafeNavigationReducer

/// 안전한 네비게이션을 제공하는 리듀서
public struct SafeNavigationReducer<State, Action>: Reducer {
    private let baseReducer: any Reducer<State, Action>
    private let stateValidators: [String: (State) -> Bool]

    public init<R: Reducer<State, Action>>(
        baseReducer: R,
        stateValidators: [String: (State) -> Bool] = [:]
    ) {
        self.baseReducer = baseReducer
        self.stateValidators = stateValidators
    }

    public func reduce(into state: inout State, action: SafeNavigationAction<Action>) -> Effect<SafeNavigationAction<Action>> {
        switch action {
        case let .safeDispatch(wrappedAction, validatorKey):
            if let validator = stateValidators[validatorKey], !validator(state) {
                #if DEBUG
                #logError("🚫 [TCAFlow] SafeDispatch: Action ignored due to state validation failure")
                #logDebug("Action: \(wrappedAction)")
                #logDebug("Current State: \(state)")
                #endif
                return .none
            }
            fallthrough

        case let .wrapped(wrappedAction):
            return baseReducer.reduce(into: &state, action: wrappedAction)
                .map { .wrapped($0) }

        case let .cancelEffects(effectIDs):
            return .merge(effectIDs.map { Effect.cancel(id: $0) })
        }
    }
}

// MARK: - Effect + SafeNavigation

extension Effect {
    /// State 검증과 함께 안전하게 action을 전송
    public static func safeNavigationDispatch(
        _ action: Action,
        validateState stateKey: String
    ) -> Effect<SafeNavigationAction<Action>> {
        .send(.safeDispatch(action, stateValidator: stateKey))
    }

    /// Effects 취소
    public static func cancelNavigationEffects(
        _ effectIDs: [String]
    ) -> Effect<SafeNavigationAction<Action>> {
        .send(.cancelEffects(effectIDs))
    }
}

// MARK: - Store + SafeNavigation

extension Store {
    /// 안전한 네비게이션 액션 전송
    public func safeSend<WrappedAction>(
        _ action: WrappedAction,
        validateState stateKey: String = "default"
    ) where Action == SafeNavigationAction<WrappedAction> {
        send(.safeDispatch(action, stateValidator: stateKey))
    }

    /// Effects 취소
    public func cancelEffects<WrappedAction>(
        _ effectIDs: [String]
    ) where Action == SafeNavigationAction<WrappedAction> {
        send(.cancelEffects(effectIDs))
    }
}

// MARK: - Routing Effect IDs

/// 라우팅 관련 Effect ID 상수들
public enum RoutingEffectID {
    public static func authFlow(_ identifier: String = "") -> String {
        "auth_flow_\(identifier)"
    }

    public static func homeFlow(_ identifier: String = "") -> String {
        "home_flow_\(identifier)"
    }

    public static func staffFlow(_ identifier: String = "") -> String {
        "staff_flow_\(identifier)"
    }

    public static func navigationTransition(_ from: String, to: String) -> String {
        "navigation_\(from)_to_\(to)"
    }

    public static func viewLifecycle(_ screen: String, lifecycle: String) -> String {
        "lifecycle_\(screen)_\(lifecycle)"
    }
}

// MARK: - Usage Example (주석)

/*
 // 사용 예시:

 // 1. 기본 리듀서를 SafeNavigationReducer로 래핑
 let safeReducer = SafeNavigationReducer(
     baseReducer: AppReducer(),
     stateValidators: [
         "auth": { state in
             if case .auth = state { return true }
             return false
         },
         "home": { state in
             if case .home = state { return true }
             return false
         }
     ]
 )

 // 2. Store에서 안전한 액션 전송
 store.safeSend(.someAction, validateState: "auth")

 // 3. State 변경 시 effects 취소
 store.cancelEffects([
     RoutingEffectID.authFlow(),
     RoutingEffectID.navigationTransition("auth", to: "home")
 ])

 // 4. IfCaseLetSafeReducer 사용
 let ifCaseLetReducer = IfCaseLetSafeReducer(
     state: \.auth,
     action: \.auth,
     childReducer: AuthReducer(),
     onStateChange: { previous, current in
         // State가 변경되었을 때 취소할 effect IDs 반환
         return [RoutingEffectID.authFlow()]
     }
 )
 */