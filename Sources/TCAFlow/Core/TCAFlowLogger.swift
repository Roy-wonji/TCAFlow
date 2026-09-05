import Foundation

enum TCAFlowLogger {
    enum Level: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    static func debug(
        _ message: @autoclosure () -> String,
        prefix: String = "[TCAFlow]",
        includeTimestamp: Bool = false
    ) {
        log(
            level: .debug,
            message(),
            prefix: prefix,
            includeTimestamp: includeTimestamp
        )
    }

    static func info(_ message: @autoclosure () -> String) {
        log(level: .info, message())
    }

    static func warning(_ message: @autoclosure () -> String) {
        log(level: .warning, message())
    }

    static func error(_ message: @autoclosure () -> String) {
        log(level: .error, message())
    }

    static func format(
        level: Level,
        message: String,
        prefix: String = "[TCAFlow]",
        timestamp: String? = nil
    ) -> String {
        let timestampComponent = timestamp.map { " [\($0)]" } ?? ""
        return "\(prefix)\(timestampComponent) [\(level.rawValue)] \(message)"
    }

    private static func log(
        level: Level,
        _ message: @autoclosure () -> String,
        prefix: String = "[TCAFlow]",
        includeTimestamp: Bool = false
    ) {
        #if DEBUG
        let timestamp = includeTimestamp
            ? ISO8601DateFormatter().string(from: Date())
            : nil
        Swift.print(
            format(
                level: level,
                message: message(),
                prefix: prefix,
                timestamp: timestamp
            )
        )
        #endif
    }
}
