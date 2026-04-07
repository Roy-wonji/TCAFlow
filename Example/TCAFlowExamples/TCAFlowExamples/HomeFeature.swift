import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature: Sendable {
    @ObservableState
    struct State: Equatable {}

    enum Action {
        case pushOneViewButtonTapped
        case startFlowButtonTapped
        case settingsButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}

struct HomeView: View {
    @SwiftUI.Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TCACoordinators 스타일의 coordinator 예제")
                .font(.title2.bold())

            Text("Hashable 없이 route state를 쌓고, coordinator에서 직접 push / goTo / popToRoot를 제어합니다.")
                .foregroundStyle(.secondary)

            Button("Start Flow") {
                self.store.send(.startFlowButtonTapped)
            }
            .buttonStyle(.borderedProminent)

            Button("Push One View") {
                self.store.send(.pushOneViewButtonTapped)
            }
            .buttonStyle(.bordered)

            Button("Jump To Settings") {
                self.store.send(.settingsButtonTapped)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground))
    }
}
