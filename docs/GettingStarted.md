# Getting Started

이 문서는 TCAFlow를 iOS SwiftUI 앱에서 사용하는 기본 흐름을 설명합니다.

## 1. Package 추가

`Package.swift`를 사용하는 앱이면 dependency에 `TCAFlow`를 추가합니다.

```swift
dependencies: [
  .package(url: "git@github.com:Roy-wonji/TCAFlow.git", from: "1.0.0")
]
```

target dependency에도 추가합니다.

```swift
.target(
  name: "App",
  dependencies: [
    "TCAFlow",
    .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
  ]
)
```

로컬 개발 중이면 example처럼 local package로 연결할 수 있습니다.

```swift
.local(path: "../..")
```

## 2. 화면 Feature 작성

각 화면은 일반적인 TCA feature로 작성합니다.

```swift
import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature: Sendable {
  @ObservableState
  struct State: Equatable {}

  enum Action {
    case detailButtonTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct HomeView: View {
  @SwiftUI.Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    Button("Open Detail") {
      self.store.send(.detailButtonTapped)
    }
  }
}
```

## 3. Coordinator 작성

`@FlowCoordinator`는 nested `Screen` enum을 읽어서 `AppScreen`, `State`, `Action`을 생성합니다.

```swift
import ComposableArchitecture
import TCAFlow

@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.element(.element(_, .home(.detailButtonTapped)))):
        state.routes.push(.detail(DetailFeature.State()))
        return .none

      case .route(.element(.element(_, .detail(.closeButtonTapped)))):
        _ = state.routes.pop()
        return .none

      case .route:
        return .none
      }
    }
  }
}
```

`Screen`의 첫 번째 case가 기본 root route가 됩니다. 위 예제에서는 `home`이 root입니다.

`navigation`의 기본값은 `true`입니다. root를 `NavigationStack` 없이 렌더링하려면 `false`를 넘깁니다.

```swift
@FlowCoordinator(navigation: false)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
  }
}
```

직접 route stack을 작성하는 경우에는 root route의 네비게이션 컨테이너 포함 여부를 선택할 수 있습니다.

```swift
var routes: RouteStack<AppScreen.State> = [
  .root(.home(HomeFeature.State()), embedInNavigationView: true)
]
```

`embedInNavigationView: false`를 쓰면 `TCARouter`가 `NavigationStack` 없이 현재 화면만 렌더링합니다.

## 4. SwiftUI Router 연결

`TCARouter`에는 `RouteStack`으로 scope한 store를 넘깁니다.

```swift
struct AppCoordinatorView: View {
  @SwiftUI.Bindable var store: StoreOf<AppCoordinator>

  var body: some View {
    TCARouter(
      self.store.scope(state: \.routes, action: \.route)
    ) { screen in
      switch screen.case {
      case .home(let store):
        HomeView(store: store)
          .navigationTitle("Home")

      case .detail(let store):
        DetailView(store: store)
          .navigationTitle("Detail")
      }
    }
  }
}
```

`TCARouter` 내부는 iOS 16을 지원하기 위해 SwiftUI `@Bindable`을 사용하지 않습니다. 앱의 view에서는 iOS 17+ target이면 `@SwiftUI.Bindable var store` 패턴을 그대로 사용할 수 있습니다.

## 5. App 진입점

```swift
@main
struct ExampleApp: App {
  var body: some Scene {
    WindowGroup {
      AppCoordinatorView(
        store: Store(
          initialState: AppCoordinator.State(),
          reducer: { AppCoordinator() }
        )
      )
    }
  }
}
```
