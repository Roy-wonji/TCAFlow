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

  // body 직접 작성 → 매크로가 body 생성 건너뜀 (backToMain 처리 필요)
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .router(let routeAction):
        return self.handleRoute(state: &state, action: routeAction)
      case .backToMain:
        return .none
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }
}

extension NestedCoordinator.NestedScreen.State: Equatable {}

// MARK: - Route Handling
// body는 매크로가 생성 → .forEachRoute 자동 적용
// handleRoute에서 모든 Action을 처리 (추가 action 포함)

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
        return .none  // 상위 coordinator에서 처리

      default:
        return .none
    }
  }
}
