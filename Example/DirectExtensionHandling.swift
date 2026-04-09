// MARK: - Extension에서 직접 액션 처리 (분기 없이)

import TCAFlow
import ComposableArchitecture

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

  // 메인 body에서는 extension들을 조합만 함 (분기 처리 없음)
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      .none  // 기본 처리 없음
    }
    // extension reducer들을 조합
    .concat(homeFlowReducer())
    .concat(exploreFlowReducer())
    .concat(profileFlowReducer())
    .concat(routeFlowReducer())
  }
}

// MARK: - Screen 정의

extension AppCoordinator {
  enum AppScreen: Equatable, Sendable {
    case home(HomeFeature.State)
    case explore(ExploreFeature.State)
    case exploreList(ExploreListFeature.State)
    case exploreDetail(ExploreDetailFeature.State)
    case profile(ProfileCoordinator.State)
    case route(RouteFeature.State)
    case routeNotification(RouteNotificationFeature.State)
  }

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

// MARK: - Extension으로 Home Flow 처리 (분기 없이 직접)

extension AppCoordinator {
  private func homeFlowReducer() -> some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      // Home 액션만 직접 처리
      guard case .route(.routeAction(_, .home(let homeAction))) = action else {
        return .none
      }

      switch homeAction {
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
}

// MARK: - Extension으로 Explore Flow 처리 (분기 없이 직접)

extension AppCoordinator {
  private func exploreFlowReducer() -> some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      // Explore 액션들만 직접 처리
      switch action {
      case .route(.routeAction(_, .explore(let exploreAction))):
        return handleExploreAction(exploreAction, state: &state)

      case .route(.routeAction(_, .exploreList(let listAction))):
        return handleExploreListAction(listAction, state: &state)

      case .route(.routeAction(_, .exploreDetail(let detailAction))):
        return handleExploreDetailAction(detailAction, state: &state)

      default:
        return .none
      }
    }
  }

  private func handleExploreAction(
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

  private func handleExploreListAction(
    _ action: ExploreListFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    // ExploreList 액션 처리
    return .none
  }

  private func handleExploreDetailAction(
    _ action: ExploreDetailFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    // ExploreDetail 액션 처리
    return .none
  }
}

// MARK: - Extension으로 Profile Flow 처리 (분기 없이 직접)

extension AppCoordinator {
  private func profileFlowReducer() -> some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      // Profile 액션만 직접 처리
      guard case .route(.routeAction(_, .profile(let profileAction))) = action else {
        return .none
      }

      switch profileAction {
      case .delegate(.dismiss):
        state.routes.pop()
        return .none

      default:
        return .none
      }
    }
  }
}

// MARK: - Extension으로 Route Flow 처리 (분기 없이 직접)

extension AppCoordinator {
  private func routeFlowReducer() -> some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      // Route 액션들만 직접 처리
      switch action {
      case .route(.routeAction(_, .route(let routeAction))):
        return handleRouteAction(routeAction, state: &state)

      case .route(.routeAction(_, .routeNotification(let notificationAction))):
        return handleRouteNotificationAction(notificationAction, state: &state)

      default:
        return .none
      }
    }
  }

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

  private func handleRouteNotificationAction(
    _ action: RouteNotificationFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    // RouteNotification 액션 처리
    return .none
  }
}

// MARK: - 더 간단한 방식 (Reducer builder 사용)

struct SimpleAppCoordinator: Reducer {
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

  // 메인 body는 조합만 담당
  var body: some ReducerOf<Self> {
    HomeFlowReducer()  // extension에서 정의된 reducer
    ExploreFlowReducer()
    ProfileFlowReducer()
    RouteFlowReducer()
  }
}

// MARK: - Extension으로 각 Flow Reducer 정의

extension SimpleAppCoordinator {
  struct HomeFlowReducer: Reducer {
    typealias State = SimpleAppCoordinator.State
    typealias Action = SimpleAppCoordinator.Action

    var body: some ReducerOf<Self> {
      Reduce { state, action in
        guard case .route(.routeAction(_, .home(let homeAction))) = action else {
          return .none
        }

        switch homeAction {
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
  }
}

extension SimpleAppCoordinator {
  struct ExploreFlowReducer: Reducer {
    typealias State = SimpleAppCoordinator.State
    typealias Action = SimpleAppCoordinator.Action

    var body: some ReducerOf<Self> {
      Reduce { state, action in
        switch action {
        case .route(.routeAction(_, .explore(let exploreAction))):
          switch exploreAction {
          case .listButtonTapped(let category):
            state.routes.push(.exploreList(ExploreListFeature.State(category: category)))
            return .none
          case .backButtonTapped:
            state.routes.pop()
            return .none
          default:
            return .none
          }

        case .route(.routeAction(_, .exploreList)):
          // ExploreList 액션들 처리
          return .none

        case .route(.routeAction(_, .exploreDetail)):
          // ExploreDetail 액션들 처리
          return .none

        default:
          return .none
        }
      }
    }
  }
}

extension SimpleAppCoordinator {
  struct ProfileFlowReducer: Reducer {
    typealias State = SimpleAppCoordinator.State
    typealias Action = SimpleAppCoordinator.Action

    var body: some ReducerOf<Self> {
      Reduce { state, action in
        guard case .route(.routeAction(_, .profile(let profileAction))) = action else {
          return .none
        }

        switch profileAction {
        case .delegate(.dismiss):
          state.routes.pop()
          return .none
        default:
          return .none
        }
      }
    }
  }
}

extension SimpleAppCoordinator {
  struct RouteFlowReducer: Reducer {
    typealias State = SimpleAppCoordinator.State
    typealias Action = SimpleAppCoordinator.Action

    var body: some ReducerOf<Self> {
      Reduce { state, action in
        switch action {
        case .route(.routeAction(_, .route(let routeAction))):
          switch routeAction {
          case .notificationButtonTapped:
            state.routes.push(.routeNotification(RouteNotificationFeature.State()))
            return .none
          case .closeButtonTapped:
            state.routes.pop()
            return .none
          }

        case .route(.routeAction(_, .routeNotification)):
          // RouteNotification 액션들 처리
          return .none

        default:
          return .none
        }
      }
    }
  }
}

// MARK: - Screen 타입 공유

extension SimpleAppCoordinator {
  typealias AppScreen = AppCoordinator.AppScreen
  typealias AppScreenAction = AppCoordinator.AppScreenAction
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