import SwiftUI
import ComposableArchitecture
import TCAFlow

@main
struct TCAFlowExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

// MARK: - Content View

struct ContentView: View {
  @State private var store = Store(initialState: DemoCoordinator.State()) {
    DemoCoordinator()
  }

  var body: some View {
    DemoCoordinatorView(store: store)
  }
}

// MARK: - Demo Coordinator

@Reducer
struct DemoCoordinator {
  @ObservableState
  struct State: Equatable {
    var routes: [Route<DemoScreen.State>]

    init() {
      self.routes = [.root(.home(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  enum Action {
    case router(IndexedRouterActionOf<DemoScreen>)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        case .router(let routeAction):
          return handleRouterAction(state: &state, action: routeAction)
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }

  private func handleRouterAction(
    state: inout State,
    action: IndexedRouterActionOf<DemoScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(_, .home(.startFlow)):
        state.routes.push(.flow(.init()))
        return .none

      case .routeAction(_, .home(.pushOneView)):
        state.routes.push(.detail(.init(title: "Push된 화면", message: "간단한 Push 테스트입니다")))
        return .none

      case .routeAction(_, .home(.openNestedCoordinator)):
        state.routes.push(.nested(.init()))
        return .none

      case .routeAction(_, .home(.jumpToSettings)):
        state.routes.push(.settings(.init()))
        return .none

      case .routeAction(_, .flow(.nextStep)):
        state.routes.push(.detail(.init(title: "Flow Step 2", message: "다음 단계로 이동했습니다")))
        return .none

      case .routeAction(_, .detail(.goBack)):
        state.routes.goBack()
        return .none

      case .routeAction(_, .detail(.goToRoot)):
        state.routes.goBackToRoot()
        return .none

      case .routeAction(_, .settings(.goBack)):
        state.routes.goBack()
        return .none

      case .routeAction(_, .nested(.backToMain)):
        state.routes.goBackToRoot()
        return .none

      default:
        return .none
    }
  }
}

extension DemoCoordinator {
  @Reducer
  enum DemoScreen {
    case home(HomeFeature)
    case flow(FlowFeature)
    case detail(DetailFeature)
    case settings(SettingsFeature)
    case nested(NestedCoordinator)
  }
}

extension DemoCoordinator.DemoScreen.State: Equatable {}

// MARK: - DemoCoordinatorView

struct DemoCoordinatorView: View {
  @Bindable var store: StoreOf<DemoCoordinator>

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .home(let store):
          HomeView(store: store)
        case .flow(let store):
          FlowView(store: store)
        case .detail(let store):
          DetailView(store: store)
        case .settings(let store):
          SettingsView(store: store)
        case .nested(let store):
          NestedCoordinatorView(store: store)
      }
    }
  }
}

// MARK: - Home Feature

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

struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 16) {
        Text("TCAFlow")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top, 20)

        Text("TCACoordinators 스타일의\ncoordinator 예제")
          .font(.title3)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)

        Text("Hashable 없이 route state를 쓰고, coordinator에서\n직접 push / goTo / popToRoot를 제어합니다.")
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 20)
      }

      VStack(spacing: 16) {
        Button("Start Flow") { store.send(.startFlow) }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)

        Button("Push One View") { store.send(.pushOneView) }
          .buttonStyle(.bordered)
          .controlSize(.large)

        Button("Open Nested Coordinator") { store.send(.openNestedCoordinator) }
          .buttonStyle(.bordered)
          .controlSize(.large)

        Button("Jump To Settings") { store.send(.jumpToSettings) }
          .buttonStyle(.bordered)
          .controlSize(.large)
      }
      .padding(.horizontal, 20)

      Spacer()
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Flow Feature

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

struct FlowView: View {
  @Bindable var store: StoreOf<FlowFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Flow Started!")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 플로우의 첫 번째 단계입니다")
        .font(.body)
        .multilineTextAlignment(.center)

      Button("Next Step") { store.send(.nextStep) }
        .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding()
    .navigationTitle("Flow")
  }
}

// MARK: - Detail Feature

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

struct DetailView: View {
  @Bindable var store: StoreOf<DetailFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text(store.title)
        .font(.largeTitle)
        .fontWeight(.bold)

      Text(store.message)
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      VStack(spacing: 16) {
        Button("Go Back") { store.send(.goBack) }
          .buttonStyle(.borderedProminent)

        Button("Go To Root") { store.send(.goToRoot) }
          .buttonStyle(.bordered)
      }

      Spacer()
    }
    .padding()
    .navigationTitle(store.title)
  }
}

// MARK: - Settings Feature

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

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(spacing: 30) {
      Text("Settings")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("이것은 Settings 화면입니다.\npush로 이동했습니다!")
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      Button("Go Back") { store.send(.goBack) }
        .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding()
    .navigationTitle("Settings")
  }
}

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

struct NestedCoordinatorView: View {
  @Bindable var store: StoreOf<NestedCoordinator>

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .step1(let store):
          NestedStep1View(store: store)
        case .step2(let store):
          NestedStep2View(store: store)
      }
    }
    .navigationTitle("Nested Coordinator")
  }
}

// MARK: - Nested Steps

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
