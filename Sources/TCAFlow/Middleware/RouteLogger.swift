import ComposableArchitecture
import Foundation

// MARK: - Route Logging Reducer

/// Route 변경을 자동으로 로깅하는 리듀서 래퍼.
///
/// 사용법:
/// ```swift
/// var body: some Reducer<State, Action> {
///     Reduce { state, action in ... }
///         .forEachRoute(\.routes, action: \.router)
///         .routeLogging()  // 디버그 모드에서 route 변경 로그
/// }
/// ```
public struct _RouteLoggingReducer<Base: Reducer>: Reducer {
    let base: Base
    let logger: RouteLogger

    public var body: some ReducerOf<Base> {
        Reduce { state, action in
            let before = String(describing: state)
            let effect = base.reduce(into: &state, action: action)
            let after = String(describing: state)

            if before != after {
                logger.log(action: action)
            }

            return effect
        }
    }
}

/// Route 로깅 설정
public struct RouteLogger: Sendable {
    public enum Level: Sendable {
        case minimal   // action 이름만
        case verbose   // action + route 스택 상태
    }

    public let level: Level
    public let prefix: String

    public init(level: Level = .minimal, prefix: String = "🧭 [TCAFlow]") {
        self.level = level
        self.prefix = prefix
    }

    func log<Action>(action: Action) {
        #if DEBUG
        let actionDescription = String(describing: action)

        // router action에서 의미 있는 부분만 추출
        switch level {
        case .minimal:
            print("\(prefix) \(actionDescription)")
        case .verbose:
            let timestamp = ISO8601DateFormatter().string(from: Date())
            print("\(prefix) [\(timestamp)] \(actionDescription)")
        }
        #endif
    }
}

// MARK: - Reducer Extension

extension Reducer {
    /// Route 변경을 디버그 로그로 출력하는 미들웨어를 추가합니다.
    ///
    /// - Parameters:
    ///   - level: 로그 상세도 (.minimal 또는 .verbose)
    ///   - prefix: 로그 접두사 (기본값: "🧭 [TCAFlow]")
    /// - Returns: 로깅이 추가된 리듀서
    ///
    /// 사용법:
    /// ```swift
    /// .forEachRoute(\.routes, action: \.router)
    /// .routeLogging()
    /// ```
    public func routeLogging(
        level: RouteLogger.Level = .minimal,
        prefix: String = "🧭 [TCAFlow]"
    ) -> _RouteLoggingReducer<Self> {
        _RouteLoggingReducer(
            base: self,
            logger: RouteLogger(level: level, prefix: prefix)
        )
    }
}
