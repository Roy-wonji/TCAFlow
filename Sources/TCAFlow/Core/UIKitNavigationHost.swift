#if os(iOS)
import SwiftUI
import UIKit

// Prototype-only identities are independent of Screen and TCA's scoped-store cache.
struct _UIKitNavigationEntryID: Hashable {
    let coordinatorID: UUID
    let index: Int
    let generation: UUID
}

@MainActor
struct _UIKitNavigationEntry {
    let id: _UIKitNavigationEntryID
    let content: AnyView
}

// Intentionally not selected by TCAFlowRouter until UI compatibility is verified.
@MainActor
struct _UIKitNavigationHost: UIViewControllerRepresentable {
    var entries: [_UIKitNavigationEntry]
    var onPop: ([_UIKitNavigationEntryID]) -> Void

    func makeCoordinator() -> _UIKitNavigationDriver {
        _UIKitNavigationDriver()
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigation = UINavigationController()
        context.coordinator.attach(to: navigation)
        context.coordinator.update(entries, onPop: onPop, animated: false)
        return navigation
    }

    func updateUIViewController(_ navigation: UINavigationController, context: Context) {
        context.coordinator.update(
            entries,
            onPop: onPop,
            animated: !context.transaction.disablesAnimations
        )
    }

    static func dismantleUIViewController(
        _ navigation: UINavigationController,
        coordinator: _UIKitNavigationDriver
    ) {
        coordinator.invalidate()
    }
}

@MainActor
final class _UIKitNavigationDriver: NSObject, UINavigationControllerDelegate {
    private weak var navigation: UINavigationController?
    private var state = _NavigationStackState<_UIKitNavigationEntryID>()
    private var controllers: [_UIKitNavigationEntryID: UIHostingController<AnyView>] = [:]
    private var entries: [_UIKitNavigationEntry] = []
    private var onPop: ([_UIKitNavigationEntryID]) -> Void = { _ in }
    private var scheduled = false
    private var isActive = true
    private var animatesChanges = false
    private var isFinishing = false
    private var completionToken: UInt64?

    // This driver owns only a fresh navigation controller. External UIKit
    // attachment requires its own delegate/prefix agreement before integration.
    func attach(to navigation: UINavigationController) {
        precondition(self.navigation == nil && navigation.viewControllers.isEmpty)
        precondition(navigation.delegate == nil)
        self.navigation = navigation
        navigation.delegate = self
    }

    func update(
        _ entries: [_UIKitNavigationEntry],
        onPop: @escaping ([_UIKitNavigationEntryID]) -> Void,
        animated: Bool
    ) {
        guard isActive else { return }
        let ids = entries.map(\.id)
        precondition(Set(ids).count == ids.count, "Navigation entry identities must be unique.")
        self.entries = entries
        self.onPop = onPop
        animatesChanges = animated
        state.update(ids)
        // Data updates refresh SwiftUI content without changing the UIKit stack.
        for entry in entries {
            controllers[entry.id]?.rootView = entry.content
        }
        reconcile()
    }

    func invalidate() {
        guard isActive else { return }
        isActive = false
        state.invalidate()
        completionToken = nil
        if navigation?.delegate === self { navigation?.delegate = nil }
        navigation = nil
        entries = []
        controllers = [:]
        onPop = { _ in }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        guard isActive, navigationController === navigation else { return }
        // Programmatic changes already have a token; UIKit back gestures do not.
        if state.transition == nil { _ = state.beginUserTransition() }
        if animated, let transition = state.transition,
           let coordinator = navigationController.transitionCoordinator,
           completionToken != transition.token {
            completionToken = transition.token
            coordinator.animate(alongsideTransition: nil) { [weak self] context in
                self?.finish(transition, cancelled: context.isCancelled)
            }
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard isActive, navigationController === navigation,
              let transition = state.transition else { return }
        guard completionToken != transition.token else { return }
        finish(transition)
    }

    private func reconcile() {
        guard isActive, !isFinishing, let navigation, let transition = state.begin() else { return }
        let destination = entries.map { entry in
            if let controller = controllers[entry.id] { return controller }
            let controller = UIHostingController(rootView: entry.content)
            controllers[entry.id] = controller
            return controller
        }
        let animated = animatesChanges && navigation.viewIfLoaded?.window != nil
        navigation.setViewControllers(destination, animated: animated)
        // Offscreen/nonanimated changes do not need an appearance callback to settle.
        if !animated { finish(transition) }
    }

    private func finish(
        _ transition: _NavigationStackState<_UIKitNavigationEntryID>.Transition,
        cancelled: Bool = false
    ) {
        guard isActive, let navigation, state.transition?.token == transition.token else { return }
        let lookup = Dictionary(uniqueKeysWithValues: controllers.map {
            (ObjectIdentifier($0.value), $0.key)
        })
        let actual = navigation.viewControllers.compactMap { lookup[ObjectIdentifier($0)] }
        guard actual.count == navigation.viewControllers.count else {
            // This prototype must never take over controllers it did not create.
            invalidate()
            return
        }
        isFinishing = true
        completionToken = nil
        let removed = state.complete(transition, actual: actual, cancelled: cancelled)
        let removedIDs = Set(removed)
        entries.removeAll { removedIDs.contains($0.id) }
        if !removed.isEmpty { onPop(removed) }
        let retained = Set(state.desired + state.displayed)
        controllers = controllers.filter { retained.contains($0.key) }
        isFinishing = false
        scheduleReconcile()
    }

    private func scheduleReconcile() {
        guard isActive, !scheduled else { return }
        scheduled = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.scheduled = false
            self.reconcile()
        }
    }
}
#endif
