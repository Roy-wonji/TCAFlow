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
- 🎨 **@FlowCoordinator 매크로** - 보일러플레이트 코드 자동 생성

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
- **Xcode**: 16.0+ (매크로 지원)

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
    dependencies: ["TCAFlow"]  // 매크로 자동 포함 ✅
)
```

**참고**: TCAFlow 패키지에는 `@FlowCoordinator` 매크로가 자동으로 포함됩니다.

## 🎨 @FlowCoordinator 매크로

TCAFlow는 **`@FlowCoordinator` 매크로**를 제공하여 Coordinator의 보일러플레이트 코드를 자동으로 생성합니다.

### ✨ 매크로를 사용하면 이렇게 간단해집니다!

#### **기존 방식 (수동 작성)**
```swift
@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: [Route<Screen.State>]
        init() {
            routes = [.root(.home(.init()), embedInNavigationView: true)]
        }
    }
    
    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<Screen>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            return handleRoute(state: &state, action: action)
        }
        .forEachRoute(\.routes, action: \.router)
    }
    
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        // 라우팅 로직...
    }
}
```

#### **💫 매크로 사용 (자동 생성)**
```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        // 라우팅 로직만 작성!
        switch action {
        case .router(.routeAction(_, .home(.detailTapped))):
            state.routes.push(.detail(.init()))
            return .none
        default:
            return .none
        }
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

### 🔧 매크로 사용법

#### **방식 1: struct에 직접 적용 (권장)**
```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {
    // ✅ 자동 생성: State, Action, body
    
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        // 라우팅 로직만 작성
    }
}

extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case detail(DetailFeature)
    }
}

// ✅ 자동 생성: Screen.State: Equatable
```

#### **방식 2: extension에 적용**
```swift
struct AppCoordinator {}

@FlowCoordinator(navigation: true)
extension AppCoordinator {
    @Reducer
    enum Screen {
        case home(HomeFeature)
        case detail(DetailFeature)
    }
    
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        // 라우팅 로직
    }
}
```

### 📋 매크로 파라미터

```swift
@FlowCoordinator(
    screen: "Screen",    // Screen enum 이름 (optional)
    navigation: true     // root route에 embedInNavigationView 적용 (기본값: true)
)
```

- **`screen`**: Screen enum의 이름을 명시적으로 지정
- **`navigation`**: `true`이면 root route가 NavigationView를 embed

### 🎛️ 커스터마이징

#### **Action에 추가 케이스가 필요한 경우**
```swift
@FlowCoordinator(screen: "Screen")
struct NestedCoordinator {
    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<Screen>)
        case backToMain  // ✅ 추가 액션
        case deepLink(URL)
    }
    
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .backToMain:
            // 커스텀 로직
            return .none
        case .router(let routerAction):
            // 라우팅 로직
            return .none
        default:
            return .none
        }
    }
}
```

