import ComposableArchitecture
import SwiftUI
import TCAFlow

struct ShowcaseCoordinatorView: View {
  @Bindable var store: StoreOf<ShowcaseCoordinator>

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case .menu(let store):
        ShowcaseMenuView(store: store)
      case .guardedScreen(let store):
        GuardedScreenView(store: store)
      case .guardRejected(let store):
        GuardRejectedView(store: store)
      case .animatedScreen(let store):
        AnimatedScreenView(store: store)
      }
    }
  }
}
