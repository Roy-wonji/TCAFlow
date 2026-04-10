import ComposableArchitecture

@Reducer
struct DetailFeature {
  @ObservableState
  struct State: Equatable {
    var title: String
    var message: String

    init(title: String = "Detail", message: String = "Detail 화면입니다") {
      self.title = title
      self.message = message
    }
  }

  @CasePathable
  enum Action {
    case goBack
    case goToRoot
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
