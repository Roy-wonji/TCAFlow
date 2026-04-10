import ComposableArchitecture
import TCAFlow

// MARK: - NestedCoordinator (body 직접 작성 예제)

@FlowCoordinator(screen: "NestedScreen", navigation: true)
struct NestedCoordinator {
  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<NestedScreen>)
    case backToMain
  }

  // body 직접 작성 → 매크로가 body 생성 건너뜀
  var body: some Reducer<State, Action> {
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
    .forEachRoute(\.routes, action: \.router)
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
