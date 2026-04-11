import ComposableArchitecture

/// `@FlowCoordinator` 매크로는 TCA coordinator의 보일러플레이트를 자동 생성합니다.
///
/// ## 기본 사용법 (State + Action + body 전부 자동)
/// ```swift
/// struct AppCoordinator {}
///
/// @FlowCoordinator(navigation: true)
/// extension AppCoordinator {
///     @Reducer
///     enum Screen {
///         case home(HomeFeature)
///         case detail(DetailFeature)
///     }
/// }
///
/// extension AppCoordinator {
///     func handleRoute(state: inout State, action: IndexedRouterActionOf<Screen>) -> Effect<Action> {
///         switch action {
///         case .routeAction(_, .home(.detailTapped)):
///             state.routes.push(.detail(.init()))
///             return .none
///         default:
///             return .none
///         }
///     }
/// }
/// ```
///
/// ## 추가 Action 필요 시 (Action 직접 작성 → 매크로가 건너뜀)
/// ```swift
/// @FlowCoordinator(navigation: true)
/// extension NestedCoordinator {
///     @Reducer
///     enum NestedScreen {
///         case step1(Step1Feature)
///         case step2(Step2Feature)
///     }
///
///     @CasePathable
///     enum Action {
///         case router(IndexedRouterActionOf<NestedScreen>)
///         case backToMain
///     }
/// }
/// ```
///
/// - Parameter navigation: `true`이면 root route에 `embedInNavigationView: true` 설정 (기본값: `true`)
@attached(member, names: named(State), named(Action), named(body))
@attached(extension, conformances: Reducer, names: arbitrary)
@attached(peer, names: arbitrary)
public macro FlowCoordinator(screen: String? = nil, navigation: Bool = true) =
    #externalMacro(module: "TCAFlowMacros", type: "FlowCoordinatorMacro")
