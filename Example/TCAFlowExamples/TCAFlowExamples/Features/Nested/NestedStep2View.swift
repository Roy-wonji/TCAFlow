import ComposableArchitecture
import SwiftUI

struct NestedStep2View: View {
  @Bindable var store: StoreOf<NestedStep2Feature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Nested Step 2")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("중첩된 Coordinator의\n두 번째 단계입니다")
        .font(.body)
        .multilineTextAlignment(.center)

      VStack(spacing: 16) {
        Button("Go Back") { store.send(.goBack) }
          .buttonStyle(.bordered)

        Button("Finish & Back to Main") { store.send(.finish) }
          .buttonStyle(.borderedProminent)
      }

      Spacer()
    }
    .padding()
    .navigationTitle("Nested Step 2")
  }
}
