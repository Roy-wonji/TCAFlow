// MARK: - 한 파일에서 Extension으로 Screen 분리하기

import TCAFlow
import ComposableArchitecture

// 방법 1: @FlowCoordinator 없이 수동으로 정의 + Extension 분리
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
        return handleScreenAction(screenAction, state: &state)
      case .route:
        return .none
      }
    }
  }

  // 기본 액션 처리
  private func handleScreenAction(
    _ screenAction: AppScreenAction,
    state: inout State
  ) -> Effect<Action> {
    switch screenAction {
    case .home(let homeAction):
      return handleHomeFlow(homeAction, state: &state)
    case .explore(let exploreAction):
      return handleExploreFlow(exploreAction, state: &state)
    case .profile(let profileAction):
      return handleProfileFlow(profileAction, state: &state)
    default:
      return .none
    }
  }
}

// MARK: - Extension으로 Screen enum 정의

extension AppCoordinator {
  // Screen 타입 정의를 여기서!
  enum AppScreen: Equatable, Sendable {
    case home(HomeFeature.State)
    case explore(ExploreFeature.State)
    case exploreList(ExploreListFeature.State)
    case exploreDetail(ExploreDetailFeature.State)
    case profile(ProfileCoordinator.State)
    case route(RouteFeature.State)
    case routeNotification(RouteNotificationFeature.State)
  }
}

// MARK: - Extension으로 Screen Action 정의

extension AppCoordinator {
  @CasePathable
  enum AppScreenAction: Equatable {
    case home(HomeFeature.Action)
    case explore(ExploreFeature.Action)
    case exploreList(ExploreListFeature.Action)
    case exploreDetail(ExploreDetailFeature.Action)
    case profile(ProfileCoordinator.Action)
    case route(RouteFeature.Action)
    case routeNotification(RouteNotificationFeature.Action)
  }
}

// MARK: - Extension으로 Home Flow 처리

extension AppCoordinator {
  private func handleHomeFlow(
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
}

// MARK: - Extension으로 Explore Flow 처리

extension AppCoordinator {
  private func handleExploreFlow(
    _ action: ExploreFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .listButtonTapped(let category):
      state.routes.push(.exploreList(ExploreListFeature.State(category: category)))
      return .none

    case .detailButtonTapped(let id):
      state.routes.push(.exploreDetail(ExploreDetailFeature.State(itemId: id)))
      return .none

    case .backButtonTapped:
      state.routes.pop()
      return .none
    }
  }
}

// MARK: - Extension으로 Profile Flow 처리

extension AppCoordinator {
  private func handleProfileFlow(
    _ action: ProfileCoordinator.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .delegate(.dismiss):
      state.routes.pop()
      return .none

    default:
      return .none
    }
  }
}

// MARK: - Extension으로 Screen 생성 헬퍼들

extension AppCoordinator.AppScreen {
  static func makeHome() -> Self {
    .home(HomeFeature.State())
  }

  static func makeExplore() -> Self {
    .explore(ExploreFeature.State())
  }

  static func makeExploreList(category: String) -> Self {
    .exploreList(ExploreListFeature.State(category: category))
  }

  static func makeExploreDetail(itemId: String) -> Self {
    .exploreDetail(ExploreDetailFeature.State(itemId: itemId))
  }

  static func makeProfile() -> Self {
    .profile(ProfileCoordinator.State())
  }
}

// MARK: - Extension으로 Navigation 유틸리티

extension AppCoordinator.AppScreen {
  var flowType: FlowType {
    switch self {
    case .home, .explore, .exploreList, .exploreDetail:
      return .explore
    case .profile:
      return .profile
    case .route, .routeNotification:
      return .route
    }
  }

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

// MARK: - Extension으로 추가 유틸리티들

extension AppCoordinator {
  /// 특정 플로우로 이동
  func navigateToFlow(_ flow: FlowType, state: inout State) -> Effect<Action> {
    switch flow {
    case .explore:
      state.routes.push(.explore(ExploreFeature.State()))
    case .profile:
      state.routes.push(.profile(ProfileCoordinator.State()))
    case .route:
      state.routes.push(.route(RouteFeature.State()))
    }
    return .none
  }

  /// 홈으로 돌아가기
  func navigateToHome(state: inout State) -> Effect<Action> {
    while let current = state.routes.currentRoute?.state,
          !current.isHome {
      state.routes.pop()
    }
    return .none
  }

  /// 현재 플로우 타입 확인
  func getCurrentFlow(from state: State) -> FlowType? {
    return state.routes.currentRoute?.state.flowType
  }
}

// MARK: - Feature 정의들

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
    case detailButtonTapped(String)
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
  struct State: Equatable {
    let itemId: String = ""
  }

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct ProfileCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {
    case delegate(Delegate)

    @CasePathable
    enum Delegate {
      case dismiss
    }
  }

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