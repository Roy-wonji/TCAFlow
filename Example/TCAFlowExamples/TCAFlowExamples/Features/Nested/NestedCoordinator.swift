import ComposableArchitecture
import TCAFlow

@FlowCoordinator(screen: "NestedScreen", navigation: true)
struct NestedCoordinator {
  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<NestedScreen>)
    case backToMain
  }
}

extension NestedCoordinator {
  @Reducer
  enum NestedScreen {
    case step1(NestedStep1Feature)
    case step2(NestedStep2Feature)
  }
}

extension NestedCoordinator.NestedScreen.State: Equatable {}

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
