import ComposableArchitecture
import SwiftUI

// MARK: - Web Feature

@Reducer
public struct WebFeature {
    @ObservableState
    public struct State: Equatable {
        let url: String

        public init(url: String = "") {
            self.url = url
        }
    }

    @CasePathable
    public enum Action {
        case backToRoot
    }

    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

// MARK: - Web View

public struct WebView: View {
    @Bindable var store: StoreOf<WebFeature>

    public var body: some View {
        VStack(spacing: 20) {
            Text("Web View")
                .font(.largeTitle)
                .bold()

            Text("URL: \(store.url)")
                .font(.caption)
                .foregroundColor(.gray)

            Button("Back") {
                store.send(.backToRoot)
            }
        }
        .padding()
    }
}