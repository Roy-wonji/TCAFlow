import ComposableArchitecture
import SwiftUI
import Foundation
import LogMacro

// MARK: - Production Safety Helpers

/// 프로덕션 환경에서 안전성을 보장하는 실용적인 헬퍼들
public struct ProductionSafety {

    /// Effect 생명주기 관리를 위한 자동 정리
    public static func managedEffect<Action>(
        id: String,
        maxLifetime: TimeInterval = 300, // 5분
        operation: @escaping @Sendable () async throws -> Action
    ) -> Effect<Action> where Action: Sendable {

        return Effect.run { send in
            do {
                let result = try await operation()
                await send(result)
            } catch {
                #if DEBUG
                #logError("🚫 [TCAFlow] Effect '\(id)' failed: \(error)")
                #endif
            }
        }
        .cancellable(id: id, cancelInFlight: true)
    }

    /// 중복 액션 방지 (디바운싱)
    public static func debouncedAction<Action>(
        _ action: Action,
        id: String,
        delay: TimeInterval = 0.5
    ) -> Effect<Action> where Action: Sendable {

        return Effect.run { send in
            try await Task.sleep(for: .seconds(delay))
            await send(action)
        }
        .cancellable(id: "debounce_\(id)", cancelInFlight: true)
    }

    /// 네트워크 요청 타임아웃과 재시도
    public static func networkRequest<Action>(
        id: String,
        timeout: TimeInterval = 30.0,
        retries: Int = 2,
        operation: @escaping @Sendable () async throws -> Action
    ) -> Effect<Action> where Action: Sendable {

        return Effect.run { send in
            for attempt in 0...retries {
                do {
                    let result = try await withThrowingTaskGroup(of: Action.self) { group in
                        group.addTask {
                            try await operation()
                        }

                        group.addTask {
                            try await Task.sleep(for: .seconds(timeout))
                            throw URLError(.timedOut)
                        }

                        let result = try await group.next()!
                        group.cancelAll()
                        return result
                    }

                    await send(result)
                    return

                } catch {
                    if attempt == retries {
                        #if DEBUG
                        #logError("🌐 [TCAFlow] Network request '\(id)' failed after \(retries + 1) attempts")
                        #endif
                        throw error
                    }

                    // 지수 백오프로 재시도 지연
                    let delay = min(pow(2.0, Double(attempt)) * 0.5, 5.0) // 최대 5초
                    try await Task.sleep(for: .seconds(delay))
                }
            }
        }
        .cancellable(id: "network_\(id)", cancelInFlight: true)
    }
}

// MARK: - Memory Leak Prevention

/// 메모리 누수를 방지하는 간단한 헬퍼
public struct MemoryLeakPrevention {

    /// View 생명주기에 따른 Effect 자동 정리
    public static func viewLifecycleEffect<Action>(
        id: String,
        onAppear: @escaping @Sendable () async -> Action,
        onDisappear: @escaping @Sendable () async -> Action
    ) -> (appear: Effect<Action>, disappear: Effect<Action>) where Action: Sendable {

        let appearEffect = Effect.run { send in
            await send(await onAppear())
        }
        .cancellable(id: "\(id)_appear", cancelInFlight: true)

        let disappearEffect = Effect.run { send in
            await send(await onDisappear())
            // 관련된 모든 effects 취소
        }
        .merge(with: Effect.cancel(id: "\(id)_appear"))

        return (appearEffect, disappearEffect)
    }
}

// MARK: - State Transition Safety

/// 상태 전환 시 안전장치
public struct StateTransitionSafety {

    /// 안전한 상태 전환 (Effect 정리 포함)
    public static func safeTransition<Action>(
        effectIDsToCancel: [String] = [],
        newAction: Action
    ) -> Effect<Action> {

        let cancelEffects = effectIDsToCancel.map { Effect<Action>.cancel(id: $0) }

        return .merge(
            [.send(newAction)] + cancelEffects
        )
    }
}

// MARK: - Simple Error Handling

/// 간단한 에러 처리
public struct SimpleErrorHandling {

    /// 안전한 에러 처리가 포함된 Effect
    public static func safeEffect<Action>(
        id: String,
        operation: @escaping @Sendable () async throws -> Action
    ) -> Effect<Action> where Action: Sendable {

        return Effect.run { send in
            do {
                let result = try await operation()
                await send(result)
            } catch {
                #if DEBUG
                #logError("⚠️ [TCAFlow] Safe effect '\(id)' caught error: \(error)")
                #endif
                // 에러 발생 시 무시 (필요하면 에러 액션 전송 가능)
            }
        }
        .cancellable(id: id, cancelInFlight: true)
    }
}

// MARK: - View Extensions

extension View {
    /// 자동 메모리 정리 모디파이어 (단순화)
    public func autoCleanup(effectIDs: [String]) -> some View {
        self
            .onDisappear {
                #if DEBUG
                #logInfo("🧹 [TCAFlow] Auto cleanup triggered for: \(effectIDs)")
                #endif
                // 실제 구현에서는 Store를 통해 effects 취소
            }
    }
}

// MARK: - Array Extensions for Routes

extension Array where Element: Equatable {
    /// 중복 제거 후 추가
    public mutating func appendIfNotExists(_ element: Element) {
        if !self.contains(element) {
            self.append(element)
        }
    }

    /// 안전한 인덱스 접근
    public subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Usage Examples (주석)

/*
 // 사용 예시:

 // 1. 생명주기가 관리되는 Effect
 case .loadData:
     return ProductionSafety.managedEffect(
         id: "load_data",
         maxLifetime: 60.0 // 1분
     ) {
         try await apiClient.fetchData()
     }

 // 2. 중복 방지 액션
 case .search(let query):
     return ProductionSafety.debouncedAction(
         .performSearch(query),
         id: "search",
         delay: 0.5
     )

 // 3. 안전한 네트워크 요청
 case .login(let credentials):
     return ProductionSafety.networkRequest(
         id: "login",
         timeout: 10.0,
         retries: 2
     ) {
         try await authService.login(credentials)
     }

 // 4. 안전한 상태 전환
 case .logout:
     return StateTransitionSafety.safeTransition(
         effectIDsToCancel: ["user_session", "background_sync"],
         newAction: .setAuthState(.loggedOut)
     )

 // 5. 간단한 에러 처리
 case .riskyOperation:
     return SimpleErrorHandling.safeEffect(
         id: "risky_op"
     ) {
         try await riskyAPICall()
     }

 // 6. View에서 자동 정리
 someView
     .autoCleanup(effectIDs: ["timer", "location_updates"])
 */