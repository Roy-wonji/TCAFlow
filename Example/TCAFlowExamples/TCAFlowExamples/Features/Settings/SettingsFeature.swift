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
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
