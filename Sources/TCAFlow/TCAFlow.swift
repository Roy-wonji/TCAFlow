import ComposableArchitecture
import Foundation
import IdentifiedCollections

@ObservableState
public struct Route<State: Equatable>: Identifiable, Equatable, Hashable {
    public let id: UUID
    public var state: State

    public init(id: UUID = UUID(), _ state: State) {
        self.id = id
        self.state = state
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}

@ObservableState
public struct RouteStack<State: Equatable>: Equatable {
    public var routes: IdentifiedArrayOf<Route<State>>

    public init(_ routes: IdentifiedArrayOf<Route<State>> = []) {
        self.routes = routes
    }

    public init(_ routes: [Route<State>]) {
        self.routes = IdentifiedArray(uniqueElements: routes)
    }
}

extension RouteStack {
    public var currentRoute: Route<State>? {
        self.routes.currentRoute
    }

    public var rootRoute: Route<State>? {
        self.routes.rootRoute
    }

    public var depth: Int {
        self.routes.depth
    }

    public var count: Int {
        self.routes.count
    }

    public var isEmpty: Bool {
        self.routes.isEmpty
    }

    public mutating func push(_ state: State) {
        self.routes.push(state)
    }

    @discardableResult
    public mutating func pop() -> Route<State>? {
        self.routes.pop()
    }

    public mutating func popToRoot() {
        self.routes.popToRoot()
    }

    public mutating func replace(with state: State) {
        self.routes.replace(with: state)
    }

    public mutating func goTo(_ targetScreen: State) {
        self.routes.goTo(targetScreen)
    }

    public mutating func goBackTo(_ targetScreen: State) {
        self.routes.goBackTo(targetScreen)
    }
}

@CasePathable
public enum FlowAction<Action> {
    case element(IdentifiedAction<UUID, Action>)
    case pathChanged([UUID])

    public var element: (id: UUID, action: Action)? {
        guard case let .element(.element(id, action)) = self else { return nil }
        return (id, action)
    }
}

public typealias FlowActionOf<Screen: Reducer> = FlowAction<Screen.Action>

public protocol FlowCoordinating: Reducer {
    associatedtype ScreenState: Equatable
    associatedtype ScreenAction

    static var flowRoutes: KeyPath<State, RouteStack<ScreenState>> { get }
    static func flowAction(_ action: FlowAction<ScreenAction>) -> Action
}

extension IdentifiedArray where ID == UUID {
    public var currentRoute: Element? {
        self.last
    }

    public var rootRoute: Element? {
        self.first
    }

    public var depth: Int {
        self.count
    }
}

extension IdentifiedArray where ID == UUID {
    public mutating func push<S: Equatable>(_ state: S) where Element == Route<S> {
        self.append(Route(state))
    }

    @discardableResult
    public mutating func pop() -> Element? {
        guard !self.isEmpty else { return nil }
        return self.removeLast()
    }

    public mutating func popToRoot() {
        while self.count > 1 {
            self.removeLast()
        }
    }

    public mutating func replace<S: Equatable>(with state: S) where Element == Route<S> {
        guard let currentRoute else {
            self.push(state)
            return
        }
        self[id: currentRoute.id]?.state = state
    }

    public func currentScreen<S: Equatable>() -> S? where Element == Route<S> {
        self.last?.state
    }

    public func rootScreen<S: Equatable>() -> S? where Element == Route<S> {
        self.first?.state
    }

    public func has<S: Equatable>(_ targetScreen: S) -> Bool where Element == Route<S> {
        self.contains { $0.state.matchesCase(of: targetScreen) }
    }

    public mutating func goTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        if let index = self.firstIndex(where: { $0.state.matchesCase(of: targetScreen) }) {
            while self.count > index + 1 {
                self.removeLast()
            }
        } else {
            self.append(Route(targetScreen))
        }
    }

    public mutating func goBackTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        while let last = self.last, !last.state.matchesCase(of: targetScreen) {
            self.removeLast()
        }
    }

}

private extension Equatable {
    func matchesCase(of other: Self) -> Bool {
        String(describing: self).split(separator: "(").first
            == String(describing: other).split(separator: "(").first
    }
}
