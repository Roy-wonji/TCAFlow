import ComposableArchitecture

@Reducer
struct NestedStep1Feature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case nextStep
    case backToMain
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
