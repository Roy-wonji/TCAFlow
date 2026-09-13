#if os(iOS)
import SwiftUI
import UIKit
import XCTest
@testable import TCAFlow

@MainActor
final class UIKitNavigationDriverTests: XCTestCase {
    func testDataUpdatesReuseControllersAndDoNotWriteBack() {
        let navigation = CountingNavigationController()
        let driver = _UIKitNavigationDriver()
        driver.attach(to: navigation)
        defer { driver.invalidate() }
        let ids = makeIDs(count: 3)
        var removals = 0
        for value in 0..<1_000 {
            let before = navigation.viewControllers
            driver.update(entries(ids, text: "\(value)"), onPop: { _ in removals += 1 }, animated: false)
            if !before.isEmpty {
                XCTAssertEqual(before.map(ObjectIdentifier.init), navigation.viewControllers.map(ObjectIdentifier.init))
            }
        }
        XCTAssertEqual(navigation.viewControllers.count, 3)
        XCTAssertEqual(removals, 0)
        XCTAssertEqual(navigation.stackAssignments, 1)
    }

    func testProgrammaticPopKeepsRootIdentity() {
        let navigation = UINavigationController()
        let driver = _UIKitNavigationDriver()
        driver.attach(to: navigation)
        defer { driver.invalidate() }
        let ids = makeIDs(count: 3)
        driver.update(entries(ids), onPop: { _ in XCTFail("Programmatic change wrote back") }, animated: false)
        let root = navigation.viewControllers.first
        driver.update(entries(Array(ids.prefix(1))), onPop: { _ in XCTFail("Programmatic change wrote back") }, animated: false)
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.viewControllers.first === root)
    }

    func testInvalidatedDriverDoesNotChangeStackOrReplaceNewDelegate() {
        let navigation = UINavigationController()
        let driver = _UIKitNavigationDriver()
        driver.attach(to: navigation)
        let ids = makeIDs(count: 2)
        driver.update(entries(ids), onPop: { _ in XCTFail("Detached callback") }, animated: false)
        let delegate = Delegate()
        navigation.delegate = delegate
        driver.invalidate()
        driver.update([], onPop: { _ in XCTFail("Detached callback") }, animated: false)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.delegate === delegate)
    }

    private func makeIDs(count: Int) -> [_UIKitNavigationEntryID] {
        let owner = UUID()
        return (0..<count).map {
            _UIKitNavigationEntryID(coordinatorID: owner, index: $0, generation: UUID())
        }
    }

    private func entries(_ ids: [_UIKitNavigationEntryID], text: String = "Screen") -> [_UIKitNavigationEntry] {
        ids.map { _UIKitNavigationEntry(id: $0, content: AnyView(Text(text))) }
    }

    private final class Delegate: NSObject, UINavigationControllerDelegate {}

    private final class CountingNavigationController: UINavigationController {
        var stackAssignments = 0

        override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
            stackAssignments += 1
            super.setViewControllers(viewControllers, animated: animated)
        }
    }
}
#endif
