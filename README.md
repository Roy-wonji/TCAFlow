# TCAFlow

**Swift 6 호환 TCA용 Coordinator-style Navigation 라이브러리**

TCAFlow는 [TCACoordinators](https://github.com/johnpatrickmorgan/TCACoordinators)와 동일한 API를 제공하면서도 **`Hashable` 제약 없이** 사용할 수 있는 navigation 라이브러리입니다.

## ✨ 주요 특징

- 🚀 **Hashable 제약 없음** - `Equatable`만으로 충분
- 📱 **Native NavigationStack** - iOS 16+의 최신 Navigation API 활용  
- 🎯 **TCA 전용 설계** - 불필요한 의존성 없음
- 🏗️ **Nested Coordinator** - 복잡한 플로우 완벽 지원
- 🔄 **Migration 친화적** - TCACoordinators에서 쉬운 전환
- ⚡ **Swift 6 호환** - 최신 Swift 기능 활용

## 🆚 TCACoordinators와 비교

| 특징 | TCACoordinators | TCAFlow |
|------|-----------------|---------|
| **Screen State 제약** | `Hashable` 필수 | `Equatable`만 요구 ✅ |
| **의존성** | TCA + FlowStacks | TCA만 ✅ |
| **Navigation API** | FlowStacks 래핑 | Native NavigationStack ✅ |
| **성능** | 간접 참조 오버헤드 | 직접 참조 최적화 ✅ |
| **Nested 지원** | 제한적 | 완전 지원 ✅ |

## 📋 요구사항

- **Swift**: 6.0+
- **TCA**: 1.25.5+
- **플랫폼**: iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+

## 📦 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Roy-wonji/TCAFlow.git", from: "1.0.2")
]
```

```swift
.target(
    name: "App",
    dependencies: ["TCAFlow"]
)
```

## 🚀 빠른 시작

### 1️⃣ 기본 Feature 정의

```swift
import ComposableArchitecture
import TCAFlow

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {  // ✅ Hashable 불필요!
        var title = "홈 화면"
    }
    
    @CasePathable
    enum Action {
        case detailButtonTapped
        case settingsButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .detailButtonTapped, .settingsButtonTapped:
                return .none  // Navigation은 Coordinator에서 처리
            }
        }
    }
}
```

### 2️⃣ Coordinator 구현

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
            // 📱 Navigation 로직
            case .router(.routeAction(_, .home(.detailButtonTapped))):
                state.routes.push(.detail(.init(title: "상세 화면")))
                return .none
                
            case .router(.routeAction(_, .home(.settingsButtonTapped))):
                state.routes.presentSheet(.settings(.init()))
                return .none
                
            case .router(.routeAction(_, .detail(.backTapped))):
                state.routes.goBack()
                return .none
                
            default:
                return .none
            }
        }
        .forEachRoute(\.routes, action: \.router)  // 🔗 라우터 연결
    }
}

// 📄 Screen 정의
extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case detail(DetailFeature)
        case settings(SettingsFeature)
    }
}

extension AppCoordinator.Screen.State: Equatable {}
```

### 3️⃣ View 연결

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
            case .settings(let store):
                SettingsView(store: store)
            }
        }
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text(store.title)
                .font(.largeTitle)
            
            Button("상세 화면으로") {
                store.send(.detailButtonTapped)
            }
            
            Button("설정") {
                store.send(.settingsButtonTapped)  
            }
        }
        .navigationTitle("홈")
    }
}
```

## 📖 Navigation API 가이드

### 🔄 Push / Pop Navigation

```swift
// Push (화면 추가)
state.routes.push(.detail(.init()))
state.routes.push(.settings(.init()))

// Pop (뒤로 가기)
state.routes.goBack()           // 1단계 뒤로
state.routes.goBack(2)          // 2단계 뒤로
state.routes.goBackToRoot()     // 홈으로

// Stack에서만 Pop (presented 화면 유지)
state.routes.pop()              // push된 화면만 pop
state.routes.popToRoot()        // push된 화면 모두 pop
```

### 📑 Sheet / FullScreenCover

```swift
// Sheet 표시
state.routes.presentSheet(.settings(.init()))
state.routes.presentSheet(.profile(.init()), embedInNavigationView: true)

// FullScreenCover 표시  
state.routes.presentCover(.onboarding(.init()))

