@_spi(Internals) import ComposableArchitecture
import SwiftUI

public struct TCARouter<ScreenState: Equatable, ScreenAction, ScreenView: View>: View {
    @SwiftUI.Bindable private var store: Store<RouteStack<ScreenState>, FlowAction<ScreenAction>>
    private let screenView: (Store<ScreenState, ScreenAction>) -> ScreenView

    public init(
        _ store: Store<RouteStack<ScreenState>, FlowAction<ScreenAction>>,
        @ViewBuilder screenView: @escaping (Store<ScreenState, ScreenAction>) -> ScreenView
    ) {
        self._store = SwiftUI.Bindable(wrappedValue: store)
        self.screenView = screenView
    }

    public var body: some View {
        let routes = self.store.state

        SwiftUI.NavigationStack {
            Group {
                if let route = routes.routes.last {
                    self.makeScreen(route: route)
                        .id(route.id)
                } else {
                    Text("No Routes")
                        .foregroundStyle(.secondary)
                }
            }
            .toolbar {
                if routes.routes.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            let path = Array(routes.routes.dropFirst().dropLast().map(\.id))
                            self.store.send(.pathChanged(path))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func makeScreen(route: Route<ScreenState>) -> some View {
        if let store = self.store.scope(
            state: \.routes[id: route.id]?.state,
            action: \.element[id: route.id]
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
