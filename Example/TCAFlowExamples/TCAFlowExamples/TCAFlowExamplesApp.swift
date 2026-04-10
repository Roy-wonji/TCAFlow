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
  @State private var store = Store(initialState: DemoCoordinator.State()) {
    DemoCoordinator()
  }

  var body: some View {
    DemoCoordinatorView(store: store)
  }
}
