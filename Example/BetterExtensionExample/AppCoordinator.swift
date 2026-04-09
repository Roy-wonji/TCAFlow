// MARK: - 실용적인 Extension 기반 구조

import TCAFlow
import ComposableArchitecture

@FlowCoordinator
struct AppCoordinator: Reducer {

  // Screen enum은 별도 파일에서 정의 (AppScreen.swift)
  enum Screen {
    case home(HomeFeature)
    case explore(ExploreFeature)
    case exploreList(ExploreListFeature)
    case exploreDetail(ExploreDetailFeature)
    case profile(ProfileCoordinator)
    case route(RouteFeature)
    case routeNotification(RouteNotificationFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        return self.handleScreenAction(screenAction, state: &state)

      case .route:
        return .none
      }
    }
  }
}

// MARK: - Extension으로 Action 처리 분리

extension AppCoordinator {
  private func handleScreenAction(
    _ screenAction: AppScreen.Action,
    state: inout State
  ) -> Effect<Action> {
    switch screenAction {
    case .home(let homeAction):
      return handleHomeAction(homeAction, state: &state)

    case .explore(let exploreAction):
      return handleExploreAction(exploreAction, state: &state)

    case .profile(let profileAction):
      return handleProfileAction(profileAction, state: &state)

    case .route(let routeAction):
      return handleRouteAction(routeAction, state: &state)

    default:
      return .none
    }
  }
}

// MARK: - Home Flow 처리

extension AppCoordinator {
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
}

// MARK: - Explore Flow 처리

extension AppCoordinator {
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

// MARK: - Profile Flow 처리

extension AppCoordinator {
  private func handleProfileAction(
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

// MARK: - Route Flow 처리

extension AppCoordinator {
  private func handleRouteAction(
    _ action: RouteFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .notificationButtonTapped:
      state.routes.push(.routeNotification(RouteNotificationFeature.State()))
      return .none

    case .closeButtonTapped:
      state.routes.pop()
      return .none
    }
  }
}

// MARK: - Navigation Utilities

extension AppCoordinator {
  /// 특정 화면으로 직접 이동
  private func navigateToScreen(
    _ screen: AppScreen.State,
    state: inout State
  ) -> Effect<Action> {
    state.routes.push(screen)
    return .none
  }

  /// 특정 화면까지 뒤로 이동
  private func popToScreen(
    _ targetScreen: AppScreen.State,
    state: inout State
  ) -> Effect<Action> {
    state.routes.goBackTo(targetScreen)
    return .none
  }

  /// 현재 플로우 확인
  private func getCurrentFlow(from state: State) -> AppFlow? {
    guard let currentScreen = state.routes.currentRoute?.state else { return nil }

    switch currentScreen {
    case .home, .explore, .exploreList, .exploreDetail:
      return .explore
    case .profile:
      return .profile
    case .route, .routeNotification:
      return .route
    }
  }
}

// MARK: - Flow Types

enum AppFlow {
  case explore
  case profile
  case route
}

// MARK: - Feature Stubs (실제로는 별도 파일들)

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
  enum Action {
    case notificationButtonTapped
    case closeButtonTapped
  }

  var body: some ReducerOf<Self> { EmptyReducer() }
}

struct RouteNotificationFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action {}

  var body: some ReducerOf<Self> { EmptyReducer() }
}