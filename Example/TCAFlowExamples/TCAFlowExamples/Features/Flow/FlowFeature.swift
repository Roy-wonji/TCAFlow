import ComposableArchitecture

@Reducer
struct FlowFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case nextStep
    case goToDetailSmartly           // Detail로 스마트 이동
    case goToHomeDirectly            // 이전 홈으로 돌아가기
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
