// A scoped Store can outlive its route during a SwiftUI removal transition.
// Keep its last state instead of redirecting the key path to another route.
// Access is confined to the main-actor Store and router.
final class _RouteScreenState<Screen>: Hashable {
    let index: Int
    private var value: Screen
    private(set) var isAttached = true

    init(index: Int, value: Screen) {
        self.index = index
        self.value = value
    }

    func read(from routes: [Route<Screen>]) -> Screen {
        if isAttached {
            if routes.indices.contains(index) {
                value = routes[index].screen
            } else {
                isAttached = false
            }
        }
        return value
    }

    func attach(value: Screen) {
        self.value = value
        isAttached = true
    }

    static func == (lhs: _RouteScreenState, rhs: _RouteScreenState) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

@MainActor
final class _RouteScreenStateCache<Screen> {
    private var states: [Int: _RouteScreenState<Screen>] = [:]

    init(routes: [Route<Screen>] = []) {
        update(routes)
    }

    func update(_ routes: [Route<Screen>]) {
        for state in states.values {
            _ = state.read(from: routes)
        }

        for index in routes.indices {
            let value = routes[index].screen
            if let state = states[index] {
                if !state.isAttached {
                    state.attach(value: value)
                }
            } else {
                states[index] = _RouteScreenState(index: index, value: value)
            }
        }
    }

    func state(at index: Int, routes: [Route<Screen>]) -> _RouteScreenState<Screen> {
        update(routes)
        guard let state = states[index] else {
            preconditionFailure("A route screen must be cached before it is rendered.")
        }
        // Routes are index-addressed. Reuse the same scope key on a later push
        // so TCA's child-store cache does not grow for every push/pop cycle.
        return state
    }
}

extension Array {
    subscript<Screen>(retaining state: _RouteScreenState<Screen>) -> Screen
    where Element == Route<Screen> {
        state.read(from: self)
    }
}
