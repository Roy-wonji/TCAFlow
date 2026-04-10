import ComposableArchitecture
import SwiftUI

@Reducer
struct DetailFeature {
  @ObservableState
  struct State: Equatable {
    var title: String
    var message: String

    init(title: String = "Detail", message: String = "Detail 화면입니다") {
      self.title = title
      self.message = message
    }
  }

  @CasePathable
  enum Action {
    case goBack
    case goToRoot
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct DetailView: View {
  @Bindable var store: StoreOf<DetailFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text(store.title)
        .font(.largeTitle)
        .fontWeight(.bold)

      Text(store.message)
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      VStack(spacing: 16) {
        Button("Go Back") { store.send(.goBack) }
          .buttonStyle(.borderedProminent)

        Button("Go To Root") { store.send(.goToRoot) }
          .buttonStyle(.bordered)
      }

      Spacer()
    }
    .padding()
    .navigationTitle(store.title)
  }
}
