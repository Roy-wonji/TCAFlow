import SwiftUI

// MARK: - RouteAnimation

/// Route 전환 시 적용할 애니메이션 타입.
///
/// **제한**: NavigationStack의 push/pop은 SwiftUI 내장 슬라이드 애니메이션만 지원합니다.
/// 커스텀 애니메이션은 sheet/cover 전환에만 적용됩니다.
///
/// 사용법:
/// ```swift
/// // Sheet에 커스텀 애니메이션 적용
/// state.routes.presentSheet(
///     .settings(.init()),
///     configuration: .init(detents: [.medium, .large]),
///     animation: .spring
/// )
/// ```
public enum RouteAnimation: Equatable, Sendable {
    /// 시스템 기본 애니메이션
    case `default`
    /// 페이드 인/아웃
    case fade(duration: Double = 0.3)
    /// 스프링 애니메이션
    case spring(duration: Double = 0.35, bounce: Double = 0.2)
    /// 커스텀 이징
    case easeInOut(duration: Double = 0.35)
    /// 애니메이션 없음
    case none

    /// SwiftUI Animation으로 변환
    public var animation: Animation? {
        switch self {
        case .default:
            return .default
        case .fade(let duration):
            return .easeInOut(duration: duration)
        case .spring(let duration, let bounce):
            return .spring(duration: duration, bounce: bounce)
        case .easeInOut(let duration):
            return .easeInOut(duration: duration)
        case .none:
            return nil
        }
    }

    /// SwiftUI Transition으로 변환
    public var transition: AnyTransition {
        switch self {
        case .default:
            return .opacity.combined(with: .move(edge: .bottom))
        case .fade:
            return .opacity
        case .spring, .easeInOut:
            return .opacity.combined(with: .scale(scale: 0.95))
        case .none:
            return .identity
        }
    }
}

// MARK: - View Extension for RouteAnimation

extension View {
    /// Route 애니메이션을 적용하는 뷰 수정자
    @ViewBuilder
    public func routeTransition(_ animation: RouteAnimation) -> some View {
        switch animation {
        case .none:
            self.transaction { $0.disablesAnimations = true }
        default:
            self.transition(animation.transition)
        }
    }
}
