import ComposableArchitecture
import SwiftUI

@Reducer
struct SummaryFeature: Sendable {

  @ObservableState
  struct State: Equatable {
    var sessionName: String
    var finalCount: Int
  }

  enum Action {
    case backButtonTapped
    case settingsButtonTapped
    case restartButtonTapped
  }

  var body: some Reducer<State, Action> {
    Reduce { _, _ in .none }
  }
}

struct SummaryView: View {
  @SwiftUI.Bindable var store: StoreOf<SummaryFeature>

  var body: some View {

    VStack(alignment: .leading, spacing: 18) {
      Text("Flow Complete")
        .font(.largeTitle.bold())

      Text("Session: \(store.sessionName)")
      Text("Final Count: \(store.finalCount)")
        .font(.title3.weight(.semibold))

      Button("Go To Settings") {
        store.send(.settingsButtonTapped)
      }
      .buttonStyle(.borderedProminent)

      Button("Back") {
        store.send(.backButtonTapped)
      }
      .buttonStyle(.bordered)

      Button("Restart From Root") {
        store.send(.restartButtonTapped)
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(.systemBackground))
  }
}
