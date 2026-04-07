import ComposableArchitecture
import SwiftUI

@Reducer
struct CounterFeature: Sendable {
    @ObservableState
    struct State: Equatable {
        var session: DemoSession
        var count: Int
    }

    enum Action {
        case decrementButtonTapped
        case incrementButtonTapped
        case summaryButtonTapped
        case backToRootButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                return .none

            case .incrementButtonTapped:
                state.count += 1
                return .none

            case .summaryButtonTapped, .backToRootButtonTapped:
                return .none
            }
        }
    }
}

struct CounterView: View {
    @SwiftUI.Bindable var store: StoreOf<CounterFeature>

    var body: some View {
        VStack(spacing: 24) {
            Text(self.store.session.name)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("\(self.store.count)")
                .font(.system(size: 64, weight: .bold, design: .rounded))

            HStack(spacing: 16) {
                Button("-1") {
                    self.store.send(.decrementButtonTapped)
                }
                .buttonStyle(.bordered)

                Button("+1") {
                    self.store.send(.incrementButtonTapped)
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Show Summary") {
                self.store.send(.summaryButtonTapped)
            }
            .buttonStyle(.borderedProminent)

            Button("Pop To Root") {
                self.store.send(.backToRootButtonTapped)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }
}
