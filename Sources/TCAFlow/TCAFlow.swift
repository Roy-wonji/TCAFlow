import ComposableArchitecture
import Foundation
import SwiftUI

/// A route represents a navigation destination and how it should be presented.
/// Identical to TCACoordinators Route API
@CasePathable
public enum Route<Screen> {
    case root(Screen, embedInNavigationView: Bool = true)
    case push(Screen)
    case sheet(Screen, embedInNavigationView: Bool = false)
    case cover(Screen, embedInNavigationView: Bool = false)

    /// The screen data for this route.
    public var screen: Screen {
        get {
            switch self {
            case let .root(screen, _),
                 let .push(screen),
                 let .sheet(screen, _),
                 let .cover(screen, _):
                return screen
            }
        }
        set {
            switch self {
            case let .root(_, embedInNavigationView):
                self = .root(newValue, embedInNavigationView: embedInNavigationView)
            case .push:
                self = .push(newValue)
            case let .sheet(_, embedInNavigationView):
                self = .sheet(newValue, embedInNavigationView: embedInNavigationView)
            case let .cover(_, embedInNavigationView):
                self = .cover(newValue, embedInNavigationView: embedInNavigationView)
            }
        }
    }

    /// Whether this route should be embedded in a NavigationView/NavigationStack.
    public var embedInNavigationView: Bool {
        switch self {
        case let .root(_, embedInNavigationView),
             let .sheet(_, embedInNavigationView),
             let .cover(_, embedInNavigationView):
            return embedInNavigationView
        case .push:
            return false // Push routes are already in a NavigationStack
        }
    }

    /// Whether this route is presented modally (sheet or cover).
    public var isPresented: Bool {
        switch self {
        case .root, .push:
            return false
        case .sheet, .cover:
            return true
        }
    }

    /// Maps the screen data to a new type while preserving the route style.
    public func map<NewScreen>(_ transform: (Screen) -> NewScreen) -> Route<NewScreen> {
        switch self {
        case let .root(screen, embedInNavigationView):
            return .root(transform(screen), embedInNavigationView: embedInNavigationView)
        case let .push(screen):
            return .push(transform(screen))
        case let .sheet(screen, embedInNavigationView):
            return .sheet(transform(screen), embedInNavigationView: embedInNavigationView)
        case let .cover(screen, embedInNavigationView):
            return .cover(transform(screen), embedInNavigationView: embedInNavigationView)
        }
    }
}

// MARK: - Route + Equatable

extension Route: Equatable where Screen: Equatable {
    public static func == (lhs: Route<Screen>, rhs: Route<Screen>) -> Bool {
        switch (lhs, rhs) {
        case let (.root(lhsScreen, lhsEmbed), .root(rhsScreen, rhsEmbed)):
            return lhsScreen == rhsScreen && lhsEmbed == rhsEmbed
        case let (.push(lhsScreen), .push(rhsScreen)):
            return lhsScreen == rhsScreen
        case let (.sheet(lhsScreen, lhsEmbed), .sheet(rhsScreen, rhsEmbed)):
            return lhsScreen == rhsScreen && lhsEmbed == rhsEmbed
        case let (.cover(lhsScreen, lhsEmbed), .cover(rhsScreen, rhsEmbed)):
            return lhsScreen == rhsScreen && lhsEmbed == rhsEmbed
        default:
            return false
        }
    }
}

// MARK: - Route + Sendable

extension Route: @unchecked Sendable where Screen: Sendable {}

// MARK: - RouterAction

/// Action type for handling route updates and screen actions.
/// Based on TCACoordinators RouterAction structure.
@CasePathable
public enum RouterAction<ID: Hashable, Screen, ScreenAction> {
    case updateRoutes([Route<Screen>])
    case routeAction(ID, ScreenAction)
}

// MARK: - RouterAction Extensions

extension RouterAction {
    public var updateRoutesValue: [Route<Screen>]? {
        guard case let .updateRoutes(routes) = self else { return nil }
        return routes
    }

    public var routeActionValue: (ID, ScreenAction)? {
        guard case let .routeAction(id, action) = self else { return nil }
        return (id, action)
    }
}

// MARK: - Collection + Safe Subscript

extension Collection {
    /// Safe subscript that returns nil if index is out of bounds.
    public subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Array + Route Utilities

extension Array {
    /// The current (topmost) route in the navigation stack.
    public var currentRoute: Element? {
        return self.last
    }

    /// The root (first) route in the navigation stack.
    public var rootRoute: Element? {
        return self.first
    }

    /// The depth of the navigation stack.
    public var depth: Int {
        return self.count
    }

    /// Pushes a new screen onto the navigation stack.
    public mutating func push<Screen>(_ screen: Screen) where Element == Route<Screen> {
        self.append(.push(screen))
    }

