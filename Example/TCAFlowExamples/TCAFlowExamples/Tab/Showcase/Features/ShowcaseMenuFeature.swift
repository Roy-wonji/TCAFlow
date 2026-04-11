import ComposableArchitecture

@Reducer
struct ShowcaseMenuFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    // Route Guard
    case openGuardedScreen           // 미로그인 → 거부
    case openGuardedScreenLoggedIn   // 로그인 → 허용
    // Route Persistence
    case saveRoutes
    case loadRoutes
    // Route Animation
    case openAnimatedSheet
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