// Dismiss
state.routes.dismiss()          // 최상단 presented 화면 닫기
state.routes.dismiss(2)         // 2개 presented 화면 닫기
state.routes.dismissAll()       // 모든 presented 화면 닫기
```

### 🎯 특정 화면으로 이동

```swift
// CaseKeyPath로 특정 화면까지 이동
state.routes.goBackTo(\.home)
state.routes.goBackTo(\.profile)

// 조건부 이동
state.routes.goBackTo { route in
    route.screen.id == "specific-id"
}
```

## 🏗️ Nested Coordinator

복잡한 플로우는 Nested Coordinator로 분리할 수 있습니다.

```swift
// 🎯 온보딩 전용 Coordinator
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
        case completed  // 상위 Coordinator에 완료 알림
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .router(.routeAction(_, .welcome(.nextTapped))):
                state.routes.push(.step1(.init()))
                return .none
                
            case .router(.routeAction(_, .step2(.completeTapped))):
                return .send(.completed)  // 🚀 완료 신호
                
            default:
                return .none
            }
        }
        .forEachRoute(\.routes, action: \.router)
    }
}

// 📱 메인 앱에서 사용
extension AppCoordinator {
    @Reducer 
    enum Screen {
        case home(HomeFeature)
        case onboarding(OnboardingCoordinator)  // 🎯 Nested Coordinator
    }
}
```

## 💡 실전 팁

### 🔧 라우터 액션 헬퍼

```swift
extension AppCoordinator {
    // 📝 읽기 쉬운 헬퍼 함수
    private func handleNavigation(
        state: inout State, 
        action: IndexedRouterActionOf<Screen>
    ) -> Effect<Action> {
        switch action {
        case .routeAction(_, .home(let homeAction)):
            return handleHomeAction(state: &state, action: homeAction)
        case .routeAction(_, .detail(let detailAction)):
            return handleDetailAction(state: &state, action: detailAction)
        default:
            return .none
        }
    }
    
    private func handleHomeAction(
        state: inout State,
        action: HomeFeature.Action  
    ) -> Effect<Action> {
        switch action {
        case .detailButtonTapped:
            state.routes.push(.detail(.init(title: "상세")))
            return .none
        }
    }
}
```

### 🎨 Route 확장

```swift
extension Array where Element == Route<AppCoordinator.Screen.State> {
    var isOnDetailScreen: Bool {
        last?.screen.case.is(\.detail) == true
    }
    
    mutating func pushDetailWithId(_ id: String) {
        push(.detail(.init(id: id)))
    }
}
```

## 🔄 Migration from TCACoordinators

TCACoordinators에서 마이그레이션은 간단합니다:

```swift
// Before (TCACoordinators)
import TCACoordinators
TCARouter(store) { screen in ... }

// After (TCAFlow)  
import TCAFlow
TCAFlowRouter(store) { screen in ... }

// ✅ State에서 Hashable 제거
struct MyState: Hashable, Equatable { ... }  // ❌
struct MyState: Equatable { ... }            // ✅
```

## 📚 예제 프로젝트

완전한 예제는 `Example/` 폴더에서 확인하세요:

```
Example/TCAFlowExamples/
├── TCAFlowExamplesApp.swift
├── Coordinators/
│   ├── DemoCoordinator.swift          # 메인 코디네이터
│   └── DemoCoordinatorView.swift      # 라우터 뷰
└── Features/
    ├── Home/                          # 홈 화면
    ├── Flow/                          # 플로우 예제
    ├── Detail/                        # 상세 화면
    ├── Settings/                      # 설정 화면
    └── Nested/                        # 중첩 코디네이터 예제
```

### 🔨 예제 빌드

```bash
cd Example/TCAFlowExamples
open TCAFlowExamples.xcodeproj
```

또는 

```bash
xcodebuild \
    -project Example/TCAFlowExamples/TCAFlowExamples.xcodeproj \
    -scheme TCAFlowExamples \
    -destination 'generic/platform=iOS Simulator' \
    build
```

## 🤝 기여

기여는 언제나 환영입니다! 

1. Fork the repository
2. Create your feature branch
3. Make your changes  
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 확인하세요.

---

**TCAFlow**로 더 깔끔하고 유연한 TCA Navigation을 경험해보세요! 🚀