import ComposableArchitecture
import SwiftUI

@Reducer
struct ProfileHomeFeature: Sendable {
  @ObservableState
  struct State: Equatable {}

  enum Action {
    case detailButtonTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct ProfileHomeView: View {
  @SwiftUI.Bindable var store: StoreOf<ProfileHomeFeature>

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Nested Coordinator")
        .font(.largeTitle.bold())

      Text("이 화면은 `@FlowCoordinator(navigation: true)` 인 child coordinator의 root입니다.")
        .foregroundStyle(.secondary)

      Text("child coordinator가 자기 NavigationStack을 가지는 케이스를 example으로 보여줍니다.")
        .font(.callout)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))

      Button("Push Profile Detail") {
        self.store.send(.detailButtonTapped)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(.systemBackground))
  }
}
