import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case startFlow
    case pushOneView
    case openNestedCoordinator
    case jumpToSettings
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 16) {
        Text("TCAFlow")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top, 20)

        Text("TCACoordinators 스타일의\ncoordinator 예제")
          .font(.title3)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)

        Text("Hashable 없이 route state를 쓰고, coordinator에서\n직접 push / goTo / popToRoot를 제어합니다.")
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 20)
      }

      VStack(spacing: 16) {
        Button("Start Flow") { store.send(.startFlow) }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)

        Button("Push One View") { store.send(.pushOneView) }
          .buttonStyle(.bordered)
          .controlSize(.large)

        Button("Open Nested Coordinator") { store.send(.openNestedCoordinator) }
          .buttonStyle(.bordered)
          .controlSize(.large)

        Button("Jump To Settings") { store.send(.jumpToSettings) }
          .buttonStyle(.bordered)
          .controlSize(.large)
      }
      .padding(.horizontal, 20)

      Spacer()
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
  }
}
