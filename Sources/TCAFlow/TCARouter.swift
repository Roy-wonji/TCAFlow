@_spi(Internals) import ComposableArchitecture
import SwiftUI

public struct TCARouter<ScreenState: Equatable, ScreenAction, ScreenView: View>: View {
  private let store: Store<RouteStack<ScreenState>, FlowAction<ScreenAction>>
  private let screenView: (Store<ScreenState, ScreenAction>) -> ScreenView

  public init(
    _ store: Store<RouteStack<ScreenState>, FlowAction<ScreenAction>>,
    @ViewBuilder screenView: @escaping (Store<ScreenState, ScreenAction>) -> ScreenView
  ) {
    self.store = store
    self.screenView = screenView
  }

  public var body: some View {
    WithPerceptionTracking {
      let routes = self.store.state.routes
      let routeIDs = routes.map(\.id)
      let topRouteID = routeIDs.last
      let routeCount = routeIDs.count
      let backPath = Array(routeIDs.dropFirst().dropLast())

      SwiftUI.NavigationStack {
        WithPerceptionTracking {
          self.routeContent(routeID: topRouteID)
        }
        .toolbar {
          if routeCount > 1 {
            ToolbarItem(placement: .automatic) {
              Button("Back") {
                self.store.send(.pathChanged(backPath))
              }
            }
          }
        }
        .animation(.easeInOut(duration: 0.1), value: routeCount)
        .transaction { transaction in
          if routeCount > 1 {
            transaction.animation = .easeInOut(duration: 0.1)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func routeContent(routeID: UUID?) -> some View {
    if let routeID {
      self.makeScreen(routeID: routeID)
        .id(routeID)
    } else {
      Text("No Routes")
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func makeScreen(routeID: UUID) -> some View {
    if let store = self.store.scope(
      state: \.routes[id: routeID]?.state,
      action: \.element[id: routeID]
    ) {
      self.screenView(store)
    } else {
      EmptyView()
    }
  }
}

extension View {
  public func slideTransition() -> some View {
    self.transition(
      .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
      )
    )
  }

  public func fadeTransition() -> some View {
    self.transition(.opacity)
  }

  public func scaleTransition() -> some View {
    self.transition(.scale.combined(with: .opacity))
  }

  public func leadingTransition() -> some View {
    self.transition(
      .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
      )
    )
  }

  public func bottomTransition() -> some View {
    self.transition(
      .asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
      )
    )
  }
}
