# @FlowCoordinator Macro

`@FlowCoordinator` 매크로로 coordinator 보일러플레이트를 자동 생성하는 방법을 알아봅니다.

## Overview

Coordinator를 수동으로 작성하면 반복되는 코드가 많습니다:
- `@ObservableState struct State` + routes 배열 + init
- `@CasePathable enum Action` + router case
- `var body` + `.forEachRoute`

`@FlowCoordinator` 매크로는 이 보일러플레이트를 자동 생성합니다.

## 기본 사용법

```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {}

extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case detail(DetailFeature)
    }
}

extension AppCoordinator.Screen.State: Equatable {}

extension AppCoordinator {
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .router(.routeAction(_, .home(.detailTapped))):
            state.routes.push(.detail(.init()))
            return .none
        default:
            return .none
        }
    }
}
```

### 매크로가 자동 생성하는 코드

```swift
// 이 코드가 자동 생성됩니다:
@ObservableState
struct State: Equatable {
    var routes: [Route<Screen.State>]
}

@CasePathable
enum Action {
    case router(IndexedRouterActionOf<Screen>)
}

var body: some Reducer<State, Action> {
    Reduce { state, action in
        return self.handleRoute(state: &state, action: action)
    }
    .forEachRoute(\.routes, action: \.router)
}

extension AppCoordinator: Reducer {}
```

## 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|---------|------|-------|------|
| `screen` | `String?` | `nil` | Screen enum 이름. extension으로 분리할 때 필수 |
| `navigation` | `Bool` | `true` | root route의 `embedInNavigationView` 값 |

### screen 파라미터

Screen enum이 struct 안에 있으면 생략 가능:

```swift
// ✅ screen enum이 struct 안에 있으면 생략 가능
@FlowCoordinator(navigation: true)
struct AppCoordinator {
    @Reducer
    enum Screen { ... }
}

// ✅ screen enum이 extension에 있으면 이름 지정 필수
@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {}

extension AppCoordinator {
    @Reducer
    enum Screen { ... }
}
```

> Important: Swift 매크로는 자기가 붙은 선언의 멤버만 볼 수 있습니다. Screen enum이 다른 extension에 있으면 `screen:` 파라미터로 이름을 알려줘야 합니다.

## 커스텀 Action

추가 Action이 필요하면 `Action`을 직접 작성합니다. 매크로가 감지하여 Action 생성을 건너뜁니다.

```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct NestedCoordinator {
    // Action 직접 작성 → 매크로가 건너뜀
    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<Screen>)
        case backToMain  // 추가 action
    }
}
```

> Note: `case router(IndexedRouterActionOf<Screen>)`은 반드시 포함해야 합니다.

## body 직접 작성

`body`를 직접 작성하면 매크로가 body 생성을 건너뜁니다. 이 경우 `.forEachRoute`를 직접 추가해야 합니다.

```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct NestedCoordinator {
    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<Screen>)
        case completed
    }

    // body 직접 작성 → .forEachRoute 수동
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .router(.routeAction(_, .step1(.nextTapped))):
                state.routes.push(.step2(.init()))
                return .none
            case .completed:
                return .none
            default:
                return .none
            }
        }
        .forEachRoute(\.routes, action: \.router)
    }
}
```

## 건너뛰기 규칙

매크로는 이미 존재하는 멤버를 건너뜁니다:

| 멤버 | 존재 여부 | 매크로 동작 |
|-----|----------|-----------|
| `struct State` | 없음 | 자동 생성 |
| `struct State` | 있음 | 건너뜀 |
| `enum Action` | 없음 | 자동 생성 |
| `enum Action` | 있음 | 건너뜀 |
| `var body` | 없음 | 자동 생성 (handleRoute + forEachRoute) |
| `var body` | 있음 | 건너뜀 |

## @Reducer와의 관계

`@FlowCoordinator`는 `@Reducer`와 **같이 사용할 수 없습니다** (State/Action 중복 생성). 대신 `@FlowCoordinator`가 `Reducer` conformance를 자동으로 추가합니다.

```swift
// ❌ 충돌
@Reducer
@FlowCoordinator(screen: "Screen")
struct AppCoordinator {}

// ✅ 정상
@FlowCoordinator(screen: "Screen")
struct AppCoordinator {}

// ✅ Screen enum에는 @Reducer 사용
extension AppCoordinator {
    @Reducer
    enum Screen { ... }
}
```
