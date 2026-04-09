# TCAFlow

TCAFlow는 TCA(The Composable Architecture)용 coordinator-style navigation helper입니다.

TCACoordinators처럼 route stack을 reducer state에서 관리하지만, 화면 state에 `Hashable`을 강제하지 않고 `Equatable`만 요구합니다. 현재 API는 TCA 1.25+의 `@Reducer`, `@ObservableState`, key-path store scoping에 맞춰져 있습니다.

## Features

- `RouteStack` 기반 stack navigation
- `Hashable` 대신 `Equatable` screen state 지원
- `@FlowCoordinator` macro로 coordinator boilerplate 생성
- `TCARouter` SwiftUI view 제공
- iOS 16+ `NavigationStack` 기반 router
- `@SwiftUI.Bindable var store`를 쓰는 modern TCA example 포함

## TCACoordinators와 차이점

| 항목 | TCACoordinators | TCAFlow |
| --- | --- | --- |
| 화면 state 제약 | 보통 hashable route state 중심 | `Equatable`만 요구 |
| Coordinator 선언 | screen enum, route state, action 연결을 직접 작성 | `@FlowCoordinator`가 `AppScreen` 또는 `HomeScreen` 같은 screen enum과 `State`, `Action` 생성 |
| Root navigation 옵션 | route 설정에서 직접 처리 | `@FlowCoordinator(navigation: true/false)`로 선택 |
| Router 연결 | 라이브러리 전용 router action/store 패턴 | `TCARouter(self.store.scope(state: \.routes, action: \.route))` |
| TCA 버전 방향 | 기존 coordinator 패턴 | TCA 1.25+ `@ObservableState`, key-path scoping 기준 |
| 화면 state 타입 | `Hashable`이 부담될 수 있음 | `CLLocationCoordinate2D`, class reference 등 `Equatable`로 감싼 state 사용 가능 |

TCAFlow는 TCACoordinators의 "coordinator가 route stack을 소유한다"는 아이디어를 유지하면서, 최신 TCA API와 macro 기반 boilerplate 제거에 초점을 둡니다.

```swift
// TCACoordinators 스타일에서는 screen/router 보일러플레이트를 더 직접 관리하는 편입니다.

// TCAFlow
@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
  }
}
```

## Requirements

- Swift 6.0+
- TCA 1.25.5+
- iOS 16.0+
- macOS 13.0+
- watchOS 9.0+
- tvOS 16.0+

## Installation

Swift Package Manager에 package를 추가합니다.

```swift
dependencies: [
  .package(url: "git@github.com:Roy-wonji/TCAFlow.git", from: "1.0.0")
]
```

target dependency에 `TCAFlow`를 추가합니다.

```swift
.target(
  name: "App",
  dependencies: [
    "TCAFlow"
  ]
)
```

로컬 개발 중이면 example project처럼 local package로 연결할 수 있습니다.

```swift
.local(path: "../..")
```

## Quick Start

화면 feature는 일반 TCA feature로 작성합니다.

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

coordinator는 `@FlowCoordinator`와 nested `Screen` enum으로 작성합니다.

```swift
import ComposableArchitecture
import SwiftUI
import TCAFlow

@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case profile(ProfileCoordinator)
    case detail(DetailFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, .home(.profileButtonTapped)))):
        state.routes.push(.profile(.init()))
        return .none

      case .route(.routeAction(_, .home(.detailButtonTapped)))):
        state.routes.push(.detail(DetailFeature.State()))
        return .none

      case .route(.routeAction(_, .detail(.closeButtonTapped)))):
        _ = state.routes.pop()
        return .none

      case .route:
        return .none
      }
    }
  }
}
```

SwiftUI에서는 coordinator store를 `RouteStack`으로 scope해서 `TCARouter`에 넘깁니다.

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

앱 진입점에서는 일반 TCA `Store`를 생성합니다.

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

## Navigation API

`navigation`은 기본값이 `true`입니다. root를 `NavigationStack` 없이 렌더링하려면 `false`를 넘깁니다.

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

직접 `State`를 작성하는 경우에는 `Route.root`에서도 같은 옵션을 줄 수 있습니다.

