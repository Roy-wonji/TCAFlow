import ComposableArchitecture
import TCAFlow

// MARK: - ShowcaseCoordinator

@FlowCoordinator(screen: "ShowcaseScreen", navigation: true)
struct ShowcaseCoordinator {
  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<ShowcaseScreen>)
  }

  // body를 직접 작성해서 routeLogging + routeGuard 사용
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      return self.handleRoute(state: &state, action: action)
    }
    .forEachRoute(\.routes, action: \.router)
    .routeLogging(level: .verbose, prefix: "✨ [Showcase]")
  }

  func handleRoute(state: inout State, action: Action) -> Effect<Action> {
    switch action {

    // MARK: - Route Guard 데모
    case .router(.routeAction(_, .menu(.openGuardedScreen))):
      // Route Guard로 네비게이션 조건 체크
      let guard_ = LoginGuard(isLoggedIn: false) // 항상 거부 (데모)
      if checkRouteGuard(guard_, from: state.routes) {
        state.routes.push(.guardedScreen(.init()))
      } else {
        state.routes.push(.guardRejected(.init(reason: "로그인이 필요합니다")))
      }
      return .none

    case .router(.routeAction(_, .menu(.openGuardedScreenLoggedIn))):
      let guard_ = LoginGuard(isLoggedIn: true) // 항상 허용 (데모)
      if checkRouteGuard(guard_, from: state.routes) {
        state.routes.push(.guardedScreen(.init()))
      } else {
        state.routes.push(.guardRejected(.init(reason: "로그인이 필요합니다")))
      }
      return .none

    // MARK: - Route Persistence 데모 (콘솔 로그)
    case .router(.routeAction(_, .menu(.saveRoutes))):
      // 실제 앱에서는 Screen.State가 Codable이면:
      // state.routes.saveRoutes(to: "showcase_nav")
      print("🧭 [Persistence] 현재 routes 개수: \(state.routes.count)")
      for (i, route) in state.routes.enumerated() {
        print("  [\(i)] \(route.isPush ? "push" : "root") - \(String(describing: route.screen))")
      }
      return .none

    case .router(.routeAction(_, .menu(.loadRoutes))):
      // 실제 앱에서는 Screen.State가 Codable이면:
      // state.routes = .loadRoutes(from: "showcase_nav") ?? state.routes
      print("🧭 [Persistence] load 호출됨 (Screen.State가 Codable이면 복원 가능)")
      return .none

    // MARK: - Route Animation 데모
    case .router(.routeAction(_, .menu(.openAnimatedSheet))):
      state.routes.presentSheet(.animatedScreen(.init()), configuration: .halfAndFull)
      return .none

    // MARK: - Go Back
    case .router(.routeAction(_, .guardedScreen(.goBack))),
         .router(.routeAction(_, .guardRejected(.goBack))),
         .router(.routeAction(_, .animatedScreen(.goBack))):
      state.routes.goBack()
      return .none

    default:
      return .none
    }
  }
}

extension ShowcaseCoordinator {
  @Reducer
  enum ShowcaseScreen {
    case menu(ShowcaseMenuFeature)
    case guardedScreen(GuardedScreenFeature)
    case guardRejected(GuardRejectedFeature)
    case animatedScreen(AnimatedScreenFeature)
  }
}

extension ShowcaseCoordinator.ShowcaseScreen.State: Equatable {}

// MARK: - Route Guard 구현

struct LoginGuard: RouteGuard {
  let isLoggedIn: Bool

  func canNavigate<Screen>(
    from currentRoutes: [Route<Screen>],
    to newRoutes: [Route<Screen>]
  ) -> RouteGuardResult {
    isLoggedIn ? .allow : .reject(reason: "로그인이 필요합니다")
  }
}
