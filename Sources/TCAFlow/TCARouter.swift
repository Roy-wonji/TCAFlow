import Foundation
import ComposableArchitecture
import SwiftUI

// MARK: - TCAFlowRouter - 메인 라우터 컴포넌트
public struct TCAFlowRouter<Screen: CasePathable & Equatable, ScreenView: View>: View {
    let routes: IdentifiedArrayOf<Route<Screen>>
    let screenView: (Screen) -> ScreenView

    public init(
        _ routes: IdentifiedArrayOf<Route<Screen>>,
        @ViewBuilder screenView: @escaping (Screen) -> ScreenView
    ) {
        self.routes = routes
        self.screenView = screenView
    }

    public var body: some View {
        NavigationStack(path: .constant(routes.map(\.id))) {
            if let firstRoute = routes.first {
                screenView(firstRoute.state)
            } else {
                EmptyView()
            }
        }
        .navigationDestination(for: UUID.self) { routeID in
            if let route = routes[id: routeID] {
                screenView(route.state)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: routes.count)
        .transaction { transaction in
            if routes.count > 1 {
                transaction.animation = .easeInOut(duration: 0.1)
            }
        }
    }
}

// MARK: - Navigation Helpers with Animation
extension IdentifiedArrayOf where Element: Identifiable, Element.ID == UUID {

    /// 현재 화면 (최상위)
    public var currentScreen: Element? {
        last
    }

    /// 루트 화면 (최하위)
    public var rootScreen: Element? {
        first
    }

    /// 애니메이션과 함께 push
    public mutating func pushWithAnimation<S: Equatable>(_ state: S, animation: Animation = .default) where Element == Route<S> {
        withAnimation(animation) {
            push(state)
        }
    }

    /// 애니메이션과 함께 pop
    @discardableResult
    public mutating func popWithAnimation(animation: Animation = .default) -> Element? {
        withAnimation(animation) {
            return pop()
        }
    }

    /// 애니메이션과 함께 goTo
    public mutating func goToWithAnimation<S: Equatable>(_ targetScreen: S, animation: Animation = .default) where Element == Route<S> {
        withAnimation(animation) {
            goTo(targetScreen)
        }
    }

    /// 애니메이션과 함께 goBackTo
    public mutating func goBackToWithAnimation<S: Equatable>(_ targetScreen: S, animation: Animation = .default) where Element == Route<S> {
        withAnimation(animation) {
            goBackTo(targetScreen)
        }
    }
}

// MARK: - Transition Extensions
extension View {
    /// 커스텀 네비게이션 전환
    public func flowTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }

    /// 슬라이드 전환
    public func slideTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
    }

    /// 페이드 전환
    public func fadeTransition() -> some View {
        self.transition(.opacity)
    }

    /// 스케일 전환
    public func scaleTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }

    /// 커스텀 방향 전환 (왼쪽에서 들어오기)
    public func leadingTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    /// 커스텀 방향 전환 (아래에서 들어오기)
    public func bottomTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}