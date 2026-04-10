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
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
