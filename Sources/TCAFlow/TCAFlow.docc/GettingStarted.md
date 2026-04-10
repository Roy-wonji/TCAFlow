# Getting Started

TCAFlow로 coordinator 기반 navigation을 구현하는 방법을 알아봅니다.

## Overview

TCAFlow는 3단계로 사용합니다:
1. **Feature 정의** — 각 화면의 Reducer + View
2. **Coordinator 정의** — Route stack 관리 + Screen enum
3. **View 연결** — `TCAFlowRouter`로 화면 렌더링

## Step 1: Feature 정의

각 화면은 일반 TCA Feature로 작성합니다. State에 `Hashable`이 필요 없습니다.

```swift
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {  // Hashable 불필요!
        var title = "홈 화면"
    }

    @CasePathable
    enum Action {
        case detailTapped
        case settingsTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none  // Navigation은 Coordinator에서 처리
        }
    }
}
```

## Step 2: Coordinator 정의

### 방법 A: @FlowCoordinator 매크로 사용 (권장)

매크로가 State, Action, body를 자동 생성합니다.

```swift
import TCAFlow

@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {}

extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case detail(DetailFeature)
        case settings(SettingsFeature)
    }
}

extension AppCoordinator.Screen.State: Equatable {}

// handleRoute만 작성하면 됩니다
extension AppCoordinator {
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .router(.routeAction(_, .home(.detailTapped))):
            state.routes.push(.detail(.init()))
            return .none

        case .router(.routeAction(_, .home(.settingsTapped))):
            state.routes.presentSheet(.settings(.init()))
            return .none

        case .router(.routeAction(_, .detail(.goBack))):
            state.routes.goBack()
            return .none

        default:
            return .none
        }
    }
}
```

### 방법 B: 수동 작성

매크로 없이 직접 State, Action, body를 작성합니다.

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

## Step 3: View 연결

`TCAFlowRouter`를 사용하여 화면을 렌더링합니다.

```swift
import SwiftUI
import TCAFlow

struct AppCoordinatorView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
            switch screen.case {
            case .home(let store):
                HomeView(store: store)
            case .detail(let store):
                DetailView(store: store)
            case .settings(let store):
                SettingsView(store: store)
            }
        }
    }
}
```

## App 진입점

```swift
@main
struct MyApp: App {
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
