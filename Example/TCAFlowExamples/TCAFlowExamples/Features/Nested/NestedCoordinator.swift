import ComposableArchitecture
import TCAFlow

// MARK: - NestedCoordinator (@FlowCoordinator + 추가 Action)

struct NestedCoordinator: Reducer {}

@FlowCoordinator(navigation: true)
extension NestedCoordinator {
  @Reducer
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

extension NestedCoordinator.NestedScreen.State: Equatable {}

// MARK: - Route Handling
// routeReducer를 작성하면 매크로가 body에서 .forEachRoute 자동 적용

extension NestedCoordinator {
  var routeReducer: some Reducer<State, Action> {
    Reduce { state, action in
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
}
