# API Reference

이 문서는 TCAFlow public API의 역할과 사용 방식을 요약합니다.

## Route

`Route`는 route stack 안의 개별 화면을 표현합니다.

```swift
public enum Route<Screen> {
  case root(Screen, embedInNavigationView: Bool = true)
  case push(Screen)
  case sheet(Screen, embedInNavigationView: Bool = false)
  case cover(Screen, embedInNavigationView: Bool = false)
}
```

화면 state에는 `Hashable` 제약이 없습니다. `embedInNavigationView: true`이면 부모 TCAFlow navigation을 상속하거나, 부모가 없을 때 UIKitNavigation의 독립적인 `NavigationStackController`를 생성합니다.

```swift
let route = Route.root(.home(HomeFeature.State()), embedInNavigationView: true)
```

네비게이션 컨테이너 없이 화면만 렌더링하려면 `embedInNavigationView: false`를 사용합니다.

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
state.routes.pop()
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
case .route(.routeAction(let id, let screenAction)):
  switch screenAction {
  case .home(.detailButtonTapped):
    state.routes.push(.detail(DetailFeature.State()))

  case .detail(.closeButtonTapped):
    state.routes.pop()
  }
  return .none
```

`pathChanged`는 SwiftUI back 동작과 route stack을 동기화할 때 사용합니다.

```swift
case .route(.pathChanged(let path)):
  let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
  while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
    state.routes.pop()
  }
  return .none
```

## TCARouter

`TCARouter`는 `RouteStack` store를 받아 현재 route의 screen store를 만들어 view builder로 넘깁니다.

```swift
TCARouter(
  self.store.scope(\.routes, action: \.route)
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
