import ComposableArchitecture
import TCAFlow

// MARK: - NestedCoordinator (struct에 @FlowCoordinator + Action 직접 작성)

@FlowCoordinator(navigation: true)
struct NestedCoordinator {
  @Reducer(state: .equatable)
  enum NestedScreen {
    case step1(NestedStep1Feature)
    case step2(NestedStep2Feature)
  }

  // Action 직접 작성 → 매크로가 Action 생성 건너뜀
  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<NestedScreen>)
    case backToMain
  }
}

// MARK: - Route Handling

extension NestedCoordinator {
  func handleRoute(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .router(.routeAction(_, .step1(.nextStep))):
      state.routes.push(.step2(.init()))
      return .none

    case .router(.routeAction(_, .step1(.backToMain))):
      return .send(.backToMain)

    case .router(.routeAction(_, .step2(.goBack))):
      state.routes.goBack()
      return .none

    case .router(.routeAction(_, .step2(.finish))):
      return .send(.backToMain)

    case .backToMain:
      return .none

    default:
      return .none
    }
  }
}
