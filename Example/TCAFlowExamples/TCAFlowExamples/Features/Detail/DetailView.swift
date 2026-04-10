import ComposableArchitecture
import SwiftUI

struct DetailView: View {
  @Bindable var store: StoreOf<DetailFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text(store.title)
        .font(.largeTitle)
        .fontWeight(.bold)

      Text(store.message)
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      VStack(spacing: 16) {
        Button("Go Back") { store.send(.goBack) }
          .buttonStyle(.borderedProminent)

        Button("Go To Root") { store.send(.goToRoot) }
          .buttonStyle(.bordered)
      }

      // goTo 예제 섹션
      VStack(spacing: 12) {
        Text("🎯 goTo 이동")
          .font(.headline)
          .fontWeight(.semibold)

        VStack(spacing: 8) {
          Button("이전 홈으로 돌아가기") {
            store.send(.goToHomeDirectly)
          }
          .buttonStyle(.bordered)

          Button("Settings로 이동") {
            store.send(.goToSettingsSmartly)
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
    .navigationTitle(store.title)
  }
}
