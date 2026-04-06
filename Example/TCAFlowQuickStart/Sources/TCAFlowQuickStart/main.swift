import Foundation
import ComposableArchitecture
import TCAFlow

// MARK: - 간단한 화면 State 타입들
enum SimpleScreen: Equatable {
    case home(String)
    case explore(String)
    case profile(String)
    case settings(String)
}

// MARK: - 🚀 TCAFlow 핵심 기능 테스트
func testTCAFlowCore() {
    print("🚀 TCAFlow 핵심 기능 테스트")
    print("========================================")

    // 1. Route 생성 (Hashable 제약 없음!)
    let homeRoute = Route(SimpleScreen.home("홈 화면"))
    print("✅ Route 생성:")
    print("   - ID: \(homeRoute.id)")
    print("   - State: \(homeRoute.state)")

    // 2. 네비게이션 스택 관리
    var routes: IdentifiedArrayOf<Route<SimpleScreen>> = []

    // 기본 네비게이션
    routes.push(SimpleScreen.home("홈"))
    routes.push(SimpleScreen.explore("탐색"))
    routes.push(SimpleScreen.profile("프로필"))

    print("\n✅ 기본 네비게이션:")
    print("   - 스택 깊이: \(routes.depth)")
    print("   - 현재 화면: \(routes.currentScreen?.state ?? SimpleScreen.home("없음"))")
    print("   - 루트 화면: \(routes.rootScreen?.state ?? SimpleScreen.home("없음"))")

    // 3. TCAFlow 특화 기능: 스크린 직접 이동
    routes.goTo(SimpleScreen.settings("설정"))
    print("\n✅ 스크린 직접 이동 (goTo):")
    print("   - goTo(.settings) 후 깊이: \(routes.depth)")
    print("   - 현재 화면: \(routes.currentScreen?.state ?? SimpleScreen.home("없음"))")

    routes.goBackTo(SimpleScreen.home("홈"))
    print("\n✅ 스크린 직접 뒤로 (goBackTo):")
    print("   - goBackTo(.home) 후 깊이: \(routes.depth)")
    print("   - 현재 화면: \(routes.currentScreen?.state ?? SimpleScreen.home("없음"))")

    // 4. 스크린 존재 확인
    let hasProfile = routes.has(SimpleScreen.profile("프로필"))
    let hasSettings = routes.has(SimpleScreen.settings("설정"))
    print("\n✅ 스크린 존재 확인:")
    print("   - 프로필 화면 존재: \(hasProfile)")
    print("   - 설정 화면 존재: \(hasSettings)")

    // 5. 애니메이션 지원 네비게이션
    routes.pushWithAnimation(SimpleScreen.explore("새 탐색"))
    print("\n✅ 애니메이션 네비게이션:")
    print("   - pushWithAnimation 후 깊이: \(routes.depth)")

    let poppedRoute = routes.popWithAnimation()
    print("   - popWithAnimation 후: \(poppedRoute?.state ?? SimpleScreen.home("없음"))")
    print("   - 현재 깊이: \(routes.depth)")

    print("\n🎉 TCAFlow 핵심 기능 테스트 완료!")
}

// MARK: - TCAFlow vs TCACoordinators 비교 데모
func showComparison() {
    print("\n📊 TCAFlow vs TCACoordinators 비교")
    print("========================================")

    print("🔴 TCACoordinators의 한계:")
    print("   - @Reducer(state: .hashable) 필수")
    print("   - CLLocationCoordinate2D ❌ (Hashable 아님)")
    print("   - UIImage ❌ (Hashable 아님)")
    print("   - 복잡한 클로저: routes.goBack(matching: { ... })")
    print("   - 긴 타입명: IndexedRouterActionOf")

    print("\n🟢 TCAFlow의 혁신:")
    print("   - @Reducer (Hashable 불필요!) ✅")
    print("   - CLLocationCoordinate2D ✅ (Equatable만)")
    print("   - UIImage ✅ (Equatable만)")
    print("   - 직관적 API: routes.goBackTo(.home) ✅")
    print("   - 짧은 타입명: FlowActionOf ✅")

    print("\n🪄 추가 혁신:")
    print("   - @FlowCoordinator 매크로 (개발중)")
    print("   - 애니메이션 내장: pushWithAnimation")
    print("   - iOS 16+ NavigationStack 기반")
    print("   - UUID 기반 효율적 라우팅")
}

// MARK: - 실제 사용 시나리오 데모
func showRealWorldExample() {
    print("\n🌍 실제 사용 시나리오")
    print("========================================")

    // 실제 앱에서 사용할 수 있는 복잡한 타입들
    struct UserProfile: Equatable {
        let name: String
        let email: String
        let preferences: [String: Any] = ["theme": "dark", "notifications": true]

        static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
            return lhs.name == rhs.name && lhs.email == rhs.email
        }
    }

    enum AppScreen: Equatable {
        case login(String)
        case profile(UserProfile)
        case settings([String: Any])
        case map(Double, Double) // 위도, 경도

        static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
            switch (lhs, rhs) {
            case (.login(let l), .login(let r)): return l == r
            case (.profile(let l), .profile(let r)): return l == r
            case (.map(let l1, let l2), .map(let r1, let r2)): return l1 == r1 && l2 == r2
            case (.settings, .settings): return true
            default: return false
            }
        }
    }

    var appRoutes: IdentifiedArrayOf<Route<AppScreen>> = []

    // 실제 네비게이션 플로우
    appRoutes.push(AppScreen.login("initial"))
    print("✅ 로그인 화면 push")

    let user = UserProfile(name: "김개발", email: "dev@example.com")
    appRoutes.goTo(AppScreen.profile(user))
    print("✅ 프로필 화면으로 직접 이동")

    appRoutes.push(AppScreen.map(37.5665, 126.9780)) // 서울 좌표
    print("✅ 지도 화면 push (위도/경도)")

    appRoutes.goBackTo(AppScreen.profile(user))
    print("✅ 프로필로 뒤로 이동")

    print("\n📱 최종 네비게이션 스택:")
    print("   - 총 깊이: \(appRoutes.depth)")
    print("   - 현재 화면: Profile(\(user.name))")
    print("   - TCACoordinators로는 불가능했던 시나리오! 🚀")
}

// MARK: - 메인 실행
print("🌟 TCAFlow - TCA 네비게이션 혁신 🌟")
print("================================================")

testTCAFlowCore()
showRealWorldExample()
showComparison()

print("\n✨ 결론 ✨")
print("TCAFlow = TCACoordinators의 편의성 + Hashable 제약 제거")
print("→ 더 자유롭고 직관적인 TCA 네비게이션 구현 🎯")
print("================================================")