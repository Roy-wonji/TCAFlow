import ComposableArchitecture
import SwiftUI

@Reducer
struct GuardedScreenFeature {
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

struct GuardedScreenView: View {
  let store: StoreOf<GuardedScreenFeature>

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "checkmark.shield.fill")
        .font(.system(size: 60))
        .foregroundColor(.green)

      Text("보호된 화면")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Route Guard가 허용하여\n이 화면에 접근할 수 있습니다.")
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button("Go Back") { store.send(.goBack) }
        .buttonStyle(.borderedProminent)
    }
    .padding()
    .navigationTitle("Guarded")
  }
}
