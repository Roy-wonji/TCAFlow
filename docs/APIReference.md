# API Reference

이 문서는 TCAFlow public API의 역할과 사용 방식을 요약합니다.

## Route

`Route`는 route stack 안의 개별 화면을 표현합니다.

```swift
@ObservableState
public struct Route<State: Equatable>: Identifiable, Equatable, Hashable {
  public let id: UUID
  public var state: State
  public var embedInNavigationView: Bool
}
```

`Hashable` 구현은 `id` 기준입니다. 화면 state 자체는 `Equatable`만 요구합니다. `embedInNavigationView`는 root route가 `NavigationStack` 안에 렌더링될지 결정합니다.

```swift
let route = Route.root(.home(HomeFeature.State()), embedInNavigationView: true)
```

네비게이션 컨테이너 없이 화면만 렌더링하고 싶으면 `false`를 넘깁니다.

```swift
let route = Route.root(.home(HomeFeature.State()), embedInNavigationView: false)
```

## RouteStack

`RouteStack`은 route 배열을 관리하는 coordinator state입니다.

```swift
@ObservableState
public struct RouteStack<State: Equatable>: Equatable {
  public var routes: IdentifiedArrayOf<Route<State>>
}
```

`RouteStack`은 array literal을 지원합니다.

```swift
var routes: RouteStack<AppScreen.State> = [
  .root(.home(HomeFeature.State()), embedInNavigationView: true)
]
```

기본 navigation helper를 제공합니다.

```swift
state.routes.push(.detail(DetailFeature.State()))
_ = state.routes.pop()
state.routes.popToRoot()
state.routes.replace(with: .settings(SettingsFeature.State()))
state.routes.goTo(.settings(SettingsFeature.State()))
state.routes.goBackTo(.home(HomeFeature.State()))
```

`goTo`는 target screen과 같은 enum case가 이미 stack 안에 있으면 그 위치까지 pop하고, 없으면 새 route를 push합니다.

`goBackTo`는 target screen과 같은 enum case가 나올 때까지 pop합니다.

## FlowAction

`FlowAction`은 child screen action과 path 변경을 coordinator reducer로 전달합니다.

```swift
@CasePathable
public enum FlowAction<Action> {
  case element(IdentifiedAction<UUID, Action>)
  case pathChanged([UUID])
}
```

화면 action은 보통 coordinator reducer에서 이렇게 처리합니다.

```swift
case .route(.element(.element(let id, let screenAction))):
  switch screenAction {
  case .home(.detailButtonTapped):
    state.routes.push(.detail(DetailFeature.State()))

  case .detail(.closeButtonTapped):
    _ = state.routes.pop()
  }
  return .none
```

`pathChanged`는 SwiftUI back 동작과 route stack을 동기화할 때 사용합니다.

```swift
case .route(.pathChanged(let path)):
  let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
  while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
    _ = state.routes.pop()
  }
  return .none
```

## TCARouter

`TCARouter`는 `RouteStack` store를 받아 현재 route의 screen store를 만들어 view builder로 넘깁니다.

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

내부 구현은 iOS 16 호환을 위해 SwiftUI `@Bindable`을 쓰지 않습니다. TCA observation backport에 맞춰 `WithPerceptionTracking`으로 route stack 읽기를 추적합니다.

## Transition Helpers

`View` extension으로 간단한 transition helper가 제공됩니다.

```swift
HomeView(store: store)
  .slideTransition()

DetailView(store: store)
  .fadeTransition()

SettingsView(store: store)
  .bottomTransition()
```

제공되는 helper는 다음과 같습니다.

- `slideTransition()`
- `fadeTransition()`
- `scaleTransition()`
- `leadingTransition()`
- `bottomTransition()`
