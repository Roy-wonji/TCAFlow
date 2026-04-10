import ComposableArchitecture

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case goBack
    case goToHomeDirectly            // 이전 홈으로 돌아가기
    case goToFlowSmartly             // 무조건 Flow로 이동
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