    /// Presents a screen as a sheet.
    public mutating func presentSheet<Screen>(_ screen: Screen, embedInNavigationView: Bool = false) where Element == Route<Screen> {
        self.append(.sheet(screen, embedInNavigationView: embedInNavigationView))
    }

    /// Presents a screen as a full screen cover.
    public mutating func presentCover<Screen>(_ screen: Screen, embedInNavigationView: Bool = false) where Element == Route<Screen> {
        self.append(.cover(screen, embedInNavigationView: embedInNavigationView))
    }

    /// Pops the topmost route from the navigation stack.
    @discardableResult
    public mutating func pop() -> Element? {
        return self.popLast()
    }

    /// Goes back by one step (same as pop)
    @discardableResult
    public mutating func goBack() -> Element? {
        return self.pop()
    }

    /// Pops back to the root route.
    public mutating func popToRoot() {
        if let root = self.first {
            self = [root]
        }
    }

    /// Goes back to root (same as popToRoot)
    public mutating func goBackToRoot() {
        popToRoot()
    }

    /// Dismisses the topmost presented route (sheet or cover).
    @discardableResult
    public mutating func dismiss() -> Element? {
        guard !self.isEmpty else { return nil }
        let last = self.last!

        // Check if it's a Route type and if it's presented
        if let route = last as? Route<Any>, route.isPresented {
            return self.removeLast()
        }
        return nil
    }

    /// Goes back to a specific screen case using AnyCasePath
    public mutating func goBackTo<Screen, Value>(_ casePath: AnyCasePath<Screen, Value>) where Element == Route<Screen> {
        while let last = self.last {
            if casePath.extract(from: last.screen) != nil {
                break
            }
            self.removeLast()
        }
    }

    /// Goes to a specific screen, popping if it exists or pushing if it doesn't
    public mutating func goTo<Screen>(_ screen: Screen) where Element == Route<Screen> {
        // Check if screen already exists in stack
        if let index = self.firstIndex(where: { route in
            matchesScreenCase(route.screen, target: screen)
        }) {
            // Pop to that screen
            while self.count > index + 1 {
                self.removeLast()
            }
        } else {
            // Push new screen
            push(screen)
        }
    }

    /// Replaces current screen with new screen
    public mutating func replaceCurrent<Screen>(with screen: Screen) where Element == Route<Screen> {
        guard !self.isEmpty else {
            push(screen)
            return
        }
        self[self.count - 1] = .push(screen)
    }
}

// MARK: - routeWithDelaysIfUnsupported helper

/// TCACoordinators-style helper for handling route updates with delays
public func routeWithDelaysIfUnsupported<Action, Screen, ScreenAction>(
    _ routes: [Route<Screen>],
    action keyPath: AnyCasePath<Action, RouterAction<Int, Screen, ScreenAction>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: (inout [Route<Screen>]) -> Void
) -> Effect<Action> {
    var newRoutes = routes
    update(&newRoutes)

    let routerAction = RouterAction<Int, Screen, ScreenAction>.updateRoutes(newRoutes)
    return Effect.send(keyPath.embed(routerAction))
}

// MARK: - Helper Functions

/// Helper function to match screen cases
private func matchesScreenCase<Screen>(_ screen1: Screen, target screen2: Screen) -> Bool {
    // This is a simplified implementation
    // In a real scenario, you'd want to compare enum cases properly
    return String(describing: screen1).split(separator: "(").first ==
           String(describing: screen2).split(separator: "(").first
}

// MARK: - Type Aliases

/// Convenience type alias for indexed router actions.
public typealias IndexedRouterAction<Screen, ScreenAction> = RouterAction<Int, Screen, ScreenAction>

/// Convenience type alias for indexed router actions with reducer.
public typealias IndexedRouterActionOf<R: Reducer> = RouterAction<Int, R.State, R.Action>

/// Convenience type alias for identified router actions.
public typealias IdentifiedRouterAction<Screen: Identifiable, ScreenAction> = RouterAction<Screen.ID, Screen, ScreenAction>

/// Convenience type alias for identified router actions with reducer.
public typealias IdentifiedRouterActionOf<R: Reducer> = RouterAction<R.State.ID, R.State, R.Action> where R.State: Identifiable

// MARK: - Debugging Utilities

#if DEBUG
/// Runtime warning function for debugging.
public func runtimeWarn(
    _ message: @autoclosure () -> String,
    category: String? = nil,
    file: StaticString = #file,
    line: UInt = #line
) {
    let message = message()
    let category = category ?? "TCAFlow"

    #if canImport(os)
    import os
    os_log(
        .fault,
        dso: #dsohandle,
        log: OSLog(subsystem: "com.tcaflow", category: category),
        "%@",
        message
    )
    #else
    print("[\(category)] \(message)")
    #endif
}
#else
public func runtimeWarn(
    _ message: @autoclosure () -> String,
    category: String? = nil,
    file: StaticString = #file,
    line: UInt = #line
) {}
#endif