# TCAFlow Examples

**TCAFlow 라이브러리의 실용적인 사용법을 보여주는 예제 앱**

TCAFlow의 다양한 기능들을 실제 앱에서 어떻게 활용할 수 있는지 보여주는 데모 애플리케이션입니다.

## 📱 앱 구조

### 탭 기반 아키텍처
- **Demo 탭**: 기본적인 TCAFlow 기능들
- **Showcase 탭**: 고급 기능 및 실제 사용 사례들

### 주요 기능 데모

#### 🚀 기본 Navigation
- **단순 Push**: 기본적인 화면 이동
- **Flow Navigation**: 순차적인 플로우 관리
- **Nested Coordinator**: 중첩된 코디네이터 구조

#### 🏗️ 고급 패턴
- **Tab Coordinator**: 탭별 독립적인 네비게이션 스택
- **Pop to Root**: 탭 재선택 시 루트로 이동
- **Deep Linking**: 딥링크를 통한 특정 화면 이동
- **Half Sheet**: 모달 프레젠테이션

## 🏭 아키텍처

```
TCAFlowExamples/
├── TCAFlowExamplesApp.swift        # 앱 진입점
├── Tab/
│   ├── MainTabCoordinator.swift    # 메인 탭 코디네이터
│   └── MainTabView.swift           # 탭 뷰
├── Coordinators/
│   ├── DemoCoordinator.swift       # Demo 탭 코디네이터
│   └── DemoCoordinatorView.swift   # Demo 코디네이터 뷰
└── Features/
    ├── Home/                       # 홈 화면
    │   ├── HomeFeature.swift
    │   └── HomeView.swift
    ├── Flow/                       # 플로우 예제
    │   ├── FlowFeature.swift
    │   └── FlowView.swift
    ├── Detail/                     # 상세 화면
    │   ├── DetailFeature.swift
    │   └── DetailView.swift
    ├── Settings/                   # 설정 화면
    │   ├── SettingsFeature.swift
    │   └── SettingsView.swift
    └── Nested/                     # 중첩 코디네이터 예제
        ├── NestedCoordinator.swift
        ├── NestedCoordinatorView.swift
        ├── NestedStep1Feature.swift
        ├── NestedStep1View.swift
        ├── NestedStep2Feature.swift
        └── NestedStep2View.swift
```

## 🚀 빌드 및 실행

### 요구사항
- **Xcode**: 16.0+
- **iOS**: 17.0+
- **Swift**: 6.0+

### 의존성
- TCAFlow (로컬 패키지)
- ComposableArchitecture 1.25.5+
- IdentifiedCollections 1.1.1+

### 실행 방법

1. **Tuist를 통한 프로젝트 생성**:
   ```bash
   cd TCAFlow/Example/TCAFlowExamples
   tuist generate
   ```

2. **Xcode에서 열기**:
   ```bash
   open TCAFlowExamples.xcworkspace
   ```

3. **빌드 및 실행**:
   - 타겟: `TCAFlowExamples`
   - 시뮬레이터 또는 실제 디바이스에서 실행

## 🔧 최신 업데이트

### v1.0.2 주요 변경사항
- ✅ **빌드 최적화**: 모든 빌드 설정에 `-suppress-warnings` 플래그 추가
- ✅ **매크로 경고 수정**: `@FlowCoordinator` 매크로의 protocol composition 경고 해결
- ✅ **성능 개선**: NavigationRequestObserver 중복 업데이트 방지 로직 추가
- ✅ **UI 개선**: HomeView에 스크롤 기능 추가 및 폴더 구조 정리
- ✅ **기능 확장**: Showcase 탭 추가로 고급 기능 데모 제공

## 📋 학습 가이드

### 1단계: 기본 Navigation
`HomeView`에서 시작해서 기본적인 push/pop 동작을 확인해보세요.

### 2단계: Flow Management
`FlowFeature`를 통해 순차적인 플로우 관리 방법을 학습하세요.

### 3단계: Nested Coordinators
`NestedCoordinator`에서 복잡한 플로우의 중첩 관리를 이해하세요.

### 4단계: Tab Navigation
`MainTabCoordinator`를 통해 탭별 독립적인 네비게이션 구현을 확인하세요.

## 🛠️ 개발자 팁

- **@FlowCoordinator 매크로**: 보일러플레이트 코드를 대폭 줄여줍니다
- **Equatable만 필요**: Hashable 제약 없이 모든 State를 사용할 수 있습니다
- **Native NavigationStack**: iOS 16+의 최신 API를 직접 활용합니다
- **성능 최적화**: 불필요한 업데이트를 방지하는 최적화가 적용되어 있습니다

## 📚 참고 자료

- [TCAFlow 메인 프로젝트](../../README.md)
- [TCA 공식 문서](https://github.com/pointfreeco/swift-composable-architecture)
- [Apple NavigationStack 문서](https://developer.apple.com/documentation/swiftui/navigationstack)

---

**TCAFlow**로 더 나은 iOS 앱을 만들어보세요! 🚀