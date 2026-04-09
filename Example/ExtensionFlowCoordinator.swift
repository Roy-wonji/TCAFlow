// MARK: - Extension에서 @FlowCoordinator 사용 테스트

import TCAFlow
import ComposableArchitecture

// 1. 기본 Coordinator 정의 (비어있는 상태)
struct HomeCoordinator: Reducer {
  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

// 2. Extension에서 @FlowCoordinator 적용
@FlowCoordinator(navigation: true)
extension HomeCoordinator {
  public enum Screen: Equatable {
    case home(HomeFeature)
    case explore(ExploreFeature)
    case exploreList(ExploreListFeature)
    case exploreDetail(ExploreDetailFeature)
    case profile(ProfileCoordinator)
    case route(RouteFeature)
    case routeNotification(RouteNotificationFeature)
  }
}

// 3. Extension으로 추가 기능들 분리
extension HomeCoordinator {
  // Home 관련 로직
  func handleHomeActions(_ action: HomeFeature.Action, state: inout State) -> Effect<Action> {
    switch action {
    case .detailButtonTapped:
      state.routes.push(.exploreDetail(ExploreDetailFeature()))
      return .none
    case .exploreButtonTapped:
      state.routes.push(.explore(ExploreFeature()))
      return .none
    }
  }
}

extension HomeCoordinator {
  // Explore 관련 로직
  func handleExploreActions(_ action: ExploreFeature.Action, state: inout State) -> Effect<Action> {
    switch action {
    case .listButtonTapped(let category):
      state.routes.push(.exploreList(ExploreListFeature()))
      return .none
    case .backButtonTapped:
      state.routes.pop()
      return .none
    }
  }
}

extension HomeCoordinator {
  // Navigation 유틸리티들
  func navigateToHome(state: inout State) -> Effect<Action> {
    while let current = state.routes.currentRoute?.state,
          !current.isHome {
      state.routes.pop()
    }
    return .none
  }

  func getCurrentFlow(from state: State) -> FlowType? {
    guard let currentScreen = state.routes.currentRoute?.state else { return nil }
    return currentScreen.flowType
  }
}

// 4. Screen 관련 Extension
extension HomeCoordinator.HomeScreen {
  var isHome: Bool {
    if case .home = self { return true }
    return false
  }

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
}

enum FlowType {
  case explore
  case profile
  case route
}

// Feature 정의들
struct HomeFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {
    case detailButtonTapped
    case exploreButtonTapped
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
  struct State: Equatable {}

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