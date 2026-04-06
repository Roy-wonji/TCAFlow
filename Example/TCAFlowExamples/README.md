# TCAFlowExamples

TCAFlow를 사용한 iOS 앱 예제입니다.

## 프로젝트 설정

1. **Xcode에서 TCAFlow 라이브러리 추가**
   - Xcode에서 `TCAFlowExamples.xcodeproj` 열기
   - Project Navigator에서 프로젝트 선택
   - `Package Dependencies` 탭으로 이동
   - `+` 버튼 클릭
   - `Add Local...` 선택하고 상위 폴더 선택 (TCAFlow 폴더)

2. **또는 GitHub URL로 추가** (향후)
   ```
   https://github.com/yourusername/TCAFlow
   ```

## 주요 기능

### TCAFlowRouter 사용법
```swift
TCAFlowRouter(store.routes) { screen in
    switch screen.case {
    case .home(let homeStore):
        HomeView(store: homeStore)
            .navigationBarBackButtonHidden()
            .leadingTransition()  // 커스텀 전환 효과

    case .explore(let exploreStore):
        ExploreView(store: exploreStore)
            .navigationBarBackButtonHidden()
            .bottomTransition()   // 아래에서 올라오는 효과
    // ...
    }
}
.animation(.easeInOut(duration: 0.1), value: store.routes.count)
```

### 네비게이션 API
```swift
// 기본 네비게이션
state.routes.push(.explore(.init()))       // 화면 추가
state.routes.pop()                         // 뒤로 가기
state.routes.popToRoot()                   // 루트로

// 스크린 직접 이동 (TCAFlow 특화)
state.routes.goTo(.profile(.init()))       // 특정 화면으로
state.routes.goBackTo(.home(.init()))      // 특정 화면까지 뒤로

// 애니메이션과 함께
state.routes.pushWithAnimation(.settings(.init()), animation: .spring)
state.routes.goToWithAnimation(.profile(.init()))
```

### 전환 효과들
- `.leadingTransition()` - 왼쪽에서 들어오기
- `.bottomTransition()` - 아래에서 올라오기  
- `.slideTransition()` - 기본 슬라이드
- `.fadeTransition()` - 페이드 인/아웃
- `.scaleTransition()` - 스케일 효과

## 앱 구조

```
📱 홈
├─ 🔍 탐색
├─ 👤 프로필
│  └─ ⚙️ 설정
└─ ⚙️ 설정
   └─ 🏠 홈으로 (루트 이동)
```

### 화면들
- **HomeView**: 메인 화면, 다른 화면으로 이동
- **ExploreView**: 아이템 목록, 선택 기능
- **ProfileView**: 사용자 프로필 정보
- **SettingsView**: 앱 설정 (알림, 다크모드, 언어)

### TCA 패턴
각 화면은 독립적인 Reducer를 가지며:
- `@ObservableState` - 화면 상태
- `Action` - 사용자 액션들
- `body` - 비즈니스 로직

AppCoordinator에서 네비게이션 로직을 중앙 관리합니다.

## 빌드 & 실행

1. Xcode에서 프로젝트 열기
2. iOS 16.0+ 시뮬레이터 선택
3. ⌘+R로 실행

## 특징

- ✅ **Hashable 불필요**: `CLLocationCoordinate2D`, `UIImage` 등 모든 타입 지원
- ✅ **스크린 직접 이동**: 클로저 없이 `.goTo(.profile(.init()))`  
- ✅ **애니메이션**: 다양한 전환 효과 내장
- ✅ **타입 안전**: 컴파일 타임에 네비게이션 오류 발견