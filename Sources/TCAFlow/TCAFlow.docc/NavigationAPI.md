# Navigation API

TCAFlow가 제공하는 navigation 메서드들을 알아봅니다.

## Overview

모든 navigation은 `state.routes` 배열을 조작하여 수행합니다. TCAFlow는 `[Route<Screen>]`에 대한 확장 메서드를 제공합니다.

## Push / Pop

화면을 NavigationStack에 push하거나 pop합니다.

```swift
// Push
state.routes.push(.detail(.init()))

// Pop (뒤로 가기)
state.routes.goBack()           // 1단계
state.routes.goBack(2)          // 2단계
state.routes.goBackToRoot()     // root까지

// Stack에서만 Pop (presented 화면 유지)
state.routes.pop()              // push된 화면만 pop
state.routes.popToRoot()        // push된 화면 모두 pop
```

### push vs goBack 차이

- `push` — 새 화면을 스택에 추가
- `goBack` — 마지막 화면을 스택에서 제거 (push/sheet/cover 무관)
- `pop` — push된 화면만 제거 (sheet/cover는 유지)

## Sheet / FullScreenCover

모달로 화면을 표시합니다.

```swift
// Sheet
state.routes.presentSheet(.settings(.init()))
state.routes.presentSheet(.profile(.init()), embedInNavigationView: true)

// FullScreenCover (iOS/tvOS/watchOS만 지원)
state.routes.presentCover(.onboarding(.init()))
state.routes.presentCover(.onboarding(.init()), embedInNavigationView: true)

// Dismiss
state.routes.dismiss()          // 최상단 presented 화면
state.routes.dismiss(2)         // 2개
state.routes.dismissAll()       // 모두
```

### embedInNavigationView

`embedInNavigationView: true`로 설정하면 Router가 navigation 소유권을 자동 판단합니다. 부모 TCAFlow navigation이 있으면 상속하고, 없으면 UIKitNavigation의 독립적인 `NavigationStackController`를 생성합니다. `false`이면 navigation container를 만들지 않습니다.

## 특정 화면으로 이동

### goBackTo — 기존 화면으로 돌아가기

스택에서 특정 화면을 찾아 그 위치까지 pop합니다.

```swift
// CaseKeyPath로 이동
state.routes.goBackTo(\.home)
state.routes.goBackTo(\.profile)

// 조건으로 이동
state.routes.goBackTo { route in
    route.screen == .home(.init())
}
```

### goTo — 스마트 이동

스택에 해당 화면이 있으면 거기까지 pop, 없으면 새로 push합니다.

```swift
// 화면 인스턴스로 이동
state.routes.goTo(.settings(.init()))
state.routes.goTo(.detail(.init(title: "제목")))

// CaseKeyPath로 이동 (기존 화면 찾기만)
state.routes.goTo(\.home)
```

> Note: `goTo`에 화면 인스턴스를 전달하면 없을 때 새로 생성합니다.
> `CaseKeyPath`를 전달하면 기존 화면만 찾고, 없으면 아무것도 하지 않습니다.

## Route 타입

```swift
@CasePathable
public enum Route<Screen> {
    case root(Screen, embedInNavigationView: Bool = true)
    case push(Screen)
    case sheet(Screen, embedInNavigationView: Bool = false)
    case cover(Screen, embedInNavigationView: Bool = false)
}
```

### 프로퍼티

| 프로퍼티 | 설명 |
|---------|------|
| `screen` | 화면 데이터 (get/set) |
| `embedInNavigationView` | navigation container 자동 구성 여부 |
| `isPresented` | sheet/cover 여부 |
| `isPush` | push 여부 |
| `isSheet` | sheet 여부 |
| `isCover` | cover 여부 |

## 뒤로가기 버튼 숨기기와 스와이프 유지

iOS에서 push된 화면에 `swipeBackButtonHidden()`을 적용하면 기본 뒤로가기
버튼을 숨기면서 화면 가장자리 스와이프로 뒤로 갈 수 있습니다.

```swift
DetailView(store: store)
    .swipeBackButtonHidden()
```

`false`를 전달하면 기본 뒤로가기 버튼과 기존 제스처 설정을 복원합니다.
해당 화면을 감싸는 navigation controller를 사용하며 루트 화면과 화면 전환
중에는 스와이프 시작을 차단합니다. 화면이 보이는 동안 가장자리 스와이프의
delegate를 임시로 교체하므로 같은 제스처에 별도 delegate를 설정하지 마세요.
