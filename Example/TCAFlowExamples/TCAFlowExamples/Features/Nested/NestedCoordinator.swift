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

extension NestedCoordinator {
  func handleRoute(
    state: inout State,
    action: IndexedRouterActionOf<NestedScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(_, .step1(.nextStep)):
        state.routes.push(.step2(.init()))
        return .none

      case .routeAction(_, .step1(.backToMain)):
        return .send(.backToMain)

      case .routeAction(_, .step2(.goBack)):
        state.routes.goBack()
        return .none

      case .routeAction(_, .step2(.finish)):
        return .send(.backToMain)

      default:
        return .none
    }
  }
}
