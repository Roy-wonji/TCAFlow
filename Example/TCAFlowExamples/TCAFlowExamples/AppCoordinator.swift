import ComposableArchitecture
import SwiftUI

@Reducer
struct AppCoordinator: Sendable {
  @preconcurrency @Reducer
  enum AppScreen: Sendable {
    case home(HomeFeature)
    case single(SingleViewFeature)
    case counter(CounterFeature)
    case summary(SummaryFeature)
    case settings(SettingsFeature)

    @dynamicMemberLookup
    enum CaseScope: ComposableArchitecture._CaseScopeProtocol, CasePaths.CasePathable {
      case home(StoreOf<HomeFeature>)
      case single(StoreOf<SingleViewFeature>)
      case counter(StoreOf<CounterFeature>)
      case summary(StoreOf<SummaryFeature>)
      case settings(StoreOf<SettingsFeature>)

      struct AllCasePaths {
        var home: CasePaths.AnyCasePath<CaseScope, StoreOf<HomeFeature>> {
          CasePaths.AnyCasePath(
            embed: { @Sendable in CaseScope.home($0) },
            extract: { guard case let .home(store) = $0 else { return nil }; return store }
          )
        }

        var single: CasePaths.AnyCasePath<CaseScope, StoreOf<SingleViewFeature>> {
          CasePaths.AnyCasePath(
            embed: { @Sendable in CaseScope.single($0) },
            extract: { guard case let .single(store) = $0 else { return nil }; return store }
          )
        }

        var counter: CasePaths.AnyCasePath<CaseScope, StoreOf<CounterFeature>> {
          CasePaths.AnyCasePath(
            embed: { @Sendable in CaseScope.counter($0) },
            extract: { guard case let .counter(store) = $0 else { return nil }; return store }
          )
        }

        var summary: CasePaths.AnyCasePath<CaseScope, StoreOf<SummaryFeature>> {
          CasePaths.AnyCasePath(
            embed: { @Sendable in CaseScope.summary($0) },
            extract: { guard case let .summary(store) = $0 else { return nil }; return store }
          )
        }

        var settings: CasePaths.AnyCasePath<CaseScope, StoreOf<SettingsFeature>> {
          CasePaths.AnyCasePath(
            embed: { @Sendable in CaseScope.settings($0) },
            extract: { guard case let .settings(store) = $0 else { return nil }; return store }
          )
        }
      }

      static var allCasePaths: AllCasePaths { AllCasePaths() }
    }
  }

  @ObservableState
  struct State: Equatable {
    var routes: RouteStack<AppScreen.State>

    init() {
      self.routes = RouteStack([
        Route(.home(HomeFeature.State()))
      ])
    }
  }

  enum Action {
    case route(FlowActionOf<AppScreen>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(let routeAction):
        switch routeAction {
        case .pathChanged(let path):
          let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
          while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
            _ = state.routes.pop()
          }

        case .element(.element(let id, let screenAction)):
        switch screenAction {
        case .home(.pushOneViewButtonTapped):
          state.routes.push(.single(SingleViewFeature.State()))

        case .home(.startFlowButtonTapped):
          state.routes.push(
            .counter(
              CounterFeature.State(
                session: DemoSession(name: "Onboarding"),
                count: 1
              )
            )
          )

        case .home(.settingsButtonTapped):
          state.routes.goTo(.settings(SettingsFeature.State()))

        case .counter(.summaryButtonTapped):
          if let route = state.routes.routes[id: id],
             case .counter(let counterState) = route.state {
            state.routes.push(
              .summary(
                SummaryFeature.State(
                  sessionName: counterState.session.name,
                  finalCount: counterState.count
                )
              )
            )
          }

        case .counter(.backToRootButtonTapped):
          state.routes.popToRoot()

        case .summary(.settingsButtonTapped):
          state.routes.goTo(.settings(SettingsFeature.State()))

        case .summary(.backButtonTapped):
          _ = state.routes.pop()

        case .summary(.restartButtonTapped):
          state.routes.popToRoot()

        case .settings(.backButtonTapped):
          _ = state.routes.pop()

        case .single(.closeButtonTapped):
          _ = state.routes.pop()

        case .counter(.incrementButtonTapped):
          if case .counter(var childState) = state.routes.routes[id: id]?.state {
            childState.count += 1
            state.routes.routes[id: id]?.state = .counter(childState)
          }

        case .counter(.decrementButtonTapped):
          if case .counter(var childState) = state.routes.routes[id: id]?.state {
            childState.count -= 1
            state.routes.routes[id: id]?.state = .counter(childState)
          }

        case .settings(.binding(let bindingAction)):
          if let isEnabled = BindingAction<SettingsFeature.State>.allCasePaths.isNotificationsEnabled
            .extract(from: bindingAction),
            case .settings(var childState) = state.routes.routes[id: id]?.state {
            childState.isNotificationsEnabled = isEnabled
            state.routes.routes[id: id]?.state = .settings(childState)
          }
          }
        }

        return .none
      }
    }
  }
}

extension AppCoordinator.AppScreen.State: Equatable {}

final class DemoSession: Equatable, Sendable {
  let name: String

  init(name: String) {
    self.name = name
  }

  static func == (lhs: DemoSession, rhs: DemoSession) -> Bool {
    lhs === rhs || lhs.name == rhs.name
  }
}

struct AppCoordinatorView: View {
  @SwiftUI.Bindable var store: StoreOf<AppCoordinator>

  init(store: StoreOf<AppCoordinator>) {
    self.store = store
  }

  var body: some View {
    TCARouter(
      self.store.scope(
        state: \.routes,
        action: \.route
      )
    ) { screen in
      switch screen.case {
      case .home(let homeStore):
        HomeView(store: homeStore)
          .navigationTitle("TCAFlow")

      case .single(let singleStore):
        SingleView(store: singleStore)
          .navigationTitle("One View")

      case .counter(let counterStore):
        CounterView(store: counterStore)
          .navigationTitle("Counter")

      case .summary(let summaryStore):
        SummaryView(store: summaryStore)
          .navigationTitle("Summary")

      case .settings(let settingsStore):
        SettingsView(store: settingsStore)
          .navigationTitle("Settings")
      }
    }
    .animation(.easeInOut(duration: 0.1), value: self.store.routes.count)
    .transaction { transaction in
      if self.store.routes.count > 1 {
        transaction.animation = .easeInOut(duration: 0.1)
      }
    }
  }
}
