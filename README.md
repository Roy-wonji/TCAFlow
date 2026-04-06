# TCAFlow 🚀

<div align="center">

![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![TCA](https://img.shields.io/badge/TCA-1.25.5+-blue.svg)
![Platform](https://img.shields.io/badge/platforms-iOS%2016%2B%20%7C%20macOS%2013%2B-lightgrey)
[![License](https://img.shields.io/github/license/yourusername/TCAFlow)](LICENSE)

**TCA를 위한 현대적인 네비게이션 라이브러리**

*TCACoordinators의 편의성 + Hashable 제약 제거 + 더 간단한 API*

</div>

## ✨ 주요 특징

🚀 **Hashable 제약 제거** - `CLLocationCoordinate2D`, `UIImage` 등 모든 타입 지원  
🎯 **직관적인 API** - `.goTo(.profile(.init()))` 형태의 간단한 네비게이션  
🎨 **풍부한 애니메이션** - 다양한 내장 전환 효과  
🔧 **TCA 완벽 통합** - TCA 1.25.5+ 100% 호환  
📱 **NavigationStack 기반** - iOS 16+ 모던한 네비게이션  
⚡ **성능 최적화** - UUID 기반 효율적인 라우팅  

## 📚 상세 문서

📖 **[완전한 문서 보기](DOCUMENTATION.md)** - 아키텍처, API 참조, 고급 사용법  
🌐 **[온라인 예제](Example/TCAFlowExamples)** - 실행 가능한 iOS 앱 예제  

## 🛠 기술적 기반

이 라이브러리는 다음 기술들을 기반으로 구현되었습니다:
- **[TCA](https://github.com/pointfreeco/swift-composable-architecture)**: Point-Free의 Composable Architecture
- **[NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)**: iOS 16+ 네이티브 네비게이션
- **[IdentifiedArray](https://github.com/pointfreeco/swift-identified-collections)**: 효율적인 컬렉션 관리

## 📦 설치 방법

### Swift Package Manager (권장)

Package.swift에 다음을 추가하세요:

```swift
let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/yourusername/TCAFlow.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["TCAFlow"]
        )
    ]
)
```

### Xcode Project

1. File → Add Package Dependencies
2. `https://github.com/yourusername/TCAFlow.git` 입력
3. Add to Target 선택

## 🚀 빠른 시작

### 1단계: Screen 정의
```swift
import TCAFlow

@Reducer  // Hashable 불필요!
enum AppScreen {
    case home(Home.State)
    case profile(Profile.State)
    case settings(Settings.State)
}
```

### 2단계: Coordinator 구현
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
                state.routes.push(.profile(.init()))  // 기본 push
                return .none

            case .home(.settingsTapped):
                state.routes.goTo(.settings(.init()))  // 직접 이동!
                return .none

            case .settings(.backToHome):
                state.routes.goBackTo(.home(.init()))  // 스크린 직접!
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

### 3단계: SwiftUI 연결
```swift
import SwiftUI
import TCAFlow

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

## 🔥 TCACoordinators와 비교

| 기능 | TCACoordinators | TCAFlow |
|------|-----------------|---------|
| **Hashable 제약** | ❌ 필수 (`@Reducer(state: .hashable)`) | ✅ **불필요** (`Equatable`만) |
| **액션 타입** | ❌ `IndexedRouterActionOf` | ✅ **`FlowActionOf`** (간단) |
| **화면 탐색** | ❌ 복잡한 클로저 | ✅ **직접 스크린 넣기** |
| **보일러플레이트** | ❌ 반복적인 설정 | ✅ **최소한의 코드** |
| **애니메이션** | ⚠️ 수동 설정 | ✅ **내장 전환 효과** |

### 실제 코드 비교

```swift
// TCACoordinators - 복잡한 방식
state.routes.goBack(matching: { screen in
    if case .home = screen { return true }
    return false
})

// TCAFlow - 직관적인 방식
state.routes.goBackTo(.home(.init()))
```

## 🎯 핵심 기능

### 네비게이션 API
```swift
// 기본 네비게이션 (TCACoordinators 호환)
state.routes.push(.profile(.init()))    // 화면 추가
state.routes.pop()                      // 뒤로 가기
state.routes.popToRoot()                // 루트로

// TCAFlow 전용 - 스크린 직접 이동
state.routes.goTo(.settings(.init()))           // 특정 화면으로
state.routes.goBackTo(.home(.init()))           // 특정 화면까지 뒤로
state.routes.has(.profile(.init()))             // 화면 존재 확인

// 애니메이션 지원
state.routes.pushWithAnimation(.profile(.init()), animation: .spring)
```

### 전환 효과
```swift
HomeView(store: homeStore)
    .leadingTransition()    // 왼쪽에서 슬라이드
    .bottomTransition()     // 아래에서 올라오기
    .fadeTransition()       // 페이드 인/아웃
    .scaleTransition()      // 확대/축소
    .slideTransition()      // 기본 슬라이드
```

### 복잡한 타입 지원
```swift
struct MapState: Equatable {  // Hashable 불필요!
    let coordinate: CLLocationCoordinate2D  // ✅
    let image: UIImage?                    // ✅
    let customObject: MyClass              // ✅
}

@Reducer
enum AppScreen {
    case map(MapState)  // 완벽 지원
}
```

## 🔧 시스템 요구사항

- **iOS**: 16.0+
- **macOS**: 13.0+
- **watchOS**: 9.0+
- **tvOS**: 16.0+
- **Swift**: 6.0+
- **TCA**: 1.25.5+

## 🤝 마이그레이션 가이드

TCACoordinators에서 TCAFlow로 쉽게 마이그레이션할 수 있습니다:

### 1. 의존성 변경
```swift
// Package.swift
- .package(url: "https://github.com/johnpatrickmorgan/TCACoordinators", from: "0.8.0")
+ .package(url: "https://github.com/yourusername/TCAFlow", from: "1.0.0")
```

### 2. 간단한 코드 변경
```swift
- import TCACoordinators
+ import TCAFlow

- @Reducer(state: .hashable)
+ @Reducer

- case router(IndexedRouterActionOf<AppScreen>)
+ case router(FlowActionOf<AppScreen>)
```

더 자세한 마이그레이션 가이드는 [DOCUMENTATION.md](DOCUMENTATION.md#마이그레이션-가이드)를 참조하세요.

## 📱 예제 앱

완전한 예제 앱이 포함되어 있습니다:
- 4개 화면 (홈, 탐색, 프로필, 설정)
- 다양한 네비게이션 패턴
- 애니메이션 효과
- 실제 사용 시나리오

```bash
cd Example/TCAFlowExamples
open TCAFlowExamples.xcodeproj
```

## 🐛 문제 해결

일반적인 문제와 해결책은 [DOCUMENTATION.md](DOCUMENTATION.md#트러블슈팅)의 트러블슈팅 섹션을 참조하세요.

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

<div align="center">

**TCAFlow로 더 간단하고 강력한 네비게이션을 경험하세요!** 🚀

[GitHub](https://github.com/yourusername/TCAFlow) • [문서](DOCUMENTATION.md) • [예제](Example/TCAFlowExamples)

</div>
