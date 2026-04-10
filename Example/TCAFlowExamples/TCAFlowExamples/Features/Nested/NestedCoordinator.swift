import ComposableArchitecture
import TCAFlow

@Reducer
struct NestedCoordinator {
  @ObservableState
  struct State: Equatable {
    var routes: [Route<NestedScreen.State>]

    init() {
      self.routes = [.root(.step1(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<NestedScreen>)
    case backToMain
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        case .router(let routeAction):
          return handleRouterAction(state: &state, action: routeAction)
        case .backToMain:
          return .none
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }

  private func handleRouterAction(
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

// MARK: - NestedScreen

extension NestedCoordinator {
  @Reducer
  enum NestedScreen {
    case step1(NestedStep1Feature)
    case step2(NestedStep2Feature)
  }
}

extension NestedCoordinator.NestedScreen.State: Equatable {}
