import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(TCAFlowMacros)
import TCAFlowMacros

let testMacros: [String: any Macro.Type] = [
    "FlowCoordinator": FlowCoordinatorMacro.self,
]
#endif

final class FlowCoordinatorMacroTests: XCTestCase {

    func testBasicExpansion() throws {
        #if canImport(TCAFlowMacros)
        assertMacroExpansion(
            """
            @FlowCoordinator(navigation: true)
            extension AppCoordinator {
                @Reducer
                enum Screen {
                    case home(HomeFeature)
                    case detail(DetailFeature)
                }
            }
            """,
            expandedSource: """
            extension AppCoordinator {
                @Reducer
                enum Screen {
                    case home(HomeFeature)
                    case detail(DetailFeature)
                }

                @ObservableState
                struct State: Equatable {
                    var routes: [Route<Screen.State>]
                    init() {
                        self.routes = [.root(.home(.init()), embedInNavigationView: true)]
                    }
                }

                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<Screen>)
                }

                var body: some Reducer<State, Action> {
                    Reduce { state, action in
                        return self.handleRoute(state: &state, action: action)
                    }
                    .forEachRoute(\\.routes, action: \\.router)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testNavigationFalse() throws {
        #if canImport(TCAFlowMacros)
        assertMacroExpansion(
            """
            @FlowCoordinator(navigation: false)
            extension AppCoordinator {
                @Reducer
                enum Screen {
                    case login(LoginFeature)
                }
            }
            """,
            expandedSource: """
            extension AppCoordinator {
                @Reducer
                enum Screen {
                    case login(LoginFeature)
                }

                @ObservableState
                struct State: Equatable {
                    var routes: [Route<Screen.State>]
                    init() {
                        self.routes = [.root(.login(.init()), embedInNavigationView: false)]
                    }
                }

                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<Screen>)
                }

                var body: some Reducer<State, Action> {
                    Reduce { state, action in
                        return self.handleRoute(state: &state, action: action)
                    }
                    .forEachRoute(\\.routes, action: \\.router)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testCustomActionSkipsActionGeneration() throws {
        #if canImport(TCAFlowMacros)
        assertMacroExpansion(
            """
            @FlowCoordinator(navigation: true)
            extension NestedCoordinator {
                @Reducer
                enum NestedScreen {
                    case step1(Step1Feature)
                    case step2(Step2Feature)
                }

                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<NestedScreen>)
                    case backToMain
                }
            }
            """,
            expandedSource: """
            extension NestedCoordinator {
                @Reducer
                enum NestedScreen {
                    case step1(Step1Feature)
                    case step2(Step2Feature)
                }

                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<NestedScreen>)
                    case backToMain
                }

                @ObservableState
                struct State: Equatable {
                    var routes: [Route<NestedScreen.State>]
                    init() {
                        self.routes = [.root(.step1(.init()), embedInNavigationView: true)]
                    }
                }

                var body: some Reducer<State, Action> {
                    Reduce { state, action in
                        return self.handleRoute(state: &state, action: action)
                    }
                    .forEachRoute(\\.routes, action: \\.router)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDefaultNavigation() throws {
        #if canImport(TCAFlowMacros)
        assertMacroExpansion(
            """
            @FlowCoordinator()
            extension AppCoordinator {
                @Reducer
                enum Screen {
                    case home(HomeFeature)
                }
            }
            """,
            expandedSource: """
            extension AppCoordinator {
                @Reducer
                enum Screen {
                    case home(HomeFeature)
                }

                @ObservableState
                struct State: Equatable {
                    var routes: [Route<Screen.State>]
                    init() {
                        self.routes = [.root(.home(.init()), embedInNavigationView: true)]
                    }
                }

                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<Screen>)
                }

                var body: some Reducer<State, Action> {
                    Reduce { state, action in
                        return self.handleRoute(state: &state, action: action)
                    }
                    .forEachRoute(\\.routes, action: \\.router)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
