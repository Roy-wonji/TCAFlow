import ComposableArchitecture
import SwiftUI
import TCAFlow

// MARK: - Nested Coordinator

@Reducer
struct NestedCoordinator {
  @ObservableState
  struct State: Equatable {
    var routes: [Route<NestedScreen.State>]

    init() {
      self.routes = [.root(.step1(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<NestedScreen>)
    case backToMain
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        case .router(let routeAction):
          return handleRouterAction(state: &state, action: routeAction)
        case .backToMain:
          return .none
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }

  private func handleRouterAction(
    state: inout State,
    action: IndexedRouterActionOf<NestedScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(_, .step1(.nextStep)):
        state.routes.push(.step2(.init()))
        return .none

      case .routeAction(_, .step1(.backToMain)):
        return .send(.backToMain)

      case .routeAction(_, .step2(.goBack)):
        state.routes.goBack()
        return .none

      case .routeAction(_, .step2(.finish)):
        return .send(.backToMain)

      default:
        return .none
    }
  }
}

extension NestedCoordinator {
  @Reducer
  enum NestedScreen {
    case step1(NestedStep1Feature)
    case step2(NestedStep2Feature)
  }
}

extension NestedCoordinator.NestedScreen.State: Equatable {}

// MARK: - NestedCoordinatorView

struct NestedCoordinatorView: View {
  @Bindable var store: StoreOf<NestedCoordinator>
  @GestureState private var dragOffset: CGFloat = 0

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .step1(let store):
          NestedStep1View(store: store)
        case .step2(let store):
          NestedStep2View(store: store)
      }
    }
    .offset(x: dragOffset)
    .simultaneousGesture(
      DragGesture(minimumDistance: 20, coordinateSpace: .global)
        .updating($dragOffset) { value, state, _ in
          if value.startLocation.x < 30 && value.translation.width > 0 {
            state = value.translation.width
          }
        }
        .onEnded { value in
          if value.startLocation.x < 30 && value.translation.width > 100 {
            store.send(.backToMain)
          }
        }
    )
  }
}

// MARK: - Nested Step 1

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

struct NestedStep1View: View {
  @Bindable var store: StoreOf<NestedStep1Feature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Nested Step 1")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 중첩된 Coordinator의\n첫 번째 단계입니다")
        .font(.body)
        .multilineTextAlignment(.center)

      VStack(spacing: 16) {
        Button("Next Step") { store.send(.nextStep) }
          .buttonStyle(.borderedProminent)

        Button("Back to Main") { store.send(.backToMain) }
          .buttonStyle(.bordered)
      }

      Spacer()
    }
    .padding()
    .navigationTitle("Nested Step 1")
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          store.send(.backToMain)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
            Text("Back")
          }
        }
      }
    }
  }
}

// MARK: - Nested Step 2

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

struct NestedStep2View: View {
  @Bindable var store: StoreOf<NestedStep2Feature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Nested Step 2")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("중첩된 Coordinator의\n두 번째 단계입니다")
        .font(.body)
        .multilineTextAlignment(.center)

      VStack(spacing: 16) {
        Button("Go Back") { store.send(.goBack) }
          .buttonStyle(.bordered)

        Button("Finish & Back to Main") { store.send(.finish) }
          .buttonStyle(.borderedProminent)
      }

      Spacer()
    }
    .padding()
    .navigationTitle("Nested Step 2")
  }
}
