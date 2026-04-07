import ComposableArchitecture
import SwiftUI

@Reducer
struct SingleViewFeature: Sendable {
    @ObservableState
    struct State: Equatable {
        var title = "One View"
        var message = "TCARouter로 홈에서 화면 하나만 push 된 상태입니다."
    }

    enum Action {
        case closeButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}

struct SingleView: View {
    @SwiftUI.Bindable var store: StoreOf<SingleViewFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(self.store.title)
                .font(.largeTitle.bold())

            Text("홈에서 화면 하나만 push 하는 가장 단순한 라우팅 예제입니다.")
                .foregroundStyle(.secondary)

            Text(self.store.message)
                .font(.callout)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Back") {
                self.store.send(.closeButtonTapped)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }
}
