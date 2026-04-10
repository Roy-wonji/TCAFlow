import ComposableArchitecture
import SwiftUI
import TCAFlow

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
