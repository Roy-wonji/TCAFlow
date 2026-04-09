import ComposableArchitecture
import SwiftUI
import Perception

// MARK: - CaseStore

/// A wrapper that provides TCACoordinators-style case access to screen stores
public struct CaseStore<Screen> {
    public let screen: Screen

    init(screen: Screen) {
        self.screen = screen
    }

    /// Provides .case access for switch statements
    public var `case`: Screen {
        return screen
    }
}

/// TCACoordinators-style router view
/// Usage: TCARouter(store.scope(state: \.routes, action: \.router)) { screen in ... }
@MainActor
public struct TCARouter<Screen, ScreenAction, ScreenContent: View>: View {
    private let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    private let screenView: (CaseStore<Screen>) -> ScreenContent

    public init(
        _ store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
        @ViewBuilder content: @escaping (CaseStore<Screen>) -> ScreenContent
    ) {
        self.store = store
        self.screenView = content
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.withState { $0 }

            if let rootRoute = routes.first {
                if rootRoute.embedInNavigationView {
                    NavigationStack {
                        screenView(CaseStore(screen: rootRoute.screen))
                            .navigationDestination(for: Int.self) { index in
                                if index > 0 && index < routes.count {
                                    screenView(CaseStore(screen: routes[index].screen))
                                }
                            }
                    }
                } else {
                    screenView(CaseStore(screen: rootRoute.screen))
                }
            } else {
                Text("No Routes")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Type Alias

/// Alias for TCARouter to maintain compatibility with TCAFlowRouter name
public typealias TCAFlowRouter<Screen, ScreenAction, ScreenContent: View> = TCARouter<Screen, ScreenAction, ScreenContent>

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