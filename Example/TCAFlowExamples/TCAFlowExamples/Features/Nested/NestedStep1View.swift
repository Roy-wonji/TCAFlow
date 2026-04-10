import ComposableArchitecture
import SwiftUI

struct NestedStep1View: View {
  @Bindable var store: StoreOf<NestedStep1Feature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Nested Step 1")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 중첩된 Coordinator의\n첫 번째 단계입니다")
        .font(.body)
        .multilineTextAlignment(.center)

      VStack(spacing: 16) {
        Button("Next Step") { store.send(.nextStep) }
          .buttonStyle(.borderedProminent)

        Button("Back to Main") { store.send(.backToMain) }
          .buttonStyle(.bordered)
      }

      Spacer()
    }
    .padding()
    .navigationTitle("Nested Step 1")
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          store.send(.backToMain)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
            Text("Back")
          }
        }
      }
    }
  }
}
