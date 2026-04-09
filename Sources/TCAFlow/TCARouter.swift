import ComposableArchitecture
import SwiftUI
import Perception

/// A SwiftUI view that renders a navigation flow based on an array of routes.
/// Usage: TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in ... }
@MainActor
public struct TCAFlowRouter<Screen, ScreenAction, ScreenContent: View>: View {
    private let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    private let screenView: (Screen) -> ScreenContent

    public init(
        _ store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
        @ViewBuilder screenView: @escaping (Screen) -> ScreenContent
    ) {
        self.store = store
        self.screenView = screenView
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.withState { $0 }

            if let rootRoute = routes.first {
                if rootRoute.embedInNavigationView {
                    NavigationStack {
                        screenView(rootRoute.screen)
                            .navigationDestination(for: Int.self) { index in
                                if index > 0 && index < routes.count {
                                    screenView(routes[index].screen)
                                }
                            }
                    }
                } else {
                    screenView(rootRoute.screen)
                }
            } else {
                Text("No Routes")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Route Helpers

extension Route {
    /// Whether this route is a sheet presentation.
    public var isSheet: Bool {
        if case .sheet = self { return true }
        return false
    }

    /// Whether this route is a cover presentation.
    public var isCover: Bool {
        if case .cover = self { return true }
        return false
    }
}