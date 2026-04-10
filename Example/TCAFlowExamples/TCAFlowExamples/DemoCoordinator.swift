import ComposableArchitecture
import SwiftUI
import TCAFlow

// MARK: - Demo Coordinator

@Reducer
struct DemoCoordinator {
  @ObservableState
  struct State: Equatable {
    var routes: [Route<DemoScreen.State>]

    init() {
      self.routes = [.root(.home(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<DemoScreen>)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        case .router(let routeAction):
          return handleRouterAction(state: &state, action: routeAction)
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }

  private func handleRouterAction(
    state: inout State,
    action: IndexedRouterActionOf<DemoScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(_, .home(.startFlow)):
        state.routes.push(.flow(.init()))
        return .none

      case .routeAction(_, .home(.pushOneView)):
        state.routes.push(.detail(.init(title: "Push된 화면", message: "간단한 Push 테스트입니다")))
        return .none

      case .routeAction(_, .home(.openNestedCoordinator)):
        state.routes.push(.nested(.init()))
        return .none

      case .routeAction(_, .home(.jumpToSettings)):
        state.routes.push(.settings(.init()))
        return .none

      case .routeAction(_, .flow(.nextStep)):
        state.routes.push(.detail(.init(title: "Flow Step 2", message: "다음 단계로 이동했습니다")))
        return .none

      case .routeAction(_, .detail(.goBack)):
        state.routes.goBack()
        return .none

      case .routeAction(_, .detail(.goToRoot)):
        state.routes.goBackToRoot()
        return .none

      case .routeAction(_, .settings(.goBack)):
        state.routes.goBack()
        return .none

      case .routeAction(_, .nested(.backToMain)):
        state.routes.goBackToRoot()
        return .none

      default:
        return .none
    }
  }
}

extension DemoCoordinator {
  @Reducer
  enum DemoScreen {
    case home(HomeFeature)
    case flow(FlowFeature)
    case detail(DetailFeature)
    case settings(SettingsFeature)
    case nested(NestedCoordinator)
  }
}

extension DemoCoordinator.DemoScreen.State: Equatable {}

// MARK: - DemoCoordinatorView

struct DemoCoordinatorView: View {
  @Bindable var store: StoreOf<DemoCoordinator>

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .home(let store):
          HomeView(store: store)
        case .flow(let store):
          FlowView(store: store)
        case .detail(let store):
          DetailView(store: store)
        case .settings(let store):
          SettingsView(store: store)
        case .nested(let store):
          NestedCoordinatorView(store: store)
      }
    }
  }
}
