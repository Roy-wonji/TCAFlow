# TCAFlow

TCA(The Composable Architecture)용 coordinator-style navigation 라이브러리.

[TCACoordinators](https://github.com/johnpatrickmorgan/TCACoordinators)와 동일한 API를 제공하지만, 화면 state에 **`Hashable`을 요구하지 않습니다.** `Equatable`만 있으면 됩니다.

## Features

- TCACoordinators와 동일한 coordinator 패턴
- `Hashable` 불필요 - `Equatable`만 요구
- NavigationStack 기반 push/pop
- Sheet / FullScreenCover 지원
- Nested Coordinator 지원 (`embedInNavigationView: true`)
- `@Reducer enum` Screen의 `CaseScope` 자동 지원
- iOS 16+, Swift 6 호환

## TCACoordinators와 차이점

| 항목 | TCACoordinators | TCAFlow |
| --- | --- | --- |
| Screen State 제약 | `Hashable` 필수 | `Equatable`만 요구 |
| Navigation 구현 | FlowStacks 기반 | NavigationStack 직접 사용 |
| 의존성 | FlowStacks + TCA | TCA만 |
| API | `TCARouter` | `TCAFlowRouter` |

## Requirements

- Swift 6.0+
- TCA 1.25.5+
- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/AhnSunghyun/TCAFlow.git", from: "1.0.0")
]
```

```swift
.target(
    name: "App",
    dependencies: ["TCAFlow"]
)
```

## Quick Start

### 1. Feature 정의

```swift
@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {}  // Hashable 불필요!

    @CasePathable
    enum Action {
        case detailTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
```

### 2. Coordinator 정의

```swift
@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: [Route<Screen.State>] = [
            .root(.home(.init()), embedInNavigationView: true)
        ]
    }

    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<Screen>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .router(.routeAction(_, .home(.detailTapped))):
                state.routes.push(.detail(.init()))
                return .none
            case .router(.routeAction(_, .detail(.goBack))):
                state.routes.goBack()
                return .none
            default:
                return .none
            }
        }
        .forEachRoute(\.routes, action: \.router)
    }
}

extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case detail(DetailFeature)
    }
}

extension AppCoordinator.Screen.State: Equatable {}
```

### 3. View 연결

```swift
struct AppCoordinatorView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
            switch screen.case {
            case .home(let store):
                HomeView(store: store)
            case .detail(let store):
                DetailView(store: store)
            }
        }
    }
}
```

## Navigation API

### Push / Pop

```swift
state.routes.push(.detail(.init()))
state.routes.goBack()
state.routes.goBackToRoot()
state.routes.pop()
```

### Sheet / Cover

```swift
state.routes.presentSheet(.settings(.init()), embedInNavigationView: true)
state.routes.presentCover(.onboarding(.init()), embedInNavigationView: true)
state.routes.dismiss()
state.routes.dismissAll()
```

### 특정 화면으로 이동

```swift
// CaseKeyPath로 특정 화면까지 pop
state.routes.goBackTo(\.home)
```

## Nested Coordinator

다른 coordinator를 screen case에 넣을 수 있습니다.

```swift
extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case nested(NestedCoordinator)  // 중첩 coordinator
    }
}
```

Nested coordinator는 자체 routes와 TCAFlowRouter를 가집니다:

```swift
@Reducer
struct NestedCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: [Route<NestedScreen.State>] = [
            .root(.step1(.init()), embedInNavigationView: true)
        ]
    }

    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<NestedScreen>)
        case backToMain
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            // handle route actions...
        }
        .forEachRoute(\.routes, action: \.router)
    }
}
```

## Example App

```
Example/TCAFlowExamples/
├── TCAFlowExamplesApp.swift
├── Coordinators/
│   ├── DemoCoordinator.swift
│   └── DemoCoordinatorView.swift
└── Features/
    ├── Home/
    ├── Flow/
    ├── Detail/
    ├── Settings/
    └── Nested/
```

빌드:

```sh
xcodebuild \
    -project Example/TCAFlowExamples/TCAFlowExamples.xcodeproj \
    -scheme TCAFlowExamples \
    -destination 'generic/platform=iOS Simulator' \
    build
```

## License

MIT