```swift
var routes: RouteStack<AppScreen.State> = [
  .root(.home(HomeFeature.State()), embedInNavigationView: false)
]
```

`@FlowCoordinator`가 생성한 `State`에는 `routes`가 들어 있습니다.

```swift
state.routes.push(.profile(.init()))
state.routes.push(.detail(DetailFeature.State()))
_ = state.routes.pop()
state.routes.popToRoot()
state.routes.replace(with: .settings(SettingsFeature.State()))
state.routes.goTo(.settings(SettingsFeature.State()))
state.routes.goBackTo(.home(HomeFeature.State()))
```

`embedInNavigationView`가 `true`면 `TCARouter`가 root를 `NavigationStack` 안에 렌더링합니다. `false`면 네비게이션 컨테이너 없이 현재 route view만 렌더링합니다.

`goTo`는 같은 enum case가 이미 stack에 있으면 그 route까지 pop하고, 없으면 새 route를 push합니다.

`goBackTo`는 target screen과 같은 enum case가 나올 때까지 pop합니다.

## FlowCoordinator Macro

`@FlowCoordinator`는 아래 멤버를 생성합니다.

- `<CoordinatorName>Screen`
- `<CoordinatorName>Screen.State`
- `<CoordinatorName>Screen.Action`
- `<CoordinatorName>Screen.CaseScope`
- `State`
- `Action`

작성자는 `Screen` enum과 coordinator reducer logic만 작성하면 됩니다.

```swift
@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case single(SingleViewFeature)
    case counter(CounterFeature)
    case summary(SummaryFeature)
    case settings(SettingsFeature)
  }
}
```

`AppCoordinator`면 `AppScreen`, `HomeCoordinator`면 `HomeScreen`이 생성됩니다.

첫 번째 `Screen` case가 root route가 됩니다.

## Nested Coordinator

다른 coordinator를 screen case로 넣을 수 있습니다.

```swift
@FlowCoordinator(navigation: true)
@Reducer
struct HomeCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case profile(ProfileCoordinator)
  }
}
```

child coordinator가 parent `NavigationStack` 흐름에 이어서 push/pop 되어야 하면 child는 `navigation: false`가 맞습니다.

```swift
@FlowCoordinator(navigation: false)
@Reducer
struct ProfileCoordinator: Sendable {
  enum Screen {
    case profileHome(ProfileHomeFeature)
    case profileDetail(ProfileDetailFeature)
  }
}
```

child가 자기 own `NavigationStack`을 가져야 하면 `navigation: true`도 그대로 동작합니다. example 앱에 이 케이스가 포함되어 있습니다.

## Example App

example iOS 앱은 아래 경로에 있습니다.

```text
Example/TCAFlowExamples/TCAFlowExamples.xcodeproj
```

터미널 빌드:

```sh
xcodebuild \
  -project Example/TCAFlowExamples/TCAFlowExamples.xcodeproj \
  -scheme TCAFlowExamples \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/TCAFlowExamplesDerivedData \
  build
```

example은 다음 흐름을 포함합니다.

- `Home` -> `SingleView`: 화면 하나만 push/pop
- `Home` -> `Counter` -> `Summary`: stack flow
- `Summary` -> `Settings`: target screen 이동
- `Counter`/`Summary` -> root: `popToRoot`

## Documentation

자세한 문서는 `docs/` 아래에 있습니다.

- [docs/README.md](docs/README.md)
- [docs/GettingStarted.md](docs/GettingStarted.md)
- [docs/APIReference.md](docs/APIReference.md)
- [docs/TCACoordinatorsComparison.md](docs/TCACoordinatorsComparison.md)
- [docs/FlowCoordinatorMacro.md](docs/FlowCoordinatorMacro.md)
- [docs/ExampleApp.md](docs/ExampleApp.md)

## Notes

`TCARouter`는 library target에서 iOS 16을 지원하기 위해 SwiftUI `@Bindable`을 내부에서 사용하지 않습니다.

앱 view에서는 iOS 17+ target이면 아래처럼 SwiftUI 기본 `Bindable`을 사용할 수 있습니다.

```swift
struct SummaryView: View {
  @SwiftUI.Bindable var store: StoreOf<SummaryFeature>
}
```
