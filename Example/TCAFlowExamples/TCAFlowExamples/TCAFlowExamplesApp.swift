import SwiftUI
import ComposableArchitecture
import TCAFlow

@main
struct TCAFlowExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State private var store = Store(initialState: MainTabCoordinator.State()) {
    MainTabCoordinator()
  }

  var body: some View {
    MainTabView(store: store)
  }
}
