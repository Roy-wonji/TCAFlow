# 🪄 TCAFlow 매크로 사용 예제

## @FlowCoordinator 매크로

### 기존 방식 (100+ 줄)
```swift
@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: IdentifiedArrayOf<Route<AppScreen.State>> = [
            Route(.home(.init()))
        ]
    }
    
    enum Action {
        case router(FlowActionOf<AppScreen>)
        case home(Home.Action)
        case explore(Explore.Action)
        case profile(Profile.Action)
        case settings(Settings.Action)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .home(.exploreTapped):
                state.routes.push(.explore(.init()))
                return .none
            // ... 수십 줄의 네비게이션 로직
            }
        }
        .forEach(\.routes, action: \.router) {
            AppScreen()
        }
    }
}
```

### TCAFlow 매크로 방식 (10줄!)
```swift
@FlowCoordinator
@Reducer
struct AppCoordinator {
    enum Screen {
        case home(Home)
        case explore(Explore)
        case profile(Profile)
        case settings(Settings)
    }
}
```

## 매크로가 자동 생성하는 코드

```swift
// 1. State 구조체
@ObservableState
struct State: Equatable {
    var routes: IdentifiedArrayOf<Route<AppScreen.State>> = [
        Route(.home(.init()))
    ]
}

// 2. Action enum
enum Action {
    case router(FlowActionOf<AppScreen>)
    case home(Home.Action)
    case explore(Explore.Action)
    case profile(Profile.Action)
    case settings(Settings.Action)
}

// 3. Body reducer (기본 네비게이션 로직 포함)
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .home(.goNext):
            state.routes.push(.explore(.init()))
            return .none
        case .home(.goBack):
            state.routes.pop()
            return .none
        // ... 각 화면별 자동 생성된 로직
        default:
            return .none
        }
    }
    .forEach(\.routes, action: \.router) {
        AppScreen()
    }
}
```

## 🚀 혁신적인 개선

| 항목 | 기존 방식 | @FlowCoordinator |
|------|-----------|------------------|
| **코드량** | 100+ 줄 | ✅ **10줄** |
| **보일러플레이트** | ❌ 수동 작성 | ✅ **자동 생성** |
| **실수 가능성** | ❌ 높음 | ✅ **매크로로 방지** |
| **유지보수** | ❌ 반복 수정 | ✅ **한 곳에서 관리** |
| **가독성** | ❌ 복잡함 | ✅ **매우 간단** |

## 🎯 사용법

1. **Screen enum 정의** - 각 화면을 case로
2. **@FlowCoordinator 추가** - 보일러플레이트 자동 생성
3. **SwiftUI에서 사용** - TCAFlowRouter와 연결

```swift
// SwiftUI 사용 (변경 없음)
TCAFlowRouter(store.routes) { screen in
    switch screen.case {
    case .home(let homeStore):
        HomeView(store: homeStore)
    // ...
    }
}
```

## 🔮 미래 확장

- **@FlowScreen** - 각 화면별 매크로
- **@FlowAction** - 액션 자동 생성
- **@FlowRouter** - SwiftUI 라우터 매크로

TCAFlow 매크로로 **99% 보일러플레이트 제거** 달성! 🎉