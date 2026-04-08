import ComposableArchitecture
import SwiftUI

@Reducer
struct ProfileDetailFeature: Sendable {
  @ObservableState
  struct State: Equatable {}

  enum Action {
    case closeButtonTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct ProfileDetailView: View {
  @SwiftUI.Bindable var store: StoreOf<ProfileDetailFeature>

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Profile Detail")
        .font(.largeTitle.bold())

      Text("nested coordinator 내부에서 push 된 detail 화면입니다.")
        .foregroundStyle(.secondary)

      Button("Back In Nested Coordinator") {
        self.store.send(.closeButtonTapped)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(.systemBackground))
  }
}
