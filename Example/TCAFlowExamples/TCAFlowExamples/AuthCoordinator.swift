import ComposableArchitecture
import SwiftUI
import TCAFlow

// MARK: - Screen Enum (will use @Reducer macro later)

/// Screen cases for the AuthCoordinator
/// TODO: Apply @Reducer(state: .equitable) when macro is implemented
enum AuthScreen {
    case login(LoginFeature)
    case onboarding(OnboardingCoordinator)
    case web(WebFeature)
}

// MARK: - Manual State/Action (until macro is ready)

extension AuthScreen {
    @CasePathable
    @dynamicMemberLookup
    @ObservableState
    enum State: Equatable {
        case login(LoginFeature.State)
        case onboarding(OnboardingCoordinator.State)
        case web(WebFeature.State)
    }

    @CasePathable
    enum Action {
        case login(LoginFeature.Action)
        case onboarding(OnboardingCoordinator.Action)
        case web(WebFeature.Action)
    }
}

// MARK: - Auth Coordinator

@Reducer
public struct AuthCoordinator {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        var routes: [Route<AuthScreen.State>]

        public init() {
            self.routes = [.root(.login(.init()), embedInNavigationView: true)]
        }
    }

    @CasePathable
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case router(IndexedRouterActionOf<AuthScreen>)
        case view(View)
        case navigation(NavigationAction)
    }

    @CasePathable
    public enum View {
        case backAction
        case backToRootAction
    }

    @CasePathable
    public enum NavigationAction: Equatable {
        case presentStaff
        case presentMember
        case cleanup
    }

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(_):
                return .none

            case .router(let routeAction):
                return handleRouterAction(state: &state, action: routeAction)

            case .view(let viewAction):
                return handleViewAction(state: &state, action: viewAction)

            case .navigation(let navigationAction):
                return handleNavigationAction(state: &state, action: navigationAction)
            }
        }
        .forEachRoute(\.routes, action: \.router)
    }
}

// MARK: - Auth Coordinator Logic

extension AuthCoordinator {
    private func handleRouterAction(
        state: inout State,
        action: IndexedRouterActionOf<AuthScreen>
    ) -> Effect<Action> {
        switch action {
        // Login actions
        case .routeAction(id: _, action: .login(.navigation(.presentSignUp))):
            state.routes.push(.onboarding(.init()))
            return .none

        case .routeAction(id: _, action: .login(.navigation(.presentStaff))):
            return .send(.navigation(.presentStaff))

        case .routeAction(id: _, action: .login(.navigation(.presentMember))):
            return .send(.navigation(.presentMember))

        case .routeAction(id: _, action: .login(.navigation(.presentWeb))):
            state.routes.push(.web(.init(url: "https://dddset.notion.site/DDD-2d424441b0b08080a518ed42f1315b20?source=copy_link")))
            return .none

        // Onboarding actions (nested coordinator)
        case .routeAction(id: let id, action: .onboarding(let onboardingAction)):
            return handleOnboardingAction(state: &state, id: id, action: onboardingAction)

        // Web actions
        case .routeAction(id: _, action: .web(.backToRoot)):
            return .send(.view(.backAction))

        default:
            return .none
        }
    }

    private func handleOnboardingAction(
        state: inout State,
        id: Int,
        action: OnboardingCoordinator.Action
    ) -> Effect<Action> {
        // Handle nested coordinator actions
        switch action {
        case .navigation(.backToRoot):
            return routeWithDelaysIfUnsupported(state.routes, action: \.router) {
                $0.goBackTo(\.login)
            }

        case .navigation(.presentStaff):
            return .send(.navigation(.presentStaff))

        case .navigation(.presentMember):
            return .send(.navigation(.presentMember))

        default:
            // Forward other actions to the nested coordinator
            // Update the nested coordinator's state
            if case .onboarding(var onboardingState) = state.routes[safe: id]?.screen {
                // Process the onboarding action on its state
                // For now, we'll just log it since full nested coordination requires more complex state management
                runtimeWarn("Nested coordinator action: \(action)")
            }
            return .none
        }
    }

    private func handleViewAction(
        state: inout State,
        action: View
    ) -> Effect<Action> {
        switch action {
        case .backAction:
            state.routes.goBack()
            return .none

        case .backToRootAction:
            return routeWithDelaysIfUnsupported(state.routes, action: \.router) {
                $0.goBackToRoot()
            }
        }
    }

    private func handleNavigationAction(
        state: inout State,
        action: NavigationAction
    ) -> Effect<Action> {
        switch action {
        case .presentStaff:
            // Navigate to staff main (outside this coordinator)
            return .none

        case .presentMember:
            // Navigate to member main (outside this coordinator)
            return .none

        case .cleanup:
            // Cleanup any ongoing effects
            return .none
        }
    }
}

// MARK: - Auth Coordinator View

public struct AuthCoordinatorView: View {
    @Bindable private var store: StoreOf<AuthCoordinator>

    public init(store: StoreOf<AuthCoordinator>) {
        self.store = store
    }

    public var body: some View {
        TCARouter(store.scope(state: \.routes, action: \.router)) { screens in
            switch screens.case {
            case let .login(loginState):
                LoginView(store: Store(initialState: loginState) {
                    LoginFeature()
                })
                .navigationBarBackButtonHidden()

            case let .onboarding(onboardingState):
                OnboardingCoordinatorView(store: Store(initialState: onboardingState) {
                    OnboardingCoordinator()
                })
                .navigationBarBackButtonHidden()

            case let .web(webState):
                WebView(store: Store(initialState: webState) {
                    WebFeature()
                })
                .navigationBarBackButtonHidden()
            }
        }
    }
}