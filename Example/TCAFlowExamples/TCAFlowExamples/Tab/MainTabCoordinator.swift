import ComposableArchitecture
import TCAFlow
import SwiftUI

// MARK: - MainTabCoordinator

@Reducer
struct MainTabCoordinator {
  @ObservableState
  struct State: Equatable {
    var selectedTab: Int = 0
    var demoState: DemoCoordinator.State
    var showcaseState: ShowcaseCoordinator.State

    init() {
      self.demoState = .init(routes: [.root(.home(.init()), embedInNavigationView: true)])
      self.showcaseState = .init(routes: [.root(.menu(.init()), embedInNavigationView: true)])
    }
  }

  enum Action {
    case selectTab(Int)
    case tabReselected(Int)
    case demo(DemoCoordinator.Action)
    case showcase(ShowcaseCoordinator.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.demoState, action: \.demo) {
      DemoCoordinator()
    }
    Scope(state: \.showcaseState, action: \.showcase) {
      ShowcaseCoordinator()
    }
    Reduce { state, action in
      switch action {
      case .selectTab(let tab):
        state.selectedTab = tab
        return .none

      case .tabReselected(let tab):
        // 활성 탭 재탭 → popToRoot
        switch tab {
        case 0: state.demoState.routes.goBackToRoot()
        case 1: state.showcaseState.routes.goBackToRoot()
        default: break
        }
        return .none

      case .demo, .showcase:
        return .none
      }
    }
  }
}
