import ComposableArchitecture
import SwiftUI

@Reducer
struct GuardRejectedFeature {
  @ObservableState
  struct State: Equatable {
    var reason: String
    init(reason: String = "") {
      self.reason = reason
    }
  }

  @CasePathable
  enum Action {
    case goBack
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct GuardRejectedView: View {
  let store: StoreOf<GuardRejectedFeature>

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "xmark.shield.fill")
        .font(.system(size: 60))
        .foregroundColor(.red)

      Text("접근 거부")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text(store.reason)
        .font(.body)
        .foregroundColor(.secondary)

      Text("Route Guard가 이 네비게이션을\n차단했습니다.")
        .font(.caption)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button("Go Back") { store.send(.goBack) }
        .buttonStyle(.borderedProminent)
        .tint(.red)
    }
    .padding()
    .navigationTitle("Rejected")
  }
}