#### **State 초기화를 커스터마이징하는 경우**
```swift
@FlowCoordinator(screen: "Screen")
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: [Route<Screen.State>]
        var isLoggedIn: Bool  // ✅ 추가 프로퍼티
        
        init(isLoggedIn: Bool = false) {
            self.isLoggedIn = isLoggedIn
            self.routes = isLoggedIn
                ? [.root(.home(.init()), embedInNavigationView: true)]
                : [.root(.login(.init()), embedInNavigationView: true)]
        }
    }
    
    // ✅ Action, body는 자동 생성
}
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

### 2️⃣ Coordinator 구현 (매크로 사용)

```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {
    // ✨ State, Action, body는 매크로가 자동 생성!
    
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        // 📱 Navigation 로직만 집중!
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

// ✨ Screen.State: Equatable도 매크로가 자동 생성!
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
// 🔙 뒤로 이동 (goBackTo)
state.routes.goBackTo(\.home)         // 홈 화면까지 pop
state.routes.goBackTo(\.profile)      // 프로필 화면까지 pop

// 🎯 스마트 이동 (goTo) - 가장 일반적인 방식
state.routes.goTo(.settings(.init()))  // 설정으로 이동 (없으면 새로 생성)
state.routes.goTo(.profile(.init()))   // 프로필로 이동 (없으면 새로 생성)
state.routes.goTo(.detail(.init()))    // 상세로 이동 (없으면 새로 생성)

// 🏠 이전 화면으로 돌아가기 (특수 용도)
state.routes.goTo(\.home)             // 이전 홈으로 바로 돌아가기

// 🔍 조건부 이동
state.routes.goBackTo { route in
    route.screen.id == "specific-id"
}

state.routes.goTo { route in
    route.screen.isTargetScreen
}
```

**💡 언제 어떤 방식을 사용할까?**

```swift
// ✅ 일반적인 경우: 무조건 해당 화면으로 이동
case .settingsButtonTapped:
    state.routes.goTo(.settings(.init()))  // 없으면 새로 생성
    return .none

case .profileButtonTapped:
    state.routes.goTo(.profile(.init(userId: user.id)))
    return .none

// ✅ 특수한 경우: "이전 홈으로 돌아가기" 같은 경우
case .backToHomeButtonTapped:
    state.routes.goTo(\.home)  // 스택의 홈으로 바로 이동
    return .none
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

## 🎨 @FlowCoordinator vs 수동 작성

| 특징 | 수동 작성 | @FlowCoordinator 매크로 |
|------|----------|----------------------|
| **코드 길이** | ~30줄 | ~10줄 ✅ |
| **보일러플레이트** | 많음 | 자동 생성 ✅ |
| **실수 가능성** | 높음 | 낮음 ✅ |
| **커스터마이징** | 완전 자유 | 일부 제약 |
| **학습 곡선** | 높음 | 낮음 ✅ |

### 🤔 언제 무엇을 사용할까?

#### **✅ @FlowCoordinator 매크로 사용 권장**
- 새 프로젝트 시작
- 간단한 Coordinator
- 빠른 프로토타이핑
- 보일러플레이트 줄이고 싶을 때

#### **✅ 수동 작성 권장**  
- 기존 코드가 많을 때
- 매우 복잡한 State 초기화
- Action에 많은 커스텀 케이스 필요
- 매크로를 학습할 시간이 없을 때

## 💡 실전 팁

### 🔧 매크로 사용 시 팁

```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct AppCoordinator {
    // ✅ handleRoute 메서드는 필수!
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .router(let routerAction):
            return handleRouterAction(state: &state, action: routerAction)
        default:
            return .none
        }
    }
    
    // 🎯 라우터 액션을 별도 메서드로 분리하면 깔끔
    private func handleRouterAction(
        state: inout State,
        action: IndexedRouterActionOf<Screen>
    ) -> Effect<Action> {
        switch action {
        case .routeAction(_, .home(.detailTapped)):
            state.routes.push(.detail(.init()))
            return .none
        // ...
        }
    }
}
```

### 🔧 라우터 액션 헬퍼 (수동 작성 시)

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

### 1️⃣ 기본 마이그레이션
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

### 2️⃣ 매크로로 더 간단하게!

#### **Before (TCACoordinators - 수동 작성)**
```swift
@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Hashable, Equatable {  // Hashable 필요
        var routes: [Route<Screen.State>] = [...]
    }
    
    @CasePathable
    enum Action {
        case router(IndexedRouterActionOf<Screen>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            // 라우팅 로직...
        }
        .forEachRoute(\.routes, action: \.router)
    }
}
```

#### **After (TCAFlow - 매크로 사용)**
```swift
@FlowCoordinator(screen: "Screen", navigation: true)  // 🎨 매크로로 한 줄!
struct AppCoordinator {
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        // 라우팅 로직만 작성하면 끝!
        switch action {
        case .router(.routeAction(_, .home(.detailTapped))):
            state.routes.push(.detail(.init()))
            return .none
        default:
            return .none
        }
    }
}
```

### 🚀 Migration Steps

1. **Import 변경**: `TCACoordinators` → `TCAFlow`
2. **Router 변경**: `TCARouter` → `TCAFlowRouter`
3. **Hashable 제거**: Screen State에서 `Hashable` 삭제
4. **매크로 적용**: `@FlowCoordinator` 매크로로 보일러플레이트 제거 (선택사항)

## 📚 예제 프로젝트

완전한 예제는 `Example/` 폴더에서 확인하세요:

```
Example/TCAFlowExamples/
├── TCAFlowExamplesApp.swift
├── Coordinators/
│   ├── DemoCoordinator.swift          # @FlowCoordinator 매크로 사용 예제 🎨
│   └── DemoCoordinatorView.swift      # 라우터 뷰
└── Features/
    ├── Home/                          # 홈 화면 + goTo 예제
    ├── Flow/                          # 플로우 예제 + goTo 예제  
    ├── Detail/                        # 상세 화면 + goTo 예제
    ├── Settings/                      # 설정 화면 + goTo 예제
    └── Nested/                        # 중첩 코디네이터 예제
```

**🎨 매크로 사용 예제**: `DemoCoordinator.swift`에서 `@FlowCoordinator` 매크로가 어떻게 보일러플레이트를 줄이는지 확인할 수 있습니다!

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