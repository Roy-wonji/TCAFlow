import ComposableArchitecture
import SwiftUI
import TCAFlow

struct NestedCoordinatorView: View {
  @Bindable var store: StoreOf<NestedCoordinator>
  @GestureState private var dragOffset: CGFloat = 0

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .step1(let store):
          NestedStep1View(store: store)
        case .step2(let store):
          NestedStep2View(store: store)
      }
    }
    .offset(x: dragOffset)
    .simultaneousGesture(
      DragGesture(minimumDistance: 20, coordinateSpace: .global)
        .updating($dragOffset) { value, state, _ in
          if value.startLocation.x < 30 && value.translation.width > 0 {
            state = value.translation.width
          }
        }
        .onEnded { value in
          if value.startLocation.x < 30 && value.translation.width > 100 {
            store.send(.backToMain)
          }
        }
    )
  }
}
