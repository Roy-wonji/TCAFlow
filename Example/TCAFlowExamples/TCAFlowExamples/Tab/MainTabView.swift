import ComposableArchitecture
import SwiftUI
import TCAFlow

struct MainTabView: View {
  @Bindable var store: StoreOf<MainTabCoordinator>

  var body: some View {
    TCAFlowTabRouter(
      selectedTab: $store.selectedTab.sending(\.selectTab),
      tabs: [
        TabItem(title: "Demo", icon: "house", tag: 0),
        TabItem(title: "Showcase", icon: "sparkles", tag: 1)
      ],
      onReselect: { tab in
        store.send(.tabReselected(tab))
      }
    ) { index in
      switch index {
      case 0:
        DemoCoordinatorView(store: store.scope(state: \.demoState, action: \.demo))
      case 1:
        ShowcaseCoordinatorView(store: store.scope(state: \.showcaseState, action: \.showcase))
      default:
        EmptyView()
      }
    }
  }
}
