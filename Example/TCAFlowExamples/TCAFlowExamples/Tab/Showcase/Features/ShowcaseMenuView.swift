import ComposableArchitecture
import SwiftUI

struct ShowcaseMenuView: View {
  @Bindable var store: StoreOf<ShowcaseMenuFeature>

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        Text("1.1.0 Showcase")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top, 20)

        // MARK: - Route Guard
        sectionView(
          title: "Route Guard",
          description: "네비게이션 전 조건을 검사합니다"
        ) {
          Button("보호된 화면 (미로그인)") {
            store.send(.openGuardedScreen)
          }
          .buttonStyle(.bordered)
          .tint(.red)

          Button("보호된 화면 (로그인됨)") {
            store.send(.openGuardedScreenLoggedIn)
          }
          .buttonStyle(.bordered)
          .tint(.green)
        }

        // MARK: - Route Persistence
        sectionView(
          title: "Route Persistence",
          description: "네비게이션 상태를 저장/복원합니다"
        ) {
          Button("현재 Routes 저장") {
            store.send(.saveRoutes)
          }
          .buttonStyle(.bordered)

          Button("저장된 Routes 복원") {
            store.send(.loadRoutes)
          }
          .buttonStyle(.bordered)
        }

        // MARK: - Route Animation
        sectionView(
          title: "Route Animation",
          description: "Sheet에 커스텀 애니메이션을 적용합니다"
        ) {
          Button("하프 시트 (애니메이션)") {
            store.send(.openAnimatedSheet)
          }
          .buttonStyle(.borderedProminent)
        }

        Spacer()
      }
      .padding()
    }
    .navigationTitle("Showcase")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private func sectionView(
    title: String,
    description: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(spacing: 12) {
      VStack(spacing: 4) {
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      VStack(spacing: 8) {
        content()
      }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(UIColor.systemGray6))
    )
    .padding(.horizontal, 20)
  }
}
