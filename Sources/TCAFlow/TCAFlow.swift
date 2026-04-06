import ComposableArchitecture
import Foundation

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

public struct FlowAction<Action> {
    public let id: UUID
    public var action: Action

    public init(id: UUID, action: Action) {
        self.id = id
        self.action = action
    }
}

public typealias FlowActionOf<Screen: Reducer> = FlowAction<Screen.Action>

extension IdentifiedArrayOf where Element.ID == UUID {
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

extension IdentifiedArrayOf where Element == Route<some Equatable> {
}

extension IdentifiedArrayOf {
    public mutating func push<S: Equatable>(_ state: S) where Element == Route<S> {
        self.append(Route(state))
    }

    @discardableResult
    public mutating func pop() -> Element? {
        guard !self.isEmpty else { return nil }
        return self.removeLast()
    }

    public mutating func popToRoot() {
        guard let first = self.first else { return }
        self = [first]
    }

    public mutating func replace<S: Equatable>(with state: S) where Element == Route<S> {
        guard let currentRoute else {
            self.push(state)
            return
        }
        self[id: currentRoute.id]?.state = state
    }

    public var currentScreen<S: Equatable>: S? where Element == Route<S> {
        self.last?.state
    }

    public var rootScreen<S: Equatable>: S? where Element == Route<S> {
        self.first?.state
    }

    public func has<S: Equatable>(_ targetScreen: S) where Element == Route<S> -> Bool {
        self.contains { $0.state.matchesCase(of: targetScreen) }
    }

    public mutating func goTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        if let index = self.firstIndex(where: { $0.state.matchesCase(of: targetScreen) }) {
            self.removeSubrange((index + 1)...)
        } else {
            self.append(Route(targetScreen))
        }
    }

    public mutating func goBackTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        while let last = self.last, !last.state.matchesCase(of: targetScreen) {
            self.removeLast()
        }
    }

    public mutating func reduce<Screen: Reducer>(
        _ flowAction: FlowAction<Screen.Action>,
        with reducer: Screen
    ) -> Effect<FlowAction<Screen.Action>>
    where Element == Route<Screen.State>, Screen.State: Equatable {
        guard let route = self[id: flowAction.id] else {
            return .none
        }

        var routeState = route.state
        let effect = reducer.reduce(into: &routeState, action: flowAction.action)
        self[id: flowAction.id]?.state = routeState

        return effect.map { FlowAction(id: flowAction.id, action: $0) }
    }
}

private extension Equatable {
    func matchesCase(of other: Self) -> Bool {
        String(describing: self).split(separator: "(").first
            == String(describing: other).split(separator: "(").first
    }
}
