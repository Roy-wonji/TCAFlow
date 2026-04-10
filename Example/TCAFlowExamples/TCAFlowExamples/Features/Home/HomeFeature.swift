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

    // goTo 예제들 (실용적인 것만)
    case goToSettingsSmartly         // 무조건 Settings로 이동
    case goToFlowOrCreate            // 무조건 Flow로 이동
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
