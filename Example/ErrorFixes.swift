// MARK: - TCAFlow 에러 수정 가이드

import TCAFlow
import ComposableArchitecture

// ❌ 문제가 있는 코드 패턴들과 ✅ 올바른 해결책들

// 1. ReducerOf 타입 파라미터 문제 해결

// ❌ 잘못된 사용법
/*
struct HomeCoordinator: Reducer {
  var body: some ReducerOf<State, Action> {  // ❌ 타입 파라미터 2개 전달
    // ...
  }
}
*/

// ✅ 올바른 사용법
struct HomeCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {  // ✅ Equatable만 선언 (중복 제거)
    var routes = RouteStack<HomeScreen.State>([
      Route.root(.home(HomeFeature.State()))
    ])
  }

  @CasePathable
  enum Action {
    case route(FlowAction<HomeScreen.Action>)
  }

  var body: some ReducerOf<Self> {  // ✅ Self만 사용
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        switch screenAction {
        case .home(.exploreButtonTapped):
          state.routes.push(.explore(ExploreFeature.State()))
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

// 2. Screen enum과 Action enum 올바른 정의

enum HomeScreen: Sendable, Equatable {
  case home(HomeFeature.State)
  case explore(ExploreFeature.State)
  case detail(DetailFeature.State)
}

extension HomeScreen {
  @CasePathable
  enum Action: Equatable {  // ✅ Equatable만 선언
    case home(HomeFeature.Action)
    case explore(ExploreFeature.Action)
    case detail(DetailFeature.Action)
  }
}

// 3. Extension 방식으로 에러 없는 구조

@FlowCoordinator(navigation: true)
extension HomeCoordinator {
  enum Screen: Equatable {  // ✅ Equatable만 선언 (중복 없음)
    case home(HomeFeature.State)
    case explore(ExploreFeature.State)
    case detail(DetailFeature.State)
  }
}

// 4. Manual 방식으로 타입 안전한 구조

struct ManualHomeCoordinator: Reducer {
  @ObservableState
  struct State: Equatable {
    var routes = RouteStack<Screen>([
      Route.root(.home(HomeFeature.State()))
    ])
  }

  enum Screen: Equatable {
    case home(HomeFeature.State)
    case explore(ExploreFeature.State)
    case detail(DetailFeature.State)
  }

  @CasePathable
  enum ScreenAction: Equatable {
    case home(HomeFeature.Action)
    case explore(ExploreFeature.Action)
    case detail(DetailFeature.Action)
  }

  @CasePathable
  enum Action {
    case route(FlowAction<ScreenAction>)
  }

  var body: some ReducerOf<Self> {  // ✅ 올바른 타입 사용
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        return handleScreenAction(screenAction, state: &state)
      case .route:
        return .none
      }
    }
  }

  private func handleScreenAction(
    _ screenAction: ScreenAction,
    state: inout State
  ) -> Effect<Action> {
    switch screenAction {
    case .home(.exploreButtonTapped):
      state.routes.push(.explore(ExploreFeature.State()))
      return .none
    case .explore(.backButtonTapped):
      state.routes.pop()
      return .none
    default:
      return .none
    }
  }
}

// 5. 에러 방지를 위한 베스트 프랙티스

struct BestPracticeCoordinator: Reducer {
  // ✅ State는 Equatable만 선언
  @ObservableState
  struct State: Equatable {
    var routes = RouteStack<Screen>()

    init() {
      self.routes = RouteStack([
        Route.root(.home(HomeFeature.State()))
      ])
    }
  }

  // ✅ Screen enum 깔끔하게 정의
  enum Screen: Equatable, Sendable {
    case home(HomeFeature.State)
    case explore(ExploreFeature.State)
    case detail(DetailFeature.State)
  }

  // ✅ Action enum CasePathable만 선언
  @CasePathable
  enum Action {
    case route(FlowAction<ScreenAction>)
  }

  @CasePathable
  enum ScreenAction: Equatable {
    case home(HomeFeature.Action)
    case explore(ExploreFeature.Action)
    case detail(DetailFeature.Action)
  }

  // ✅ body 타입 올바르게 선언
  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .route(.routeAction(_, let screenAction)):
        return self.handleScreenAction(screenAction, state: &state)
      case .route:
        return .none
      }
    }
  }

  // Extension으로 로직 분리
  private func handleScreenAction(
    _ screenAction: ScreenAction,
    state: inout State
  ) -> Effect<Action> {
    switch screenAction {
    case .home(let homeAction):
      return self.handleHome(homeAction, state: &state)
    case .explore(let exploreAction):
      return self.handleExplore(exploreAction, state: &state)
    case .detail(let detailAction):
      return self.handleDetail(detailAction, state: &state)
    }
  }
}

// Extension으로 각 Flow 처리 분리
extension BestPracticeCoordinator {
  private func handleHome(
    _ action: HomeFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .exploreButtonTapped:
      state.routes.push(.explore(ExploreFeature.State()))
      return .none
    case .detailButtonTapped:
      state.routes.push(.detail(DetailFeature.State()))
      return .none
    }
  }

  private func handleExplore(
    _ action: ExploreFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .backButtonTapped:
      state.routes.pop()
      return .none
    }
  }

  private func handleDetail(
    _ action: DetailFeature.Action,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .closeButtonTapped:
      state.routes.pop()
      return .none
    }
  }
}

// Feature 정의들
struct HomeFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action: Equatable {
    case exploreButtonTapped
    case detailButtonTapped
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

struct ExploreFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action: Equatable {
    case backButtonTapped
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

struct DetailFeature: Reducer {
  @ObservableState
  struct State: Equatable {}

  @CasePathable
  enum Action: Equatable {
    case closeButtonTapped
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}