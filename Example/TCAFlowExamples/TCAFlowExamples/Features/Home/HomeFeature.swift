import ComposableArchitecture

@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case startFlow
    case pushOneView
    case openNestedCoordinator
    case jumpToSettings
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
