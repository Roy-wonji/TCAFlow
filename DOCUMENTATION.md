# TCAFlow - TCA 네비게이션 라이브러리 상세 문서

## 📋 목차
1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [핵심 개념](#핵심-개념)
4. [API 참고서](#api-참고서)
5. [사용 예시](#사용-예시)
6. [마이그레이션 가이드](#마이그레이션-가이드)
7. [트러블슈팅](#트러블슈팅)

---

## 개요

TCAFlow는 TCA(The Composable Architecture)를 위한 현대적인 네비게이션 라이브러리입니다. TCACoordinators의 모든 기능을 제공하면서도 **Hashable 제약을 완전히 제거**하여 더욱 유연하고 직관적인 네비게이션을 제공합니다.

### 핵심 특징
- 🚀 **Hashable 제약 제거**: `CLLocationCoordinate2D`, `UIImage` 등 모든 타입 지원
- 🎯 **직관적 API**: `.goTo(.profile(.init()))` 형태의 간단한 네비게이션
- 🎨 **풍부한 애니메이션**: 내장된 다양한 전환 효과
- 🔧 **TCA 완벽 통합**: TCA 1.25.5+ 완전 호환
- 📱 **iOS 16+ 지원**: NavigationStack 기반 모던한 네비게이션

### 기존 문제점 해결

| 문제 | TCACoordinators | TCAFlow |
|------|-----------------|---------|
| Hashable 제약 | ❌ `@Reducer(state: .hashable)` 필수 | ✅ `Equatable`만 필요 |
| 복잡한 타입 이름 | ❌ `IndexedRouterActionOf` | ✅ `FlowActionOf` |
| 클로저 기반 탐색 | ❌ `.goBack(matching: { ... })` | ✅ `.goBackTo(.home(.init()))` |
| 보일러플레이트 | ❌ 반복적인 router 설정 | ✅ 간단한 구성 |

---

## 아키텍처

TCAFlow는 다음과 같은 구조로 설계되었습니다:

```
TCAFlow/
├── Sources/
│   └── TCAFlow/
│       ├── TCAFlow.swift           # 핵심 네비게이션 API
│       └── TCARouter.swift         # SwiftUI 컴포넌트 & 애니메이션
├── Tests/
│   └── TCAFlowTests/
│       └── TCAFlowTests.swift      # 유닛 테스트
└── Example/
    └── TCAFlowExamples/            # iOS 예제 앱
```

### 핵심 구성 요소

#### 1. Route<State>
```swift
public struct Route<State: Equatable>: Identifiable, Hashable {
    public let id = UUID()
    public var state: State
    
    // UUID 기반 해싱으로 Hashable 제약 우회
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

#### 2. FlowActionOf<Screen>
```swift
public typealias FlowActionOf<Screen: Reducer> = (id: Route<Screen.State>.ID, action: Screen.Action)
```

#### 3. IdentifiedArrayOf Extensions
네비게이션을 위한 편의 메서드들을 제공하는 확장들

#### 4. TCAFlowRouter
SwiftUI 애니메이션과 전환 효과를 제공하는 라우터 컴포넌트

---

## 핵심 개념

### 1. Route 기반 네비게이션

TCAFlow는 `Route<State>` 타입을 사용하여 화면을 관리합니다. 각 Route는 고유한 UUID를 가지며, 이를 통해 Hashable 제약 없이도 식별 가능합니다.

```swift
// Route 생성
let homeRoute = Route(.home(.init()))
let profileRoute = Route(.profile(.init()))

// 네비게이션 스택
var routes: IdentifiedArrayOf<Route<AppScreen.State>> = [homeRoute]
```

### 2. 스크린 기반 탐색

TCAFlow의 가장 큰 특징은 스크린을 직접 사용한 탐색입니다:

```swift
// 기존 TCACoordinators
state.routes.goBack(matching: { screen in
    if case .home = screen { return true }
    return false
})

// TCAFlow
state.routes.goBackTo(.home(.init()))
```

### 3. 애니메이션 시스템

다양한 내장 애니메이션을 제공합니다:

```swift
// 기본 애니메이션
state.routes.pushWithAnimation(.profile(.init()))

// 커스텀 애니메이션
state.routes.pushWithAnimation(.profile(.init()), animation: .spring)
```

---

## API 참고서

### Route<State>

#### 초기화
```swift
public init(_ state: State)
```
새로운 Route를 생성합니다.

#### 프로퍼티
- `id: UUID` - 고유 식별자
- `state: State` - 화면 상태

### IdentifiedArrayOf 확장

#### 기본 네비게이션
```swift
public mutating func push<S: Equatable>(_ state: S) where Element == Route<S>
public mutating func pop() -> Element?
public mutating func popToRoot()
public mutating func replace<S: Equatable>(with state: S) where Element == Route<S>
```

#### 스크린 직접 탐색
```swift
public mutating func goTo<S: Equatable>(_ targetScreen: S) where Element == Route<S>
public mutating func goBackTo<S: Equatable>(_ targetScreen: S) where Element == Route<S>
public func has<S: Equatable>(_ targetScreen: S) -> Bool where Element == Route<S>
```

#### 애니메이션 지원
```swift
public mutating func pushWithAnimation<S: Equatable>(_ state: S, animation: Animation = .default)
public mutating func popWithAnimation(animation: Animation = .default) -> Element?
public mutating func goToWithAnimation<S: Equatable>(_ targetScreen: S, animation: Animation = .default)
public mutating func goBackToWithAnimation<S: Equatable>(_ targetScreen: S, animation: Animation = .default)
```

#### 유틸리티
```swift
public var currentScreen: Element?  // 현재 화면
public var rootScreen: Element?     // 루트 화면  
public var depth: Int              // 스택 깊이
```

### TCAFlowRouter

#### 초기화
```swift
public init(
    _ routes: IdentifiedArrayOf<Route<Screen>>,
    @ViewBuilder screenView: @escaping (Screen) -> ScreenView
)
```

### 전환 효과

#### View 확장
```swift
public func flowTransition(_ transition: AnyTransition) -> some View
public func slideTransition() -> some View
public func fadeTransition() -> some View
public func scaleTransition() -> some View
public func leadingTransition() -> some View
public func bottomTransition() -> some View
```

---

## 사용 예시

### 기본 설정

#### 1. Screen enum 정의
```swift
@Reducer
enum AppScreen {
    case home(Home.State)
    case profile(Profile.State)
    case settings(Settings.State)
}
```

#### 2. Coordinator 구현
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
        case profile(Profile.Action)
        case settings(Settings.Action)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .home(.profileTapped):
                state.routes.push(.profile(.init()))
                return .none
                
            case .profile(.settingsTapped):
                state.routes.goTo(.settings(.init()))
                return .none
                
            case .settings(.backToHome):
                state.routes.goBackTo(.home(.init()))
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.routes, action: \.router) {
            AppScreen()
        }
    }
}
```

#### 3. SwiftUI 뷰 연결
```swift
struct ContentView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        TCAFlowRouter(store.routes) { screen in
            switch screen.case {
            case .home(let homeStore):
                HomeView(store: homeStore)
                    .leadingTransition()

            case .profile(let profileStore):
                ProfileView(store: profileStore)
                    .slideTransition()

            case .settings(let settingsStore):
                SettingsView(store: settingsStore)
                    .fadeTransition()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.routes.count)
    }
}
```

### 고급 사용법

#### 조건부 네비게이션
```swift
case .userAction(.navigate):
    if state.isLoggedIn {
        state.routes.goTo(.profile(.init()))
    } else {
        state.routes.goTo(.login(.init()))
    }
    return .none
```

#### 깊은 링크 처리
```swift
case .deepLink(let url):
    switch url.path {
    case "/profile":
        state.routes.goTo(.profile(.init()))
    case "/settings":
        state.routes.goTo(.settings(.init()))
    default:
        state.routes.popToRoot()
    }
    return .none
```

#### 복잡한 타입 지원
```swift
struct MapState: Equatable {  // Hashable 불필요!
    let coordinate: CLLocationCoordinate2D
    let image: UIImage?
    let customClass: MyClass
}

@Reducer
enum AppScreen {
    case map(MapState)  // ✅ 완벽 지원
}
```

---

## 마이그레이션 가이드

### TCACoordinators에서 마이그레이션

#### 1. 의존성 변경
```swift
// Before
.package(url: "https://github.com/johnpatrickmorgan/TCACoordinators", from: "0.8.0")

// After  
.package(url: "https://github.com/yourusername/TCAFlow", from: "1.0.0")
```

#### 2. Import 변경
```swift
// Before
import TCACoordinators

// After
import TCAFlow
```

#### 3. Reducer 어노테이션 제거
```swift
// Before
@Reducer(state: .hashable)
enum AppScreen {
    // ...
}

// After
@Reducer
enum AppScreen {
    // ...
}
```

#### 4. 액션 타입 변경
```swift
// Before
case router(IndexedRouterActionOf<AppScreen>)

// After
case router(FlowActionOf<AppScreen>)
```

#### 5. 네비게이션 메서드 업그레이드
```swift
// Before
state.routes.goBack(matching: { screen in
    if case .home = screen { return true }
    return false
})

// After
state.routes.goBackTo(.home(.init()))
```

#### 6. 라우터 컴포넌트 변경
```swift
// Before
TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
    // ...
}

// After  
TCAFlowRouter(store.routes) { screen in
    // ...
}
```

---

## 트러블슈팅

### 일반적인 문제들

#### 1. 컴파일 오류: "No such module 'TCAFlow'"
**원인**: 패키지가 올바르게 추가되지 않음
**해결책**: 
```swift
// Package.swift에 의존성 추가 확인
.package(url: "https://github.com/yourusername/TCAFlow", from: "1.0.0")
```

#### 2. 네비게이션이 작동하지 않음
**원인**: Reducer에서 forEach 설정 누락
**해결책**:
```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        // ... 네비게이션 로직
    }
    .forEach(\.routes, action: \.router) {  // ✅ 필수
        AppScreen()
    }
}
```

#### 3. 애니메이션이 부자연스러움
**원인**: 충돌하는 애니메이션 설정
**해결책**:
```swift
TCAFlowRouter(store.routes) { screen in
    // ... 화면들
}
.animation(.easeInOut(duration: 0.3), value: store.routes.count)  // ✅ 하나의 애니메이션만
```

#### 4. 메모리 누수
**원인**: Strong reference cycle
**해결책**: Store capture에 주의
```swift
// ❌ 잘못된 방법
TCAFlowRouter(store.routes) { screen in
    SomeView(store: store)  // Strong capture
}

// ✅ 올바른 방법  
TCAFlowRouter(store.routes) { screen in
    switch screen.case {
    case .some(let someStore):
        SomeView(store: someStore)
    }
}
```

### 성능 최적화

#### 1. Route 개수 제한
네비게이션 스택이 너무 깊어지지 않도록 주의하세요:
```swift
// 스택이 너무 깊을 때 자동 정리
if state.routes.depth > 10 {
    state.routes.popToRoot()
}
```

#### 2. 불필요한 State 업데이트 방지
```swift
// ❌ 매번 새로운 상태 생성
state.routes.goTo(.profile(.init()))

// ✅ 기존 상태가 있으면 재사용
if !state.routes.has(.profile(.init())) {
    state.routes.goTo(.profile(.init()))
}
```

### 디버깅 팁

#### 1. 네비게이션 스택 상태 확인
```swift
#if DEBUG
case .debugAction(.printStack):
    print("현재 스택 깊이: \(state.routes.depth)")
    print("현재 화면: \(String(describing: state.routes.currentScreen))")
    return .none
#endif
```

#### 2. 로그 추가
```swift
case .router(let routerAction):
    print("네비게이션: \(routerAction)")
    return .none
```

---

*TCAFlow v1.0.0 기준으로 작성된 문서입니다.*