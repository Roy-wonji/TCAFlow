// Internal transition bookkeeping for the UIKit prototype. No Screen constraints.
struct _NavigationStackState<ID: Hashable> {
    struct Transition {
        let token: UInt64
        let revision: UInt64
        let source: [ID]
        let destination: [ID]
        let isUserInitiated: Bool
    }

    private(set) var desired: [ID] = []
    private(set) var displayed: [ID] = []
    private(set) var transition: Transition?
    private var revision: UInt64 = 0
    private var nextToken: UInt64 = 0
    private var isActive = true

    mutating func update(_ entries: [ID]) {
        guard isActive, entries != desired else { return }
        desired = entries
        revision &+= 1
    }

    mutating func begin() -> Transition? {
        guard isActive, transition == nil, displayed != desired else { return nil }
        return start(isUserInitiated: false)
    }

    mutating func beginUserTransition() -> Transition? {
        guard isActive, transition == nil else { return nil }
        return start(isUserInitiated: true)
    }

    // Only a completed user removal of an unchanged snapshot may write back.
    // A cancelled gesture has the original stack and therefore removes nothing.
    mutating func complete(_ completed: Transition, actual: [ID], cancelled: Bool = false) -> [ID] {
        guard isActive, transition?.token == completed.token else { return [] }
        transition = nil
        displayed = actual
        guard !cancelled, completed.isUserInitiated,
              completed.revision == revision,
              actual.count < completed.source.count,
              Array(completed.source.prefix(actual.count)) == actual
        else { return [] }
        desired = actual
        revision &+= 1
        return Array(completed.source.dropFirst(actual.count))
    }

    mutating func invalidate() {
        isActive = false
        transition = nil
        desired = []
        displayed = []
        revision &+= 1
    }

    private mutating func start(isUserInitiated: Bool) -> Transition {
        nextToken &+= 1
        let value = Transition(
            token: nextToken,
            revision: revision,
            source: displayed,
            destination: desired,
            isUserInitiated: isUserInitiated
        )
        transition = value
        return value
    }
}
