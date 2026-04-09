import ComposableArchitecture
import SwiftUI
import TCAFlow

@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case profile(ProfileCoordinator)
    case single(SingleViewFeature)
    case counter(CounterFeature)
    case summary(SummaryFeature)
    case settings(SettingsFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(let routeAction):
        switch routeAction {
        case .pathChanged(let path):
          let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
          while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
            state.routes.pop()
          }

        case .routeAction(let id, let screenAction):
        switch screenAction {
        case .home(.pushOneViewButtonTapped):
            state.routes.push(.single(.init()))

        case .home(.profileCoordinatorButtonTapped):
            state.routes.push(.profile(.init()))

        case .home(.startFlowButtonTapped):
          state.routes.push(
            .counter(
              CounterFeature.State(
                session: DemoSession(name: "Onboarding"),
                count: 1
              )
            )
          )

        case .home(.settingsButtonTapped):
          state.routes.goTo(.settings(SettingsFeature.State()))

        case .counter(.summaryButtonTapped):
          if let route = state.routes.routes[id: id],
             case .counter(let counterState) = route.state {
            state.routes.push(
              .summary(
                SummaryFeature.State(
                  sessionName: counterState.session.name,
                  finalCount: counterState.count
                )
              )
            )
          }

        case .counter(.backToRootButtonTapped):
          state.routes.popToRoot()

        case .summary(.settingsButtonTapped):
            state.routes.goTo(.settings(.init()))

        case .summary(.backButtonTapped):
          state.routes.pop()

        case .summary(.restartButtonTapped):
          state.routes.popToRoot()

        case .settings(.backButtonTapped):
          state.routes.pop()

        case .single(.closeButtonTapped):
          state.routes.pop()

        case .counter(.incrementButtonTapped):
          if case .counter(var childState) = state.routes.routes[id: id]?.state {
            childState.count += 1
            state.routes.routes[id: id]?.state = .counter(childState)
          }

        case .counter(.decrementButtonTapped):
          if case .counter(var childState) = state.routes.routes[id: id]?.state {
            childState.count -= 1
            state.routes.routes[id: id]?.state = .counter(childState)
          }

        case .settings(.binding(let bindingAction)):
          if let isEnabled = BindingAction<SettingsFeature.State>.allCasePaths.isNotificationsEnabled
            .extract(from: bindingAction),
            case .settings(var childState) = state.routes.routes[id: id]?.state {
            childState.isNotificationsEnabled = isEnabled
            state.routes.routes[id: id]?.state = .settings(childState)
          }

        case .profile(let profileAction):
          if case .profile(var childState) = state.routes.routes[id: id]?.state {
            Self.reduceProfileCoordinator(state: &childState, action: profileAction)
            state.routes.routes[id: id]?.state = .profile(childState)
          }
          }
        }

        return .none
      }
    }
  }
}

final class DemoSession: Equatable, Sendable {
  let name: String

  init(name: String) {
    self.name = name
  }

  static func == (lhs: DemoSession, rhs: DemoSession) -> Bool {
    lhs === rhs || lhs.name == rhs.name
  }
}

@NestedCoordinatorExtension
private extension AppCoordinator {
  static func reduceProfileCoordinator(
    state: inout ProfileCoordinator.State,
    action: ProfileCoordinator.Action
  ) {
    switch action {
    case .route(let routeAction):
      switch routeAction {
      case .pathChanged(let path):
        let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
        while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
          state.routes.pop()
        }

      case .routeAction(_, let screenAction):
        switch screenAction {
        case .profileHome(.detailButtonTapped):
          state.routes.push(.profileDetail(.init()))

        case .profileDetail(.closeButtonTapped):
          state.routes.pop()
        }
      }
    }
  }
}

struct AppCoordinatorView: View {
  @SwiftUI.Bindable var store: StoreOf<AppCoordinator>

  init(store: StoreOf<AppCoordinator>) {
    self.store = store
  }

  var body: some View {
    TCARouter(
      self.store.scope(
        state: \.routes,
        action: \.route
      )
    ) { screen in
      switch screen.case {
      case .home(let homeStore):
        HomeView(store: homeStore)
          .navigationTitle("TCAFlow")

      case .profile(let profileStore):
        ProfileCoordinatorView(store: profileStore)
          .navigationTitle("Profile")

      case .single(let singleStore):
        SingleView(store: singleStore)
          .navigationTitle("One View")

      case .counter(let counterStore):
        CounterView(store: counterStore)
          .navigationTitle("Counter")

      case .summary(let summaryStore):
        SummaryView(store: summaryStore)
          .navigationTitle("Summary")

      case .settings(let settingsStore):
        SettingsView(store: settingsStore)
          .navigationTitle("Settings")
      }
    }
  }
}
