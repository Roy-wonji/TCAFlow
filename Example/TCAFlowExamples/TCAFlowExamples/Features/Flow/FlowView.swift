import ComposableArchitecture
import SwiftUI

struct FlowView: View {
  @Bindable var store: StoreOf<FlowFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Flow Started!")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 플로우의 첫 번째 단계입니다")
        .font(.body)
        .multilineTextAlignment(.center)

      Button("Next Step") { store.send(.nextStep) }
        .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding()
    .navigationTitle("Flow")
  }
}
