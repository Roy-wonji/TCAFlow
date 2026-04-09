# TCAFlow

TCAFlow는 TCA(The Composable Architecture)용 coordinator-style navigation helper입니다.

TCACoordinators와 완전히 동일한 API를 제공하지만 NavigationStack 기반으로 구현되었고, 화면 state에 `Hashable`을 강제하지 않습니다. TCACoordinators의 모든 기능을 지원하면서도 더 유연한 타입 제약을 가집니다.

## Features

- `RouteStack` 기반 stack navigation
- `Hashable` 대신 `Equatable` screen state 지원
- `@FlowCoordinator` macro로 coordinator boilerplate 생성
- `TCARouter` SwiftUI view 제공
- iOS 16+ `NavigationStack` 기반 router
- `@SwiftUI.Bindable var store`를 쓰는 modern TCA example 포함
- **매크로 없이도 사용 가능한 RouteStack 유틸리티** 🆕
- **FlowAction 헬퍼로 깔끔한 라우트 액션 처리** 🆕

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

coordinator는 `@Reducer` 매크로로 Screen enum을 정의합니다.

```swift
import ComposableArchitecture
import SwiftUI
import TCAFlow

@Reducer
enum Screen {
  case home(HomeFeature)
  case detail(DetailFeature)
  case profile(ProfileCoordinator)
}

struct AppCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {
    var routes: [Route<Screen.State>] = [.push(.home(HomeFeature.State()))]
  }

  @CasePathable
  enum Action {
    case router(IndexedRouterAction<Screen.State, Screen.Action>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .router(.routeAction(_, .home(.detailButtonTapped))):
        state.routes.push(.detail(DetailFeature.State()))
        return .none

      case let .router(.routeAction(_, .detail(.closeButtonTapped))):
        state.routes.pop()
        return .none

      case .router:
        return .none
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }
}
```

SwiftUI에서는 TCACoordinators와 완전히 동일한 방식으로 사용합니다.

```swift
struct AppCoordinatorView: View {
  @Bindable private var store: StoreOf<AppCoordinator>

  init(store: StoreOf<AppCoordinator>) {
    self.store = store
  }

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screens in
      switch screens.case {
      case .home(let homeStore):
        HomeView(store: homeStore)
          .navigationTitle("Home")

      case .detail(let detailStore):
        DetailView(store: detailStore)
          .navigationTitle("Detail")

      case .profile(let profileStore):
        ProfileCoordinatorView(store: profileStore)
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
        store: Store(initialState: AppCoordinator.State()) {
          AppCoordinator()
        }
      )
    }
  }
}
```

## Navigation API

Route는 3가지 방식으로 화면을 표시할 수 있습니다.

```swift
// Push navigation (NavigationStack)
state.routes.push(.detail(DetailFeature.State()))

// Sheet presentation
state.routes.presentSheet(.settings(SettingsFeature.State()), withNavigation: true)

// Full screen cover
state.routes.presentCover(.onboarding(OnboardingFeature.State()), withNavigation: false)
```

기본 네비게이션 메서드들:

```swift
state.routes.push(.profile(ProfileFeature.State()))
state.routes.pop()
state.routes.popToRoot()
state.routes.dismiss() // 최상위 모달 닫기
state.routes.goBackTo(SomeFeature.self) // 특정 타입으로 이동
```

`embedInNavigationView`가 `true`면 `TCARouter`가 root를 `NavigationStack` 안에 렌더링합니다. `false`면 네비게이션 컨테이너 없이 현재 route view만 렌더링합니다.

`goTo`는 같은 enum case가 이미 stack에 있으면 그 route까지 pop하고, 없으면 새 route를 push합니다.

`goBackTo`는 target screen과 같은 enum case가 나올 때까지 pop합니다.

## @Reducer 매크로

TCACoordinators와 동일하게 `@Reducer` 매크로를 사용해서 Screen enum을 정의합니다.

```swift
@Reducer
enum Screen {
  case home(HomeFeature)
  case detail(DetailFeature)
  case settings(SettingsFeature)
}
```

매크로가 자동으로 다음을 생성합니다:

- `Screen.State` enum
- `Screen.Action` enum  
- `Screen.body` reducer implementation
- `Screen.scope(_:)` method for CaseScope

### forEachRoute

RouterAction을 자동으로 처리하는 확장입니다.

```swift
struct AppCoordinator: Reducer {
  // State, Action 정의...

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .router(.routeAction(_, screenAction)):
        // 각 스크린 액션 처리
        return handleScreenAction(screenAction, state: &state)
      case .router(.updateRoutes):
        return .none // 자동 처리됨
      }
    }
    .forEachRoute(\.routes, action: \.router) // 🎯 RouterAction 자동 처리!
  }
}
```

### TCACoordinators와의 차이점

| 항목 | TCACoordinators | TCAFlow |
| --- | --- | --- |
| Screen State 제약 | Hashable 강제 | Equatable만 요구 |
| Route 방식 | push only | push/sheet/cover 지원 |
| Navigation 구현 | FlowStacks 기반 | NavigationStack 직접 사용 |
| API 호환성 | TCACoordinators API | 100% 호환 |

## Screen Reducer Macro

`@Reducer` 매크로는 Screen enum에 다음을 생성합니다:

- `State` enum (각 케이스의 State 포함)
- `Action` enum (각 케이스의 Action 포함)  
- `body` reducer implementation
- `scope(_:)` method for pattern matching

```swift
@Reducer
enum AppScreen {
  case home(HomeFeature)
  case detail(DetailFeature)
  case settings(SettingsFeature)
}

// 생성된 코드 예시:
// enum State: CaseReducerState {
//   case home(HomeFeature.State)
//   case detail(DetailFeature.State)
//   case settings(SettingsFeature.State)
// }
//
// enum Action {
//   case home(HomeFeature.Action)
//   case detail(DetailFeature.Action)
//   case settings(SettingsFeature.Action)
// }
```

TCACoordinators와 동일한 방식으로 사용할 수 있습니다.

## Nested Coordinator

다른 coordinator를 screen case로 넣을 수 있습니다.

```swift
@Reducer
enum HomeScreen {
  case home(HomeFeature)
  case profile(ProfileCoordinator)
}

struct HomeCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {
    var routes: [Route<HomeScreen.State>] = [.push(.home(HomeFeature.State()))]
  }
  
  @CasePathable
  enum Action {
    case router(IndexedRouterAction<HomeScreen.State, HomeScreen.Action>)
  }
  
  var body: some ReducerOf<Self> {
    // reducer implementation...
  }
}
```

child coordinator는 자체 Router를 가집니다:

```swift
@Reducer  
enum ProfileScreen {
  case profileHome(ProfileHomeFeature)
  case profileDetail(ProfileDetailFeature)
}

struct ProfileCoordinator: Reducer {
  // ProfileCoordinator implementation...
}
```

중첩된 coordinator들도 TCACoordinators와 완전히 동일한 방식으로 동작합니다.

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

추가 예제 파일:
- `Example/ForEachRouteExample.swift`: 매크로 없이 깔끔하게 사용하는 패턴들
- `Example/ErrorFixes.swift`: TCAFlow 사용 시 자주 발생하는 에러와 해결법

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
