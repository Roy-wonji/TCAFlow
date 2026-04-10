import ComposableArchitecture

@Reducer
struct NestedStep2Feature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  @CasePathable
  enum Action {
    case goBack
    case finish
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
