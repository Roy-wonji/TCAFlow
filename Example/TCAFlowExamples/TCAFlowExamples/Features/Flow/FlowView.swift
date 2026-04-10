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

      // goTo 예제 섹션
      VStack(spacing: 16) {
        Text("🎯 goTo 이동")
          .font(.headline)
          .fontWeight(.semibold)

        VStack(spacing: 12) {
          Button("이전 홈으로 돌아가기") {
            store.send(.goToHomeDirectly)
          }
          .buttonStyle(.bordered)

          Button("Detail로 이동") {
            store.send(.goToDetailSmartly)
          }
          .buttonStyle(.bordered)
        }

        Text("스마트 이동: 있으면 바로 이동, 없으면 새로 생성")
          .font(.caption)
          .foregroundColor(.blue)
          .multilineTextAlignment(.center)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(UIColor.systemGray6))
      )
      .padding(.horizontal, 20)

      Spacer()
    }
    .padding()
    .navigationTitle("Flow")
  }
}
