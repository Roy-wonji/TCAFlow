import Foundation
import ComposableArchitecture
import SwiftUI

// MARK: - Route (Hashable 제약 완화)
public struct Route<State: Equatable>: Identifiable, Hashable {
    public let id = UUID()
    public var state: State

    public init(_ state: State) {
        self.state = state
    }

    // ID 기반으로만 해싱 (State의 Hashable 불필요)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Route<State>, rhs: Route<State>) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - FlowActionOf
public typealias FlowActionOf<Screen: Reducer> = (id: Route<Screen.State>.ID, action: Screen.Action) where Screen.State: Equatable

// MARK: - 네비게이션 확장
extension IdentifiedArrayOf where Element: Identifiable, Element.ID == UUID {

    /// 새로운 화면 추가
    public mutating func push<S: Equatable>(_ state: S) where Element == Route<S> {
        append(Route(state))
    }

    /// 이전 화면으로
    @discardableResult
    public mutating func pop() -> Element? {
        if isEmpty {
            return nil
        }
        return removeLast()
    }

    /// 루트로 돌아가기
    public mutating func popToRoot() {
        removeAll()
    }

    /// 현재 화면 교체
    public mutating func replace<S: Equatable>(with state: S) where Element == Route<S> {
        if isEmpty {
            push(state)
        } else {
            self[count - 1] = Route(state)
        }
    }

    /// 스크린으로 특정 화면 이동
    public mutating func goTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        let targetType = String(describing: targetScreen).components(separatedBy: "(").first ?? ""

        if let index = firstIndex(where: { route in
            let routeType = String(describing: route.state).components(separatedBy: "(").first ?? ""
            return routeType == targetType
        }) {
            removeSubrange((index + 1)...)
        } else {
            append(Route(targetScreen))
        }
    }

    /// 스크린으로 특정 화면까지 뒤로 가기
    public mutating func goBackTo<S: Equatable>(_ targetScreen: S) where Element == Route<S> {
        let targetType = String(describing: targetScreen).components(separatedBy: "(").first ?? ""

        while let last = last {
            let lastType = String(describing: last.state).components(separatedBy: "(").first ?? ""
            if lastType == targetType {
                break
            }
            removeLast()
        }
    }

    /// 스크린 존재 확인
    public func has<S: Equatable>(_ targetScreen: S) -> Bool where Element == Route<S> {
        let targetType = String(describing: targetScreen).components(separatedBy: "(").first ?? ""

        return contains { route in
            let routeType = String(describing: route.state).components(separatedBy: "(").first ?? ""
            return routeType == targetType
        }
    }

    /// 스택 깊이
    public var depth: Int {
        count
    }
}

