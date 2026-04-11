import ComposableArchitecture
import SwiftUI
import TCAFlow

@Reducer
struct AnimatedScreenFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case goBack
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct AnimatedScreenView: View {
  let store: StoreOf<AnimatedScreenFeature>

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "sparkles")
        .font(.system(size: 60))
        .foregroundColor(.purple)

      Text("Animated Sheet")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("SheetConfiguration: .halfAndFull\n드래그하여 크기를 조절하세요!")
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      VStack(alignment: .leading, spacing: 8) {
        Label("detents: [.medium, .large]", systemImage: "arrow.up.and.down")
        Label("showDragIndicator: true", systemImage: "hand.draw")
        Label("routeTransition(.fade())", systemImage: "wand.and.stars")
      }
      .font(.caption)
      .foregroundColor(.secondary)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(UIColor.systemGray6))
      )

      Button("Dismiss") { store.send(.goBack) }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
    }
    .padding()
    .routeTransition(.fade())
  }
}
