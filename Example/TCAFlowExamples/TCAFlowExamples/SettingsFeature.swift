import ComposableArchitecture
import SwiftUI

@Reducer
struct SettingsFeature {
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

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Settings")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 Settings 화면입니다.\npush로 이동했습니다!")
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      Button("Go Back") { store.send(.goBack) }
        .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding()
    .navigationTitle("Settings")
  }
}
