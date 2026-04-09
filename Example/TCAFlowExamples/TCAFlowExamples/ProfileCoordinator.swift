import ComposableArchitecture
import SwiftUI
import TCAFlow

@FlowCoordinator(navigation: true)
@Reducer
struct ProfileCoordinator: Sendable {
  enum Screen {
    case profileHome(ProfileHomeFeature)
    case profileDetail(ProfileDetailFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(let routeAction):
        switch routeAction {
        case .pathChanged(let path):
          let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
          while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
            _ = state.routes.pop()
          }

        case .routeAction(_, let screenAction):
          switch screenAction {
          case .profileHome(.detailButtonTapped):
            state.routes.push(.profileDetail(ProfileDetailFeature.State()))

          case .profileDetail(.closeButtonTapped):
            _ = state.routes.pop()
          }
        }

        return .none
      }
    }
  }
}

struct ProfileCoordinatorView: View {
  @SwiftUI.Bindable var store: StoreOf<ProfileCoordinator>

  var body: some View {
    TCARouter(
      self.store.scope(state: \.routes, action: \.route)
    ) { screen in
      switch screen.case {
      case .profileHome(let store):
        ProfileHomeView(store: store)
          .navigationTitle("Profile Home")

      case .profileDetail(let store):
        ProfileDetailView(store: store)
          .navigationTitle("Profile Detail")
      }
    }
  }
}
