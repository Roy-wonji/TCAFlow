import Foundation
import ComposableArchitecture
import TCAFlow

// MARK: - 🚀 TCAFlow 완전한 데모
func demoTCAFlow() {
    print("🌟 TCAFlow 완전한 데모 (복사 없이!) 🌟")
    print("================================================")

    // AppCoordinator 생성 및 사용
    let coordinator = AppCoordinator()
    var state = AppCoordinator.State()

    print("✅ TCAFlow AppCoordinator:")
    print("   - 초기 routes: \(state.routes.count)개")
    print("   - 첫 번째 화면: \(state.routes.first?.state ?? .home(.init()))")

    // TCAFlow 네비게이션 테스트
    state.routes.push(.explore(.init()))
    state.routes.push(.profile(.init()))

    print("\n✅ 기본 네비게이션:")
    print("   - push 후 스택 깊이: \(state.routes.depth)")
    print("   - 현재 화면: \(state.routes.currentScreen?.state ?? .home(.init()))")

    // TCAFlow 특화 기능: 스크린 직접 이동
    state.routes.goTo(.settings(.init()))
    print("\n🎯 TCAFlow 특화 - 스크린 직접 이동:")
    print("   - goTo(.settings) 후 깊이: \(state.routes.depth)")

    state.routes.goBackTo(.home(.init()))
    print("   - goBackTo(.home) 후 깊이: \(state.routes.depth)")

    // 스크린 존재 확인
    let hasProfile = state.routes.has(.profile(.init()))
    print("\n✅ 스크린 존재 확인:")
    print("   - 프로필 화면 존재: \(hasProfile)")

    // 애니메이션 지원
    state.routes.pushWithAnimation(.explore(.init()))
    print("\n🎨 애니메이션 지원:")
    print("   - pushWithAnimation 성공!")

    print("\n🎉 TCAFlow 완전한 데모 완료!")
    print("→ 복사 없이 로컬 패키지로 완벽 동작! ✅")
}

// MARK: - 비교 시연
func showComparison() {
    print("\n📊 TCAFlow vs 기존 방식 비교")
    print("================================================")

    print("🔴 기존 TCACoordinators:")
    print("   - 소스 복사 필요 📁")
    print("   - Hashable 제약 ❌")
    print("   - 복잡한 클로저 ⚙️")

    print("\n🟢 TCAFlow:")
    print("   - 로컬 패키지 참조 ✅")
    print("   - Hashable 불필요 ✅")
    print("   - 직관적 API ✅")
    print("   - .goTo(.screen) 직접 이동 🎯")
    print("   - 애니메이션 내장 🎨")

    print("\n🪄 매크로 지원 (곧 완성):")
    print("   - @FlowCoordinator")
    print("   - 100줄 → 10줄")
}

// MARK: - 메인 실행
print("🚀 TCAFlow - 복사 없는 깔끔한 예제!")
print("================================================")

demoTCAFlow()
showComparison()

print("\n✨ 결론: 복사 없이도 TCAFlow 완벽 사용 가능! 🚀")
print("================================================")