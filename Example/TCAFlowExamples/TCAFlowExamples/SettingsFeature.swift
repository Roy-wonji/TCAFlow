import ComposableArchitecture
import SwiftUI

@Reducer
struct SettingsFeature: Sendable {
    @ObservableState
    struct State: Equatable {
        var isNotificationsEnabled = true
    }

    enum Action: BindableAction {
        case backButtonTapped
        case binding(BindingAction<State>)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .backButtonTapped:
                return .none

            case .binding:
                return .none
            }
        }
    }
}

struct SettingsView: View {
    @SwiftUI.Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            Toggle(
                "Enable notifications",
                isOn: $store.isNotificationsEnabled
            )

            Button("Back") {
                self.store.send(.backButtonTapped)
            }
        }
    }
}
