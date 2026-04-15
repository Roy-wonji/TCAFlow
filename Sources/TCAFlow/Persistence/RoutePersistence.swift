import Foundation

// MARK: - Route + Codable

extension Route: Codable where Screen: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, screen, embedInNavigationView
    }

    private enum RouteType: String, Codable {
        case root, push, sheet, cover
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(RouteType.self, forKey: .type)
        let screen = try container.decode(Screen.self, forKey: .screen)
        let embed = try container.decodeIfPresent(Bool.self, forKey: .embedInNavigationView) ?? false

        switch type {
        case .root:
            self = .root(screen, embedInNavigationView: embed)
        case .push:
            self = .push(screen)
        case .sheet:
            self = .sheet(screen, embedInNavigationView: embed)
        case .cover:
            self = .cover(screen, embedInNavigationView: embed)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .root(screen, embed):
            try container.encode(RouteType.root, forKey: .type)
            try container.encode(screen, forKey: .screen)
            try container.encode(embed, forKey: .embedInNavigationView)
        case let .push(screen):
            try container.encode(RouteType.push, forKey: .type)
            try container.encode(screen, forKey: .screen)
        case let .sheet(screen, embed, _):
            try container.encode(RouteType.sheet, forKey: .type)
            try container.encode(screen, forKey: .screen)
            try container.encode(embed, forKey: .embedInNavigationView)
        case let .cover(screen, embed):
            try container.encode(RouteType.cover, forKey: .type)
            try container.encode(screen, forKey: .screen)
            try container.encode(embed, forKey: .embedInNavigationView)
        }
    }
}

// MARK: - RoutePersistence

/// Route 배열의 저장/복원 유틸리티.
///
/// 사용법:
/// ```swift
/// // 저장
/// RoutePersistence.save(state.routes, key: "home_navigation")
///
/// // 복원
/// if let routes: [Route<HomeScreen.State>] = RoutePersistence.load(key: "home_navigation") {
///     state.routes = routes
/// }
/// ```
public enum RoutePersistence {

    /// Route 배열을 UserDefaults에 저장합니다.
    public static func save<Screen: Codable>(
        _ routes: [Route<Screen>],
        key: String,
        defaults: UserDefaults = .standard
    ) {
        guard let data = try? JSONEncoder().encode(routes) else {
            #if DEBUG
            print("🧭 [TCAFlow] Route 저장 실패: \(key)")
            #endif
            return
        }
        defaults.set(data, forKey: "TCAFlow_\(key)")

        #if DEBUG
        print("🧭 [TCAFlow] Route 저장 성공: \(key) (\(routes.count)개 route)")
        #endif
    }

    /// UserDefaults에서 Route 배열을 복원합니다.
    public static func load<Screen: Codable>(
        key: String,
        defaults: UserDefaults = .standard
    ) -> [Route<Screen>]? {
        guard let data = defaults.data(forKey: "TCAFlow_\(key)"),
              let routes = try? JSONDecoder().decode([Route<Screen>].self, from: data) else {
            return nil
        }

        #if DEBUG
        print("🧭 [TCAFlow] Route 복원 성공: \(key) (\(routes.count)개 route)")
        #endif

        return routes
    }

    /// 저장된 Route 데이터를 삭제합니다.
    public static func clear(key: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: "TCAFlow_\(key)")
    }
}

// MARK: - Array + Persistence Extension

extension Array {
    /// Route 배열을 저장합니다.
    public func saveRoutes<Screen: Codable>(
        to key: String,
        defaults: UserDefaults = .standard
    ) where Element == Route<Screen> {
        RoutePersistence.save(self, key: key, defaults: defaults)
    }

    /// 저장된 Route 배열을 복원합니다.
    public static func loadRoutes<Screen: Codable>(
        from key: String,
        defaults: UserDefaults = .standard
    ) -> [Route<Screen>]? where Element == Route<Screen> {
        RoutePersistence.load(key: key, defaults: defaults)
    }
}
