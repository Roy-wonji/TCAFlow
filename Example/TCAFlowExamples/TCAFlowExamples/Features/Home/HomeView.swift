import ComposableArchitecture
import SwiftUI

struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 16) {
        Text("TCAFlow")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top, 20)

        Text("TCACoordinators 스타일의\ncoordinator 예제")
          .font(.title3)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)

        Text("Hashable 없이 route state를 쓰고, coordinator에서\n직접 push / goTo / popToRoot를 제어합니다.")
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 20)
      }

      VStack(spacing: 16) {
        Button("Start Flow") { store.send(.startFlow) }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)

        Button("Push One View") { store.send(.pushOneView) }
          .buttonStyle(.bordered)
          .controlSize(.large)

        Button("Open Nested Coordinator") { store.send(.openNestedCoordinator) }
          .buttonStyle(.bordered)
          .controlSize(.large)

        Button("Jump To Settings") { store.send(.jumpToSettings) }
          .buttonStyle(.bordered)
          .controlSize(.large)
      }
      .padding(.horizontal, 20)

      // 1.1.0 신규 기능 섹션
      VStack(spacing: 12) {
        Text("1.1.0 신규 기능")
          .font(.headline)
          .fontWeight(.semibold)

        Button("Half Sheet") { store.send(.openHalfSheet) }
          .buttonStyle(.bordered)
          .controlSize(.regular)

        Button("DeepLink Test") { store.send(.openDeepLink) }
          .buttonStyle(.bordered)
          .controlSize(.regular)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(UIColor.systemGray6))
      )
      .padding(.horizontal, 20)

      // goTo 예제 섹션
      VStack(spacing: 12) {
        Text("🎯 goTo 스마트 이동")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        VStack(spacing: 8) {
          Button("Go to Settings") {
            store.send(.goToSettingsSmartly)
          }
          .buttonStyle(.bordered)
          .controlSize(.regular)

          Button("Go to Flow") {
            store.send(.goToFlowOrCreate)
          }
          .buttonStyle(.bordered)
          .controlSize(.regular)
        }

        Text("스마트 이동: 있으면 이동, 없으면 새로 생성")
          .font(.caption)
          .foregroundColor(.blue)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(UIColor.systemGray6))
      )
      .padding(.horizontal, 20)

      Spacer()
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
  }
}
