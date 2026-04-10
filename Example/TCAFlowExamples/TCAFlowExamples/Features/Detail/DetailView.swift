import ComposableArchitecture
import SwiftUI

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
