# TCAFlow ifCaseLet 오류 해결 가이드

## 문제 상황

다음과 같은 오류가 발생하는 경우가 있습니다:

```
An "ifCaseLet" at "TimeSpot/AppReducer.swift:104" received a child action when child state was set to a different case.

Action:
  AppReducer.Action.scope(
    .home(...)
  )
State:
  AppReducer.State.auth(...)
```

이는 TCA에서 **state와 action이 불일치**할 때 발생하는 오류입니다. 예를 들어:
- 현재 state는 `.auth`인데
- action은 `.home`용 action이 들어오는 상황

## 원인

1. **Effect 취소 미흡**: 이전 state에서 시작된 effect들이 state 변경 후에도 계속 실행되어 잘못된 action을 보냄
2. **비동기 작업 타이밍**: 네트워크 요청이나 타이머 등이 state 변경 후에 완료되어 action을 전송
3. **NavigationStack 구조 문제**: NavigationDestination이 잘못된 위치에 배치됨

## TCAFlow 해결 방법

### 1. SafeActionDispatch 사용

```swift
import TCAFlow

// Effect 취소를 위한 ID 정의
let authEffectID = RoutingEffectID.authFlow("login")
let homeEffectID = RoutingEffectID.homeFlow("main")

// State 변경 시 관련 Effect 취소
return .merge(
    Effect.cancel(id: authEffectID),
    .send(.transition(.home))
)
```

### 2. SafeNavigationReducer 사용

```swift
let appReducer = SafeNavigationReducer(
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
```

### 3. IfCaseLetSafeReducer 사용

```swift
Reduce { state, action in
    // 기본 로직
}
.ifCaseLet(\.auth, action: \.auth, then: {
    IfCaseLetSafeReducer(
        state: \.auth,
        action: \.auth,
        childReducer: AuthReducer(),
        onStateChange: { previous, current in
            // State 변경 시 취소할 effect IDs
            return [RoutingEffectID.authFlow()]
        }
    )
})
```

### 4. 안전한 Effect 작성

```swift
// ❌ 위험한 방식
case .login:
    return .run { send in
        let result = await authClient.login()
        await send(.loginResponse(result))
    }

// ✅ 안전한 방식
case .login:
    return .run { send in
        let result = await authClient.login()
        await send(.loginResponse(result))
    }
    .cancellable(id: RoutingEffectID.authFlow("login"))
```

### 5. State 전환 시 Effect 취소

```swift
case .logout:
    return .merge(
        // 모든 인증 관련 effect 취소
        Effect.cancel(id: RoutingEffectID.authFlow()),
        Effect.cancel(id: RoutingEffectID.navigationTransition("auth", to: "home")),
        
        // 새로운 state로 전환
        .send(.transition(.auth(.login)))
    )
```

## 실제 사용 예시

### AppReducer에서의 적용

```swift
@Reducer
struct AppReducer {
    enum State {
        case auth(AuthCoordinator.State)
        case home(HomeCoordinator.State)
    }
    
    enum Action {
        case auth(AuthCoordinator.Action)
        case home(HomeCoordinator.Action)
        case transition(State)
    }
    
    var body: some Reducer<State, Action> {
        SafeNavigationReducer(
            baseReducer: Reduce { state, action in
                switch action {
                case let .transition(newState):
                    // 현재 state에서 실행 중인 effects 취소
                    let effectsToCancel = currentEffects(for: state)
                    state = newState
                    return SafeActionDispatch.cancelEffects(withIDs: effectsToCancel)
                    
                default:
                    return .none
                }
            }
            .ifCaseLet(\.auth, action: \.auth) {
                AuthCoordinator()
            }
            .ifCaseLet(\.home, action: \.home) {
                HomeCoordinator()
            },
            stateValidators: [
                "auth": { if case .auth = $0 { return true }; return false },
                "home": { if case .home = $0 { return true }; return false }
            ]
        )
    }
    
    private func currentEffects(for state: State) -> [String] {
        switch state {
        case .auth:
            return [
                RoutingEffectID.authFlow(),
                RoutingEffectID.viewLifecycle("auth", lifecycle: "onAppear")
            ]
        case .home:
            return [
                RoutingEffectID.homeFlow(),
                RoutingEffectID.viewLifecycle("home", lifecycle: "onAppear")
            ]
        }
    }
}
```

### Store에서의 안전한 Action 전송

```swift
// Store 사용 시
store.safeSend(.someAction, validateState: "auth")

// 또는 effects 직접 취소
store.cancelEffects([
    RoutingEffectID.authFlow(),
    RoutingEffectID.homeFlow()
])
```

## 디버깅 도구

### Debug 모드에서 로깅

```swift
#if DEBUG
IfCaseLetDebugger.logMismatch(
    expectedState: "home",
    actualState: state,
    action: action
)

IfCaseLetDebugger.logEffectCancellation(
    effectIDs: [RoutingEffectID.authFlow()],
    reason: "State transition from auth to home"
)
#endif
```

### Action Queue 사용

```swift
@MainActor
class ViewModel: ObservableObject {
    let actionQueue = ActionQueue<Action>()
    
    func handleStateTransition() async {
        // 현재 진행 중인 actions 대기열에 추가
        await actionQueue.enqueue(.someAction)
        
        // State 변경 후 대기열의 actions 처리
        let pendingActions = await actionQueue.dequeueAll()
        for action in pendingActions {
            store.send(action)
        }
    }
}
```

## 베스트 프랙티스

1. **Effect ID 체계화**: 각 기능별로 고유한 effect ID 사용
2. **State 변경 시 정리**: 항상 이전 state의 effects를 취소
3. **SwitchStore 활용**: SwiftUI에서 state별로 안전한 뷰 분기
4. **NavigationStack 최상위 배치**: 중첩된 NavigationStack 피하기
5. **Effect 생명주기 관리**: 장기 실행 effects는 반드시 cancellable로 설정

## 결론

TCAFlow의 안전 장치들을 사용하여 ifCaseLet 오류를 방지하고, 더 안정적인 TCA 애플리케이션을 구축할 수 있습니다. 특히 State 전환이 빈번한 애플리케이션에서는 반드시 effect 취소와 안전한 action dispatch를 고려해야 합니다.