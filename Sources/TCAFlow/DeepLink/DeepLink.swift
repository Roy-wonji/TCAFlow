import Foundation

// MARK: - DeepLinkHandler Protocol

/// URL을 Route 배열로 변환하는 딥링크 핸들러.
///
/// 사용법:
/// ```swift
/// struct AppDeepLinkHandler: DeepLinkHandler {
///     typealias Screen = AppCoordinator.Screen.State
///
///     func routes(for url: URL) -> [Route<Screen>]? {
///         guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
///               let host = components.host else { return nil }
///
///         switch host {
///         case "profile":
///             return [
///                 .root(.home(.init()), embedInNavigationView: true),
///                 .push(.profile(.init()))
///             ]
///         case "settings":
///             return [
///                 .root(.home(.init()), embedInNavigationView: true),
///                 .push(.profile(.init())),
///                 .push(.settings(.init()))
///             ]
///         default:
///             return nil
///         }
///     }
/// }
/// ```
public protocol DeepLinkHandler {
    associatedtype Screen
    /// URL을 Route 배열로 변환합니다. nil을 반환하면 처리할 수 없는 URL입니다.
    func routes(for url: URL) -> [Route<Screen>]?
}

// MARK: - DeepLink Navigation Mode

/// 딥링크 적용 방식
public enum DeepLinkMode {
    /// 기존 routes를 완전히 교체
    case replace
    /// 기존 routes의 root를 유지하고 나머지만 교체
    case keepRoot
    /// 기존 routes 뒤에 추가
    case append
}

// MARK: - Array + DeepLink Extension

extension Array {
    /// 딥링크 URL을 처리하여 routes를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - url: 딥링크 URL
    ///   - handler: URL → Route 변환 핸들러
    ///   - mode: 적용 방식 (기본: .replace)
    /// - Returns: 딥링크 처리 성공 여부
    ///
    /// 사용법:
    /// ```swift
    /// case .inner(.handleDeepLink(let url)):
    ///     state.routes.handleDeepLink(url, handler: AppDeepLinkHandler())
    ///     return .none
    /// ```
    @discardableResult
    public mutating func handleDeepLink<Screen, Handler: DeepLinkHandler>(
        _ url: URL,
        handler: Handler,
        mode: DeepLinkMode = .replace
    ) -> Bool where Element == Route<Screen>, Handler.Screen == Screen {
        guard let newRoutes = handler.routes(for: url), !newRoutes.isEmpty else {
            return false
        }

        switch mode {
        case .replace:
            self = newRoutes

        case .keepRoot:
            guard let root = first else {
                self = newRoutes
                return true
            }
            self = [root] + newRoutes.dropFirst()

        case .append:
            // root를 제외한 나머지만 추가
            for route in newRoutes where route.isPush || route.isPresented {
                append(route)
            }
        }

        return true
    }
}

// MARK: - URL + Query Parameters Helper

extension URL {
    /// 딥링크 URL에서 쿼리 파라미터를 딕셔너리로 추출합니다.
    public var deepLinkParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [:]) { result, item in
            result[item.name] = item.value
        }
    }

    /// 딥링크 URL의 path를 컴포넌트 배열로 분리합니다.
    public var deepLinkPathComponents: [String] {
        pathComponents.filter { $0 != "/" }
    }
}
