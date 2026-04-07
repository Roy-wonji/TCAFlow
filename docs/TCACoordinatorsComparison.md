# TCACoordinators Comparison

TCAFlow는 TCACoordinators와 같은 coordinator-style navigation 문제를 다룹니다. 차이는 API 방향입니다. TCAFlow는 TCA 1.25+의 observation, key-path scoping, macro 기반 boilerplate 제거에 맞춰 설계되어 있습니다.

## 핵심 차이

| 항목 | TCACoordinators | TCAFlow |
| --- | --- | --- |
| 화면 state 제약 | hashable route state 패턴이 부담될 수 있음 | screen state는 `Equatable`만 요구 |
| Coordinator 선언 | screen enum, route state, action wiring을 직접 관리 | `@FlowCoordinator`가 `AppScreen`, `State`, `Action` 생성 |
| Root navigation 옵션 | route 설정에서 직접 처리 | `@FlowCoordinator(navigation: true/false)`로 선택 |
| Router view | TCACoordinators router API 사용 | `TCARouter(self.store.scope(state: \.routes, action: \.route))` |
| TCA API 방향 | 기존 coordinator 패턴 | `@ObservableState`, `@SwiftUI.Bindable`, key-path scoping 기준 |
| 화면 push/pop | route stack mutation | `state.routes.push`, `pop`, `popToRoot`, `goTo`, `goBackTo` |

## TCAFlow가 줄이는 코드

TCAFlow에서는 coordinator에 nested `Screen` enum만 선언하면 macro가 routing boilerplate를 생성합니다.

```swift
@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
    case settings(SettingsFeature)
  }
}
```

macro는 개념적으로 아래 멤버들을 생성합니다.

```swift
enum AppScreen { ... }

@ObservableState
struct State: Equatable {
  var routes: RouteStack<AppScreen.State>
}

enum Action {
  case route(FlowActionOf<AppScreen>)
}
```

## Hashable 대신 Equatable

TCAFlow의 route는 `UUID`로 식별되고, screen state는 `Equatable`만 요구합니다.

```swift
@ObservableState
struct MapFeature.State: Equatable {
  var coordinate: Coordinate
}
```

이런 식으로 `Hashable` conformance가 애매한 값을 screen state에 넣는 경우에 부담이 줄어듭니다.

## Router 연결

TCAFlow는 route stack store를 `TCARouter`에 넘깁니다.

```swift
TCARouter(
  self.store.scope(state: \.routes, action: \.route)
) { screen in
  switch screen.case {
  case .home(let store):
    HomeView(store: store)

  case .detail(let store):
    DetailView(store: store)
  }
}
```

## NavigationStack 포함 여부

root가 `NavigationStack` 안에서 렌더링될지 macro argument로 선택할 수 있습니다.

```swift
@FlowCoordinator(navigation: true)
```

```swift
@FlowCoordinator(navigation: false)
```

`true`가 기본값입니다.

