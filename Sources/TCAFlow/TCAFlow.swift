import ComposableArchitecture
import CasePaths
import Foundation
import SwiftUI

// MARK: - Route

/// A route represents a screen and how it should be presented.
/// Same as TCACoordinators Route but does NOT require Hashable.
@CasePathable
public enum Route<Screen> {
    case root(Screen, embedInNavigationView: Bool = true)
    case push(Screen)
    case sheet(Screen, embedInNavigationView: Bool = false)
    case cover(Screen, embedInNavigationView: Bool = false)

    public var screen: Screen {
        get {
            switch self {
            case let .root(s, _), let .push(s), let .sheet(s, _), let .cover(s, _):
                return s
            }
        }
        set {
            switch self {
            case let .root(_, embed): self = .root(newValue, embedInNavigationView: embed)
            case .push: self = .push(newValue)
            case let .sheet(_, embed): self = .sheet(newValue, embedInNavigationView: embed)
            case let .cover(_, embed): self = .cover(newValue, embedInNavigationView: embed)
            }
        }
    }

    public var embedInNavigationView: Bool {
        switch self {
        case let .root(_, v), let .sheet(_, v), let .cover(_, v): return v
        case .push: return false
        }
    }

    public var isPresented: Bool {
        switch self {
        case .root, .push: return false
        case .sheet, .cover: return true
        }
    }

    public var isPush: Bool {
        if case .push = self { return true }
        return false
    }

    public func map<T>(_ transform: (Screen) -> T) -> Route<T> {
        switch self {
        case let .root(s, embed): .root(transform(s), embedInNavigationView: embed)
        case let .push(s): .push(transform(s))
        case let .sheet(s, embed): .sheet(transform(s), embedInNavigationView: embed)
        case let .cover(s, embed): .cover(transform(s), embedInNavigationView: embed)
        }
    }
}

extension Route: Equatable where Screen: Equatable {}
extension Route: @unchecked Sendable where Screen: Sendable {}

// MARK: - RouterAction

@CasePathable
public enum RouterAction<ID: Hashable, Screen, ScreenAction> {
    case updateRoutes([Route<Screen>])
    case routeAction(id: ID, action: ScreenAction)
}

extension RouterAction: Sendable where ID: Sendable, Screen: Sendable, ScreenAction: Sendable {}
extension RouterAction: Equatable where ID: Equatable, Screen: Equatable, ScreenAction: Equatable {}

// MARK: - RouterAction AllCasePaths subscript

extension RouterAction.AllCasePaths where ID: Sendable {
    /// Subscript for id-based action scoping (used by TCARouter store.scope).
    public subscript(id id: ID) -> AnyCasePath<RouterAction, ScreenAction> {
        AnyCasePath(
            embed: { @Sendable action in .routeAction(id: id, action: action) },
            extract: { @Sendable routerAction in
                guard case let .routeAction(routeID, action) = routerAction, routeID == id else { return nil }
                return action
            }
        )
    }
}

// MARK: - Type Aliases

public typealias IndexedRouterAction<Screen, ScreenAction> = RouterAction<Int, Screen, ScreenAction>
public typealias IndexedRouterActionOf<R: Reducer> = RouterAction<Int, R.State, R.Action>
public typealias IdentifiedRouterAction<Screen: Identifiable, ScreenAction> = RouterAction<Screen.ID, Screen, ScreenAction>
public typealias IdentifiedRouterActionOf<R: Reducer> = RouterAction<R.State.ID, R.State, R.Action> where R.State: Identifiable

// MARK: - Collection + Safe Subscript

extension Collection {
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Array + Route Screen Access

extension Array {
    /// Access the screen at a given index. Returns the screen at the given index,
    /// or the first screen if the index is out of bounds.
    public subscript<Screen>(screenAt index: Int) -> Screen
    where Element == Route<Screen> {
        get {
            guard indices.contains(index) else { return self[0].screen }
            return self[index].screen
        }
        set {
            guard indices.contains(index) else { return }
            self[index].screen = newValue
        }
    }
}

// MARK: - Array + Route Navigation

extension Array {
    public mutating func push<Screen>(_ screen: Screen) where Element == Route<Screen> {
        append(.push(screen))
    }

    public mutating func presentSheet<Screen>(
        _ screen: Screen, embedInNavigationView: Bool = false
    ) where Element == Route<Screen> {
        append(.sheet(screen, embedInNavigationView: embedInNavigationView))
    }

    public mutating func presentCover<Screen>(
        _ screen: Screen, embedInNavigationView: Bool = false
    ) where Element == Route<Screen> {
        append(.cover(screen, embedInNavigationView: embedInNavigationView))
    }

    public mutating func goBack<Screen>(_ count: Int = 1) where Element == Route<Screen> {
        let toRemove = Swift.min(count, Swift.max(0, self.count - 1))
        guard toRemove > 0 else { return }
        removeLast(toRemove)
    }

    public mutating func goBackToRoot<Screen>() where Element == Route<Screen> {
        guard let root = first else { return }
        self = [root]
    }

    public mutating func goBackTo<Screen, Value>(
        _ casePath: CaseKeyPath<Screen, Value>
    ) where Element == Route<Screen> {
        goBackTo(AnyCasePath(casePath))
    }

    public mutating func goBackTo<Screen, Value>(
        _ casePath: AnyCasePath<Screen, Value>
    ) where Element == Route<Screen> {
        guard let index = lastIndex(where: { casePath.extract(from: $0.screen) != nil }) else { return }
        self = Array(prefix(through: index))
    }

    public mutating func goBackTo<Screen>(
        where predicate: (Route<Screen>) -> Bool
    ) where Element == Route<Screen> {
        guard let index = lastIndex(where: predicate) else { return }
        self = Array(prefix(through: index))
    }

    public mutating func pop<Screen>(_ count: Int = 1) where Element == Route<Screen> {
        var remaining = count
        while remaining > 0, self.count > 1 {
            guard let last = self.last, last.isPush else { break }
            removeLast()
            remaining -= 1
        }
    }

    public mutating func popToRoot<Screen>() where Element == Route<Screen> {
        while self.count > 1, let last = self.last, !last.isPresented {
            removeLast()
        }
    }

    public mutating func dismiss<Screen>(_ count: Int = 1) where Element == Route<Screen> {
        var dismissed = 0
        while dismissed < count, self.count > 1 {
            if self.last!.isPresented {
                removeLast()
                dismissed += 1
            } else {
                removeLast()
            }
        }
    }

    public mutating func dismissAll<Screen>() where Element == Route<Screen> {
        guard let idx = firstIndex(where: { $0.isPresented }) else { return }
        self = Array(prefix(idx))
    }
}

// MARK: - routeWithDelaysIfUnsupported

public func routeWithDelaysIfUnsupported<Action: CasePathable, Screen, ScreenAction>(
    _ routes: [Route<Screen>],
    action keyPath: CaseKeyPath<Action, IndexedRouterAction<Screen, ScreenAction>>,
    _ update: (inout [Route<Screen>]) -> Void
) -> Effect<Action> {
    var newRoutes = routes
    update(&newRoutes)
    return Effect.send(AnyCasePath(keyPath).embed(.updateRoutes(newRoutes)))
}

// MARK: - runtimeWarn

public func runtimeWarn(
    _ message: @autoclosure () -> String,
    file: StaticString? = nil,
    line: UInt? = nil
) {
    #if DEBUG
    fputs("[TCAFlow] \(message())\n", stderr)
    #endif
}
