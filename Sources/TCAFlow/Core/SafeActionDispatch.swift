import ComposableArchitecture
import CasePaths
import Foundation

// MARK: - SafeActionDispatch

/// ifCaseLet 오류를 방지하기 위한 안전한 action dispatch 기능
public struct SafeActionDispatch {

    /// Effect ID를 이용한 안전한 effect 취소
    public static func cancelEffects<ID: Hashable>(
        withIDs ids: [ID]
    ) -> Effect<Never> {
        .merge(
            ids.map { Effect.cancel(id: $0) }
        )
    }

    /// State 변경 시 관련된 모든 effect를 취소하는 헬퍼
    public static func cancelAllEffectsOnStateChange<ID: Hashable>(
        effectIDs: [ID]
    ) -> Effect<Never> {
        cancelEffects(withIDs: effectIDs)
    }
}

// MARK: - StateTransitionGuard

/// State 전환 시 안전성을 보장하는 가드
public struct StateTransitionGuard {

    /// State 전환 전 실행할 정리 작업
    public static func prepareTransition<State, Action>(
        from currentState: State,
        to newState: State,
        cancellingEffects effectIDs: [AnyHashable] = []
    ) -> Effect<Action> {
        // Effect 취소
        let cancelEffect = Effect<Action>.merge(
            effectIDs.map { Effect<Action>.cancel(id: $0) }
        )

        return cancelEffect
    }
}

// MARK: - Effect + SafeDispatch

extension Effect {

    /// Effect에 고유 ID를 부여하여 추후 취소 가능하게 만드는 헬퍼
    public func cancellable<ID: Hashable & Sendable>(
        id: ID,
        cancelInFlight: Bool = false
    ) -> Effect<Action> {
        self.cancellable(id: id, cancelInFlight: cancelInFlight)
    }

    /// State 체크와 함께 안전하게 action을 dispatch하는 헬퍼
    public static func safeDispatch<State>(
        _ action: Action,
        when stateValidator: @escaping @Sendable (State) -> Bool
    ) -> Effect<Action> where Action: Sendable {
        Effect.run { send in
            // Note: 실제 state 접근은 store에서 이루어져야 함
            // 이 메서드는 패턴 제공용
            await send(action)
        }
    }
}

// MARK: - Reducer + SafeTransition

extension Reducer {

    /// State 전환 시 effect를 안전하게 취소하는 reducer 조합
    public func safeStateTransition<EffectID: Hashable & Sendable>(
        cancellingEffects effectIDs: @escaping @Sendable (State) -> [EffectID]
    ) -> some Reducer<State, Action> {
        Reduce { state, action in
            let effectsToCancel = effectIDs(state)
            let effects = self.reduce(into: &state, action: action)

            let cancelEffects = Effect<Action>.merge(
                effectsToCancel.map { Effect<Action>.cancel(id: $0) }
            )

            return .merge(cancelEffects, effects)
        }
    }
}

// MARK: - Debugging Helpers

#if DEBUG
/// ifCaseLet 오류 디버깅을 위한 헬퍼
public enum IfCaseLetDebugger {

    /// State와 Action 불일치를 로깅하는 헬퍼
    public static func logMismatch<State, Action>(
        expectedState: String,
        actualState: State,
        action: Action,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        fputs("""
        [TCAFlow] IfCaseLet State Mismatch Detected!
        Expected State: \(expectedState)
        Actual State: \(actualState)
        Action: \(action)
        Location: \(file):\(line)

        """, stderr)
    }

    /// Effect 취소를 로깅하는 헬퍼
    public static func logEffectCancellation<ID: Hashable>(
        effectIDs: [ID],
        reason: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        fputs("""
        [TCAFlow] Effect Cancellation
        Effect IDs: \(effectIDs)
        Reason: \(reason)
        Location: \(file):\(line)

        """, stderr)
    }
}
#endif

// MARK: - Action Queue

/// Action을 안전하게 대기열에 넣고 적절한 시점에 처리하는 헬퍼
public actor ActionQueue<Action> {
    private var pendingActions: [Action] = []
    private var isProcessing = false

    public init() {}

    /// Action을 큐에 추가
    public func enqueue(_ action: Action) {
        pendingActions.append(action)
    }

    /// 큐의 모든 action을 반환하고 큐를 비움
    public func dequeueAll() -> [Action] {
        let actions = pendingActions
        pendingActions = []
        return actions
    }

    /// 큐를 비움
    public func clear() {
        pendingActions = []
    }

    /// 큐가 비어있는지 확인
    public var isEmpty: Bool {
        pendingActions.isEmpty
    }
}