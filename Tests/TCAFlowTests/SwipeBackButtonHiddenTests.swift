#if os(iOS)
import SwiftUI
import UIKit
import XCTest
@testable import TCAFlow

@MainActor
final class SwipeBackButtonHiddenTests: XCTestCase {
    func testPushedScreenAllowsSwipeAndFalseRestoresOriginalConfiguration() {
        let (navigation, controller) = makeController(pushed: true)
        let gesture = navigation.interactivePopGestureRecognizer!
        let originalDelegate = gesture.delegate
        gesture.isEnabled = false

        controller.isHidden = true
        controller.viewDidAppear(false)
        controller.restoreGesture()

        XCTAssertTrue(gesture.delegate === controller)
        XCTAssertTrue(gesture.isEnabled)
        XCTAssertTrue(controller.gestureRecognizerShouldBegin(gesture))

        controller.isHidden = false
        controller.restoreWhenReady()
        XCTAssertTrue(gesture.delegate === originalDelegate)
        XCTAssertFalse(gesture.isEnabled)
    }

    func testRootCannotStartSwipe() {
        let (navigation, controller) = makeController(pushed: false)
        controller.isHidden = true
        controller.viewDidAppear(false)
        controller.restoreGesture()
        XCTAssertFalse(controller.gestureRecognizerShouldBegin(navigation.interactivePopGestureRecognizer!))
        controller.detach()
    }

    func testDisappearanceRestoresDelegateAndQueuedWorkCannotReinstallIt() async {
        let (navigation, controller) = makeController(pushed: true)
        let gesture = navigation.interactivePopGestureRecognizer!
        let originalDelegate = gesture.delegate
        controller.isHidden = true
        controller.viewDidAppear(false)
        controller.restoreGesture()
        controller.viewWillDisappear(false)
        XCTAssertTrue(gesture.delegate === controller)
        controller.viewDidDisappear(false)
        await Task.yield()
        controller.restoreGesture()
        XCTAssertTrue(gesture.delegate === originalDelegate)
        XCTAssertFalse(controller.gestureRecognizerShouldBegin(gesture))

        // An interactive pop cancellation makes the same screen appear again.
        controller.viewDidAppear(false)
        controller.restoreGesture()
        XCTAssertTrue(gesture.delegate === controller)
        controller.detach()
    }

    func testDetachDoesNotOverwriteAnotherOwnersDelegate() {
        let (navigation, controller) = makeController(pushed: true)
        let gesture = navigation.interactivePopGestureRecognizer!
        controller.isHidden = true
        controller.viewDidAppear(false)
        controller.restoreGesture()
        let replacement = GestureDelegate()
        gesture.delegate = replacement
        controller.detach()
        XCTAssertTrue(gesture.delegate === replacement)
    }

    func testPopDoesNotRestoreStaleEnabledStateOntoPreviousScreen() {
        let (navigation, controller) = makeController(pushed: true)
        let root = navigation.viewControllers[0]
        let detail = navigation.viewControllers[1]
        let previousScreen = UIViewController()
        navigation.setViewControllers([root, previousScreen, detail], animated: false)
        let gesture = navigation.interactivePopGestureRecognizer!
        let originalDelegate = gesture.delegate
        gesture.isEnabled = false
        controller.isHidden = true
        controller.viewDidAppear(false)
        controller.restoreGesture()

        controller.viewWillDisappear(false)
        XCTAssertTrue(gesture.isEnabled)
        // Completed disappearance must not write the old disabled snapshot back.
        controller.viewDidDisappear(false)
        XCTAssertTrue(gesture.isEnabled)
        navigation.popViewController(animated: false)

        XCTAssertTrue(navigation.topViewController === previousScreen)
        XCTAssertTrue(gesture.delegate === originalDelegate)
        XCTAssertTrue(gesture.isEnabled)
    }

    func testSwiftUIModifierInstallsAndRemovesGestureOverride() async throws {
        let screen = UIHostingController(rootView: Text("Detail").swipeBackButtonHidden())
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.setViewControllers([navigation.viewControllers[0], screen], animated: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let gesture = try XCTUnwrap(navigation.interactivePopGestureRecognizer)
        for _ in 0..<100 where !(gesture.delegate is SwipeBackGestureController) {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertTrue(screen.navigationItem.hidesBackButton)
        XCTAssertTrue(gesture.delegate is SwipeBackGestureController)
        XCTAssertTrue(gesture.isEnabled)

        screen.rootView = Text("Detail").swipeBackButtonHidden(false)
        for _ in 0..<100 where gesture.delegate is SwipeBackGestureController {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertFalse(screen.navigationItem.hidesBackButton)
        XCTAssertFalse(gesture.delegate is SwipeBackGestureController)
    }

    private func makeController(pushed: Bool) -> (UINavigationController, SwipeBackGestureController) {
        let root = UIViewController()
        let navigation = UINavigationController(rootViewController: root)
        let screen = pushed ? UIViewController() : root
        if pushed { navigation.setViewControllers([root, screen], animated: false) }
        navigation.loadViewIfNeeded()
        let controller = SwipeBackGestureController()
        screen.addChild(controller)
        screen.view.addSubview(controller.view)
        controller.didMove(toParent: screen)
        return (navigation, controller)
    }
}

@MainActor
private final class GestureDelegate: NSObject, UIGestureRecognizerDelegate {}
#endif
