# TCAFlow Documentation

TCAFlow는 TCA 1.25+의 `@Reducer`, `@ObservableState`, `Store.scope(state:action:)` key-path API에 맞춘 coordinator-style navigation helper입니다.

핵심 목표는 TCACoordinators처럼 route stack을 reducer state로 관리하되, 화면 state에 `Hashable`을 강제하지 않고 `Equatable`만 요구하는 것입니다.

## 문서

- [Getting Started](GettingStarted.md): 설치, coordinator 작성, router 연결
- [API Reference](APIReference.md): `Route`, `RouteStack`, `FlowAction`, `TCARouter`
- [FlowCoordinator Macro](FlowCoordinatorMacro.md): `@FlowCoordinator`가 생성하는 코드와 사용 규칙
- [Example App](ExampleApp.md): example iOS 앱 구조와 실행 방법

## 최소 요구사항

- Swift 6.0+
- TCA 1.25.5+
- iOS 16.0+
- macOS 13.0+
- watchOS 9.0+
- tvOS 16.0+

## 빠른 예시

```swift
import ComposableArchitecture
import SwiftUI
import TCAFlow

@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.element(.element(_, .home(.detailButtonTapped)))):
        state.routes.push(.detail(DetailFeature.State()))
        return .none

      case .route(.element(.element(_, .detail(.closeButtonTapped)))):
        _ = state.routes.pop()
        return .none

      case .route:
        return .none
      }
    }
  }
}

struct AppCoordinatorView: View {
  @SwiftUI.Bindable var store: StoreOf<AppCoordinator>

  var body: some View {
    TCARouter(
      self.store.scope(state: \.routes, action: \.route)
    ) { screen in
      switch screen.case {
      case .home(let store):
        HomeView(store: store)

      case .detail(let store):
        DetailView(store: store)
      }
    }
  }
}
```
