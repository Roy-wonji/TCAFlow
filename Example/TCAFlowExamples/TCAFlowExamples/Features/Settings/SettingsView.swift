import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Settings")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 Settings 화면입니다.\npush로 이동했습니다!")
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      Button("Go Back") { store.send(.goBack) }
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

          Button("Flow로 이동") {
            store.send(.goToFlowSmartly)
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
    .navigationTitle("Settings")
  }
}
