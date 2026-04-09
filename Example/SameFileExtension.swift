// MARK: - 같은 파일에서 Extension으로 Screen 정의

import TCAFlow
import ComposableArchitecture

// 1. 방법 1: Screen enum을 먼저 정의하고 Coordinator에서 참조
enum AppScreen {
  case home(HomeFeature)
  case explore(ExploreFeature)
  case exploreList(ExploreListFeature)
  case exploreDetail(ExploreDetailFeature)
  case profile(ProfileCoordinator)
  case route(RouteFeature)
  case routeNotification(RouteNotificationFeature)
}

struct AppCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {
    var routes = RouteStack<AppScreen>([
      Route.root(.home(HomeFeature.State()))
    ])
  }

  @CasePathable
  enum Action {
    case route(FlowAction<AppScreenAction>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        switch screenAction {
        case .home(.detailButtonTapped):
          state.routes.push(.exploreDetail(ExploreDetailFeature.State()))
          return .none
        case .home(.exploreButtonTapped):
          state.routes.push(.explore(ExploreFeature.State()))
          return .none
        case .explore(.backButtonTapped):
          state.routes.pop()
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

// 2. Extension으로 Screen 관련 로직 분리
extension AppScreen {
  // 카테고리별 확인
  var isExploreFlow: Bool {
    switch self {
    case .home, .explore, .exploreList, .exploreDetail:
      return true
    default:
      return false
    }
  }

  var isProfileFlow: Bool {
    if case .profile = self { return true }
    return false
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

// 3. Extension으로 Screen 생성 메서드 분리
extension AppScreen {
  static func makeHome() -> Self {
    .home(HomeFeature.State())
  }

  static func makeExplore() -> Self {
    .explore(ExploreFeature.State())
  }

  static func makeExploreList(category: String) -> Self {
    .exploreList(ExploreListFeature.State(category: category))
  }

  static func makeProfile() -> Self {
    .profile(ProfileCoordinator.State())
  }
}

// 4. Extension으로 네비게이션 로직 분리
extension AppCoordinator {
  // Home 관련 액션 처리
  private func handleHomeAction(
    _ action: HomeFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .detailButtonTapped:
      state.routes.push(.exploreDetail(ExploreDetailFeature.State()))
      return .none
    case .exploreButtonTapped:
      state.routes.push(.explore(ExploreFeature.State()))
      return .none
    case .profileButtonTapped:
      state.routes.push(.profile(ProfileCoordinator.State()))
      return .none
    }
  }

  // Explore 관련 액션 처리
  private func handleExploreAction(
    _ action: ExploreFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .listButtonTapped(let category):
      state.routes.push(.exploreList(ExploreListFeature.State(category: category)))
      return .none
    case .backButtonTapped:
      state.routes.pop()
      return .none
    }
  }
}

// 5. Extension으로 유틸리티 메서드 분리
extension AppCoordinator {
  /// 현재 플로우 타입 확인
  func getCurrentFlow(from state: State) -> FlowType? {
    guard let currentScreen = state.routes.currentRoute?.state else { return nil }

    if currentScreen.isExploreFlow { return .explore }
    if currentScreen.isProfileFlow { return .profile }
    if currentScreen.isRouteFlow { return .route }
    return nil
  }

  /// 특정 화면까지 뒤로 이동
  func popToHomeScreen(state: inout State) {
    while let current = state.routes.currentRoute?.state,
          !current.isHome {
      state.routes.pop()
    }
  }
}

extension AppScreen {
  var isHome: Bool {
    if case .home = self { return true }
    return false
  }
}

enum FlowType {
  case explore
  case profile
  case route
}

// Screen Action enum 정의
@CasePathable
enum AppScreenAction {
  case home(HomeFeature.Action)
  case explore(ExploreFeature.Action)
  case exploreList(ExploreListFeature.Action)
  case exploreDetail(ExploreDetailFeature.Action)
  case profile(ProfileCoordinator.Action)
  case route(RouteFeature.Action)
  case routeNotification(RouteNotificationFeature.Action)
}

// Feature 정의들...
struct HomeFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {
    case detailButtonTapped
    case exploreButtonTapped
    case profileButtonTapped
  }

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ExploreFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {
    case listButtonTapped(String)
    case backButtonTapped
  }

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ExploreListFeature: Reducer {
  @ObservableState
  struct State: Equatable {
    let category: String
  }

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ExploreDetailFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ProfileCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct RouteFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct RouteNotificationFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}