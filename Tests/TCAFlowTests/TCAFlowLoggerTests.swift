import XCTest
@testable import TCAFlow

final class TCAFlowLoggerTests: XCTestCase {
    func testFormatsLogLevelAndMessage() {
        XCTAssertEqual(
            TCAFlowLogger.format(level: .error, message: "Effect failed"),
            "[TCAFlow] [ERROR] Effect failed"
        )
    }

    func testFormatsCustomPrefixAndTimestamp() {
        XCTAssertEqual(
            TCAFlowLogger.format(
                level: .debug,
                message: "routeAction",
                prefix: "🧭 [Auth]",
                timestamp: "2026-09-06T12:00:00Z"
            ),
            "🧭 [Auth] [2026-09-06T12:00:00Z] [DEBUG] routeAction"
        )
    }
}
