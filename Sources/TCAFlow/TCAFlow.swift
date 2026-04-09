import ComposableArchitecture
import Foundation
import SwiftUI

/// A route represents a navigation destination and how it should be presented.
/// Based on TCACoordinators/FlowStacks architecture but with NavigationStack.
@CasePathable
public enum Route<Screen>: RouteProtocol {
    case push(Screen)
    case sheet(Screen, withNavigation: Bool = false)
    case cover(Screen, withNavigation: Bool = false)

    /// The screen data for this route.
    public var screen: Screen {
        get {
            switch self {
            case let .push(screen), let .sheet(screen, _), let .cover(screen, _):
                return screen
            }
        }
        set {
            switch self {
            case .push:
                self = .push(newValue)
            case let .sheet(_, withNavigation):
                self = .sheet(newValue, withNavigation: withNavigation)
            case let .cover(_, withNavigation):
                self = .cover(newValue, withNavigation: withNavigation)
            }
        }
    }

    /// Whether this route should be embedded in a NavigationView/NavigationStack.
    public var withNavigation: Bool {
        switch self {
        case .push:
            return false  // Push routes are already in a NavigationStack
        case let .sheet(_, withNavigation), let .cover(_, withNavigation):
            return withNavigation
        }
    }

    /// Whether this route is presented modally (sheet or cover).
    public var isPresented: Bool {
        switch self {
        case .push:
            return false
        case .sheet, .cover:
            return true
        }
    }

    /// Maps the screen data to a new type while preserving the route style.
    public func map<NewScreen>(_ transform: (Screen) -> NewScreen) -> Route<NewScreen> {
        switch self {
        case let .push(screen):
            return .push(transform(screen))
        case let .sheet(screen, withNavigation):
            return .sheet(transform(screen), withNavigation: withNavigation)
        case let .cover(screen, withNavigation):
            return .cover(transform(screen), withNavigation: withNavigation)
        }
    }
}

// MARK: - RouteProtocol

/// Protocol that all route types must conform to.
public protocol RouteProtocol {
    associatedtype Screen

    var screen: Screen { get set }
    var withNavigation: Bool { get }
    var isPresented: Bool { get }
}

// MARK: - Route + Equatable

extension Route: Equatable where Screen: Equatable {
    public static func == (lhs: Route<Screen>, rhs: Route<Screen>) -> Bool {
        switch (lhs, rhs) {
        case let (.push(lhsScreen), .push(rhsScreen)):
            return lhsScreen == rhsScreen
        case let (.sheet(lhsScreen, lhsNav), .sheet(rhsScreen, rhsNav)):
            return lhsScreen == rhsScreen && lhsNav == rhsNav
        case let (.cover(lhsScreen, lhsNav), .cover(rhsScreen, rhsNav)):
            return lhsScreen == rhsScreen && lhsNav == rhsNav
        default:
            return false
        }
    }
}

// MARK: - Route + Sendable

extension Route: @unchecked @retroactive Sendable where Screen: Sendable {}

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

extension Array where Element == Route<some Any> {
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

    /// Whether the navigation stack is empty.
    public var isEmpty: Bool {
        return self.count == 0
    }
}

extension Array {
    /// Pushes a new screen onto the navigation stack.
    public mutating func push<Screen>(_ screen: Screen) where Element == Route<Screen> {
        self.append(.push(screen))
    }

    /// Presents a screen as a sheet.
    public mutating func presentSheet<Screen>(_ screen: Screen, withNavigation: Bool = false) where Element == Route<Screen> {
        self.append(.sheet(screen, withNavigation: withNavigation))
    }

    /// Presents a screen as a full screen cover.
    public mutating func presentCover<Screen>(_ screen: Screen, withNavigation: Bool = false) where Element == Route<Screen> {
        self.append(.cover(screen, withNavigation: withNavigation))
    }

    /// Pops the topmost route from the navigation stack.
    @discardableResult
    public mutating func pop() -> Element? {
        return self.popLast()
    }

    /// Pops back to the root route.
    public mutating func popToRoot() {
        if let root = self.first {
            self = [root]
        }
    }

    /// Dismisses the topmost presented route (sheet or cover).
    @discardableResult
    public mutating func dismiss() -> Element? {
        guard let last = self.last, last.isPresented else {
            return nil
        }
        return self.removeLast()
    }

    /// Goes back to a specific screen type.
    public mutating func goBackTo<Screen>(_ screenType: Screen.Type) where Element == Route<Screen> {
        while let last = self.last,
              !isScreenOfType(last.screen, type: screenType) {
            self.removeLast()
        }
    }
}

// MARK: - Helper Functions

private func isScreenOfType<Screen>(_ screen: Screen, type: Screen.Type) -> Bool {
    return type(of: screen) == type
}

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