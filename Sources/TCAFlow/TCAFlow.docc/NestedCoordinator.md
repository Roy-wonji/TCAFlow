# Nested Coordinator

복잡한 플로우를 분리하여 중첩 coordinator로 관리하는 방법을 알아봅니다.

## Overview

앱이 커지면 하나의 coordinator가 모든 화면을 관리하기 어려워집니다. Nested Coordinator 패턴으로 관련 화면끼리 그룹화할 수 있습니다.

## 구조

```
AppCoordinator
├── Home
├── Detail
├── Settings
└── OnboardingCoordinator (Nested)
    ├── Welcome
    ├── Step1
    └── Step2
```

## Nested Coordinator 구현

### @FlowCoordinator 매크로 + body 직접 작성

추가 Action이 필요한 경우 (예: `backToMain`), `body`를 직접 작성합니다.

```swift
@FlowCoordinator(screen: "OnboardingScreen", navigation: true)
struct OnboardingCoordinator {
    // 추가 Action → 매크로가 Action 생성 건너뜀
    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<OnboardingScreen>)
        case completed  // 상위 coordinator에 완료 알림
    }

    // body 직접 작성 → 매크로가 body 생성 건너뜀
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .router(.routeAction(_, .welcome(.nextTapped))):
                state.routes.push(.step1(.init()))
                return .none

            case .router(.routeAction(_, .step2(.completeTapped))):
                return .send(.completed)

            case .completed:
                return .none

            default:
                return .none
            }
        }
        .forEachRoute(\.routes, action: \.router)
    }
}

extension OnboardingCoordinator {
    @Reducer
    enum OnboardingScreen {
        case welcome(WelcomeFeature)
        case step1(Step1Feature)
        case step2(Step2Feature)
    }
}

extension OnboardingCoordinator.OnboardingScreen.State: Equatable {}
```

### 수동 작성 (매크로 없이)

```swift
@Reducer
struct OnboardingCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: [Route<OnboardingScreen.State>] = [
            .root(.welcome(.init()), embedInNavigationView: true)
        ]
    }

    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<OnboardingScreen>)
        case completed
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            // route 처리...
        }
        .forEachRoute(\.routes, action: \.router)
    }
}
```

## 상위 Coordinator에서 사용

```swift
@FlowCoordinator(screen: "AppScreen", navigation: true)
struct AppCoordinator {}

extension AppCoordinator {
    @Reducer
    enum AppScreen {
        case home(HomeFeature)
        case onboarding(OnboardingCoordinator)  // Nested!
    }
}

extension AppCoordinator.AppScreen.State: Equatable {}

extension AppCoordinator {
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .router(.routeAction(_, .home(.startOnboarding))):
            state.routes.push(.onboarding(.init()))
            return .none

        case .router(.routeAction(_, .onboarding(.completed))):
            state.routes.goBackToRoot()
            return .none

        default:
            return .none
        }
    }
}
```

## View 연결

```swift
struct AppCoordinatorView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
            switch screen.case {
            case .home(let store):
                HomeView(store: store)
            case .onboarding(let store):
                OnboardingCoordinatorView(store: store)
            }
        }
    }
}

struct OnboardingCoordinatorView: View {
    @Bindable var store: StoreOf<OnboardingCoordinator>

    var body: some View {
        TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
            switch screen.case {
            case .welcome(let store):
                WelcomeView(store: store)
            case .step1(let store):
                Step1View(store: store)
            case .step2(let store):
                Step2View(store: store)
            }
        }
    }
}
```

## Nested Coordinator에서 Swipe Back

Nested coordinator가 push로 진입한 경우, 사용자 정의 swipe back 제스처를 추가할 수 있습니다:

```swift
struct OnboardingCoordinatorView: View {
    @Bindable var store: StoreOf<OnboardingCoordinator>
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
            // screen rendering...
        }
        .offset(x: dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .updating($dragOffset) { value, state, _ in
                    if value.startLocation.x < 30 && value.translation.width > 0 {
                        state = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.startLocation.x < 30 && value.translation.width > 100 {
                        store.send(.completed)
                    }
                }
        )
    }
}
```
