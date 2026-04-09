// MARK: - 별도 파일로 분리된 Screen 정의

import ComposableArchitecture
import TCAFlow

// 1. Screen enum을 별도 파일로 분리
enum AppScreen: Equatable, Sendable {
  case home(HomeFeature.State)
  case explore(ExploreFeature.State)
  case exploreList(ExploreListFeature.State)
  case exploreDetail(ExploreDetailFeature.State)
  case profile(ProfileCoordinator.State)
  case route(RouteFeature.State)
  case routeNotification(RouteNotificationFeature.State)
}

// 2. Extension으로 카테고리별 분리
extension AppScreen {
  // MARK: - Home Flow

  static func makeHome() -> Self {
    .home(HomeFeature.State())
  }
}

extension AppScreen {
  // MARK: - Explore Flow

  static func makeExplore() -> Self {
    .explore(ExploreFeature.State())
  }

  static func makeExploreList(category: String) -> Self {
    .exploreList(ExploreListFeature.State(category: category))
  }

  static func makeExploreDetail(id: String) -> Self {
    .exploreDetail(ExploreDetailFeature.State(itemId: id))
  }

  var isExploreFlow: Bool {
    switch self {
    case .explore, .exploreList, .exploreDetail:
      return true
    default:
      return false
    }
  }
}

extension AppScreen {
  // MARK: - Profile Flow

  static func makeProfile() -> Self {
    .profile(ProfileCoordinator.State())
  }
}

extension AppScreen {
  // MARK: - Route Flow

  static func makeRoute() -> Self {
    .route(RouteFeature.State())
  }

  static func makeRouteNotification() -> Self {
    .routeNotification(RouteNotificationFeature.State())
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

// 3. Coordinator는 이 Screen enum을 참조
struct AppCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {
    var routes = RouteStack<AppScreen>([
      Route.root(.home(HomeFeature.State()))
    ])
  }

  @CasePathable
  enum Action {
    case route(FlowActionOf<AppScreenReducer>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        switch screenAction {
        case .home(.detailButtonTapped):
          state.routes.push(.exploreDetail(ExploreDetailFeature.State(itemId: "default")))
          return .none

        case .home(.exploreButtonTapped):
          state.routes.push(.explore(ExploreFeature.State()))
          return .none

        case .explore(.listButtonTapped(let category)):
          state.routes.push(.exploreList(ExploreListFeature.State(category: category)))
          return .none

        case .exploreDetail(.closeButtonTapped):
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

// 4. Screen Reducer도 extension으로 분리 가능
enum AppScreenReducer: Reducer, CaseReducer {
  case home(HomeFeature)
  case explore(ExploreFeature)
  case exploreList(ExploreListFeature)
  case exploreDetail(ExploreDetailFeature)
  case profile(ProfileCoordinator)
  case route(RouteFeature)
  case routeNotification(RouteNotificationFeature)

  @CasePathable
  @dynamicMemberLookup
  @ObservableState
  enum State: Equatable, CaseReducerState, CasePathable, CasePathIterable, ObservableState, Observable {
    typealias StateReducer = AppScreenReducer
    case home(HomeFeature.State)
    case explore(ExploreFeature.State)
    case exploreList(ExploreListFeature.State)
    case exploreDetail(ExploreDetailFeature.State)
    case profile(ProfileCoordinator.State)
    case route(RouteFeature.State)
    case routeNotification(RouteNotificationFeature.State)
  }

  @CasePathable
  enum Action: CasePathable, CasePathIterable {
    case home(HomeFeature.Action)
    case explore(ExploreFeature.Action)
    case exploreList(ExploreListFeature.Action)
    case exploreDetail(ExploreDetailFeature.Action)
    case profile(ProfileCoordinator.Action)
    case route(RouteFeature.Action)
    case routeNotification(RouteNotificationFeature.Action)
  }

  static var body: some Reducer<State, Action> {
    Reduce(EmptyReducer<State, Action>()
      .ifCaseLet(\State.home, action: \Action.home) { HomeFeature() }
      .ifCaseLet(\State.explore, action: \Action.explore) { ExploreFeature() }
      .ifCaseLet(\State.exploreList, action: \Action.exploreList) { ExploreListFeature() }
      .ifCaseLet(\State.exploreDetail, action: \Action.exploreDetail) { ExploreDetailFeature() }
      .ifCaseLet(\State.profile, action: \Action.profile) { ProfileCoordinator() }
      .ifCaseLet(\State.route, action: \Action.route) { RouteFeature() }
      .ifCaseLet(\State.routeNotification, action: \Action.routeNotification) { RouteNotificationFeature() }
    )
  }
}

// Feature 정의들...
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
    let itemId: String
  }

  @CasePathable
  enum Action {
    case closeButtonTapped
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