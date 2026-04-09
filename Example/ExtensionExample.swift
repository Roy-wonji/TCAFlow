// MARK: - Extension 기반 Screen 정의 예시

import TCAFlow
import ComposableArchitecture

// 1. 기본 Coordinator 구조 (Screen enum 없이)
@FlowCoordinator
struct AppCoordinator: Reducer {

  // 매크로가 Screen enum을 자동 생성하지만 비어있는 상태

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        switch screenAction {
        case .home(.detailButtonTapped):
          state.routes.push(.detail(DetailFeature.State()))
          return .none

        case .home(.exploreButtonTapped):
          state.routes.push(.explore(ExploreFeature.State()))
          return .none

        case .detail(.closeButtonTapped):
          state.routes.pop()
          return .none

        case .explore(.listButtonTapped):
          state.routes.push(.exploreList(ExploreListFeature.State()))
          return .none

        default:
          return .none
        }

      case .route:
        return .none
      }
    }
  }
}

// 2. Extension으로 Screen cases 정의
extension AppScreen {
  // 기본 화면들
  static let home = AppScreen.home(HomeFeature())
  static let detail = AppScreen.detail(DetailFeature())

  // 탐색 관련 화면들
  static let explore = AppScreen.explore(ExploreFeature())
  static let exploreList = AppScreen.exploreList(ExploreListFeature())
  static let exploreDetail = AppScreen.exploreDetail(ExploreDetailFeature())

  // 프로필 관련 화면들
  static let profile = AppScreen.profile(ProfileCoordinator())

  // 루트 관련 화면들
  static let route = AppScreen.route(RouteFeature())
  static let routeNotification = AppScreen.routeNotification(RouteNotificationFeature())
}

// 3. 카테고리별로 Extension 분리
extension AppScreen {
  // MARK: - Navigation Helpers

  var isExploreFlow: Bool {
    switch self {
    case .explore, .exploreList, .exploreDetail:
      return true
    default:
      return false
    }
  }

  var isRouteFlow: Bool {
    switch self {
    case .route, .routeNotification:
      return true
    default:
      return false
    }
  }
}

// 4. 별도 파일로 분리 가능한 구조
// AppScreen+Home.swift
extension AppScreen {
  static func makeHome() -> Self {
    .home(HomeFeature())
  }
}

// AppScreen+Explore.swift
extension AppScreen {
  static func makeExplore() -> Self {
    .explore(ExploreFeature())
  }

  static func makeExploreList(category: String) -> Self {
    .exploreList(ExploreListFeature.State(category: category))
  }
}

// 더미 Feature들 (예시용)
struct HomeFeature: Reducer {
  struct State: Equatable {}
  enum Action { case detailButtonTapped, exploreButtonTapped }
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct DetailFeature: Reducer {
  struct State: Equatable {}
  enum Action { case closeButtonTapped }
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ExploreFeature: Reducer {
  struct State: Equatable {}
  enum Action { case listButtonTapped }
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ExploreListFeature: Reducer {
  struct State: Equatable { let category: String = "" }
  enum Action {}
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ExploreDetailFeature: Reducer {
  struct State: Equatable {}
  enum Action {}
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ProfileCoordinator: Reducer {
  struct State: Equatable {}
  enum Action {}
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct RouteFeature: Reducer {
  struct State: Equatable {}
  enum Action {}
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct RouteNotificationFeature: Reducer {
  struct State: Equatable {}
  enum Action {}
  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct EmptyFeature: Reducer {
  struct State: Equatable {}
  enum Action {}
  var body: some ReducerOf<Self> { EmptyReducer() }
}