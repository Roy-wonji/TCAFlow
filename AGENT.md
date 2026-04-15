# TCAFlow Agent Guide

**TCAFlow는 Swift 6 호환 TCA용 Coordinator-style Navigation 라이브러리입니다.**

## 🎯 프로젝트 목적

- TCACoordinators와 동일한 API 제공하면서 **Hashable 제약 제거**
- iOS 16+의 네이티브 NavigationStack 활용
- @FlowCoordinator 매크로로 보일러플레이트 코드 자동 생성
- 안전하고 성능 최적화된 Navigation 솔루션 제공

## 📁 프로젝트 구조

```
TCAFlow/
├── Sources/TCAFlow/
│   ├── Core/
│   │   ├── TCARouter.swift           # 핵심 라우터 구현
│   │   ├── TCAFlow.swift            # Route 정의 및 확장
│   │   ├── ForEachRoute.swift       # Route 처리 Reducer
│   │   └── FlowCoordinatorMacro.swift # 매크로 정의
│   ├── Middleware/
│   │   ├── RouteLogger.swift        # 디버깅용 로거
│   │   └── RouteGuard.swift         # Navigation 가드
│   ├── DeepLink/
│   │   └── DeepLink.swift           # 딥링크 처리
│   ├── Tab/
│   │   └── TCAFlowTabRouter.swift   # 탭 기반 라우터
│   ├── Animation/
│   │   └── RouteAnimation.swift     # 전환 애니메이션
│   └── Persistence/
│       └── RoutePersistence.swift   # Route 상태 저장/복원
├── Sources/TCAFlowMacros/
│   ├── Plugin.swift                 # Swift Package Manager 플러그인
│   └── FlowCoordinatorMacro.swift   # 매크로 구현
├── Example/TCAFlowExamples/         # 예제 프로젝트
├── Tests/                           # 테스트 코드
└── docs/                           # 문서

```

## 🔧 핵심 컴포넌트

### 1. TCARouter.swift
- **TCAFlowRouter**: 메인 라우터 뷰
- **_NavStackHost**: NavigationStack을 관리하는 호스트
- **_InlineRouteChain**: 중첩 코디네이터용 인라인 체인
- **SafeNavigationDestinationModifier**: NavigationDestination 안전 사용을 위한 modifier

### 2. TCAFlow.swift  
- **Route**: Push, Sheet, Cover 등 네비게이션 타입 정의
- **RouteArray Extensions**: goTo, push, pop 등 편의 메소드
- **SheetConfiguration**: Sheet detent 설정

### 3. @FlowCoordinator 매크로
- State, Action, body 자동 생성
- 보일러플레이트 코드 95% 감소
- handleRoute 메소드만 구현하면 됨

## 🛠️ 개발 가이드라인

### ✅ DO
- NavigationDestination 사용 시 항상 SafeNavigationDestinationModifier 사용
- Effect에는 고유한 CancelID 부여
- State 전환 시 관련 Effect들 명시적 취소
- @FlowCoordinator 매크로 적극 활용
- 중첩 Coordinator에서는 _InlineRouteChain 활용

### ❌ DON'T
- NavigationStack 밖에서 직접 navigationDestination 사용 금지
- Hashable 제약 추가 금지 (Equatable만 사용)
- Effect 취소 없이 State 전환 금지
- 매크로 없이 수동 보일러플레이트 작성 지양

## 🚨 일반적인 문제 해결

### 1. NavigationDestination 경고
**문제**: `navigationDestination` modifier가 NavigationStack 밖에서 사용됨

**해결**: SafeNavigationDestinationModifier 사용
```swift
.modifier(SafeNavigationDestinationModifier(
    isPresented: binding,
    destination: { /* destination view */ }
))
```

### 2. ifCaseLet Action 불일치
**문제**: State는 auth인데 staff action이 들어옴

**해결**: State 전환 시 Effect 취소
```swift
case .logout:
    return .concatenate(
        .cancel(id: CancelID.allStaffEffects),
        .run { send in await send(.setAuthState(.login(.init()))) }
    )
```

### 3. 중첩 Coordinator 문제
**문제**: 중첩 상황에서 Navigation이 제대로 되지 않음

**해결**: 
- 부모에서 `embedInNavigationView: true` 설정
- 자식에서는 _InlineRouteChain 사용
- 환경변수 `_isInsideNavStack` 올바르게 전파

## 📋 테스트 가이드

### UI 테스트
1. 기본 Push/Pop 동작
2. Sheet/Cover 표시/닫기
3. goTo/goBackTo 메소드
4. 중첩 Coordinator 동작
5. DeepLink 처리

### Performance 테스트
1. 대량 Route 처리
2. 빠른 연속 Navigation
3. 메모리 누수 확인
4. SwiftUI Preview 성능

## 🎨 매크로 사용법

```swift
@FlowCoordinator(screen: "Screen", navigation: true)
struct MyCoordinator {
    func handleRoute(state: inout State, action: Action) -> Effect<Action> {
        // 라우팅 로직만 작성
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

## 🔄 Migration from TCACoordinators

1. Import 변경: `TCACoordinators` → `TCAFlow`
2. Router 변경: `TCARouter` → `TCAFlowRouter`  
3. Hashable 제거: Screen State에서 Hashable 삭제
4. @FlowCoordinator 매크로 적용

## 🐛 디버깅 도구

### RouteLogger 사용
```swift
var body: some Reducer<State, Action> {
    Reduce { state, action in
        handleRoute(state: &state, action: action)
    }
    .forEachRoute(\.routes, action: \.router)
    .routeLogging(level: .verbose, prefix: "🏠 [App]")
}
```

### RouteGuard 사용
```swift
struct AuthGuard: RouteGuard {
    func canNavigate<Screen>(
        from currentRoutes: [Route<Screen>],
        to newRoutes: [Route<Screen>]
    ) -> RouteGuardResult {
        return isAuthenticated ? .allow : .reject(reason: "로그인 필요")
    }
}
```

## 📚 참고 자료

- [README.md](README.md) - 사용법 및 예제
- [Example/TCAFlowExamples](Example/TCAFlowExamples/) - 완전한 예제 프로젝트
- [TCA 공식 문서](https://github.com/pointfreeco/swift-composable-architecture)
- [TCACoordinators](https://github.com/johnpatrickmorgan/TCACoordinators) - 원본 라이브러리

## 🤝 기여할 때

1. 새로운 기능 추가 시 예제 프로젝트에도 데모 추가
2. 매크로 변경 시 컴파일 타임 성능 고려
3. NavigationDestination 관련 변경 시 안전성 우선 고려
4. 모든 변경사항에 대해 unit test 및 UI test 추가
5. 한국어 커밋 메시지 사용 (프로젝트 컨벤션)

## 🚀 성능 고려사항

- Route 배열 크기 최적화 (불필요한 히스토리 제거)
- SwiftUI Preview에서 대량 Route 처리 주의
- Effect 누적 방지를 위한 적절한 취소 로직
- 매크로 컴파일 타임 최적화

---

**TCAFlow Agent Guide v1.1.1**  
**Last Updated**: 2026-04-15