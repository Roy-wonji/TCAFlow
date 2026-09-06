#if os(iOS)
import SwiftUI
import UIKit

public extension View {
    /// Hides the native back button while preserving the leading-edge swipe to go back.
    ///
    /// Apply this to the pushed screen, inside its navigation stack. Passing `false`
    /// restores the native back button and the original gesture configuration.
    func swipeBackButtonHidden(_ isHidden: Bool = true) -> some View {
        navigationBarBackButtonHidden(isHidden)
            .background {
                SwipeBackGestureRestorer(isHidden: isHidden)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

private struct SwipeBackGestureRestorer: UIViewControllerRepresentable {
    let isHidden: Bool

    func makeUIViewController(context: Context) -> SwipeBackGestureController {
        SwipeBackGestureController()
    }

    func updateUIViewController(_ controller: SwipeBackGestureController, context: Context) {
        controller.isHidden = isHidden
        controller.restoreWhenReady()
    }

    static func dismantleUIViewController(_ controller: SwipeBackGestureController, coordinator: ()) {
        controller.isHidden = false
        controller.detach()
    }
}

@MainActor
final class SwipeBackGestureController: UIViewController, UIGestureRecognizerDelegate {
    var isHidden = false
    private var isVisible = false
    private weak var gesture: UIGestureRecognizer?
    private weak var originalDelegate: (any UIGestureRecognizerDelegate)?
    private var originalEnabled = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        restoreWhenReady()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Changing isEnabled during an interactive pop would cancel that gesture.
        detach()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            isVisible = false
            detach()
        } else {
            restoreWhenReady()
        }
    }

    func restoreWhenReady() {
        if !isHidden { detach() }
        DispatchQueue.main.async { [weak self] in
            self?.restoreGesture()
        }
    }

    func restoreGesture() {
        guard isHidden, isVisible,
              let navigation = navigationController,
              let top = navigation.topViewController,
              belongs(to: top),
              let recognizer = navigation.interactivePopGestureRecognizer
        else { return }

        if gesture !== recognizer || recognizer.delegate !== self {
            detach()
            // A second modifier on the same screen must not form a delegate chain.
            guard !(recognizer.delegate is SwipeBackGestureController) else { return }
            gesture = recognizer
            originalDelegate = recognizer.delegate
            originalEnabled = recognizer.isEnabled
            recognizer.delegate = self
        }
        recognizer.isEnabled = true
    }

    func detach() {
        if let gesture, gesture.delegate === self {
            gesture.delegate = originalDelegate
            // After a pop, the newly exposed screen owns the shared recognizer's
            // enabled state. Restore our snapshot only while still on this screen.
            if isVisible, let top = navigationController?.topViewController, belongs(to: top) {
                gesture.isEnabled = originalEnabled
            }
        }
        gesture = nil
        originalDelegate = nil
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isHidden, isVisible,
              let navigation = navigationController,
              let top = navigation.topViewController
        else { return false }
        return belongs(to: top)
            && navigation.viewControllers.count > 1
            && navigation.transitionCoordinator == nil
            && navigation.presentedViewController == nil
    }

    private func belongs(to controller: UIViewController) -> Bool {
        var ancestor: UIViewController? = self
        while let current = ancestor {
            if current === controller { return true }
            ancestor = current.parent
        }
        return false
    }
}
#endif
