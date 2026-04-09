import ComposableArchitecture
import SwiftUI
import TCAFlow

// MARK: - Onboarding Screen Cases

/// Screen cases for the OnboardingCoordinator
enum OnboardingScreen {
  case welcome(WelcomeFeature)
  case terms(TermsFeature)
  case profile(ProfileSetupFeature)
}

// MARK: - Manual State/Action (until macro is ready)

extension OnboardingScreen {
  @CasePathable
  @dynamicMemberLookup
  @ObservableState
  enum State: Equatable {
    case welcome(WelcomeFeature.State)
    case terms(TermsFeature.State)
    case profile(ProfileSetupFeature.State)
  }
  
  @CasePathable
  enum Action {
    case welcome(WelcomeFeature.Action)
    case terms(TermsFeature.Action)
    case profile(ProfileSetupFeature.Action)
  }
}

// MARK: - Onboarding Coordinator

@Reducer
public struct OnboardingCoordinator {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    var routes: [Route<OnboardingScreen.State>]
    
    public init() {
      self.routes = [.root(.welcome(.init()), embedInNavigationView: true)]
    }
  }
  
  @CasePathable
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case router(IndexedRouterActionOf<OnboardingScreen>)
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
    case backToRoot
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

// MARK: - Onboarding Coordinator Logic

extension OnboardingCoordinator {
  private func handleRouterAction(
    state: inout State,
    action: IndexedRouterActionOf<OnboardingScreen>
  ) -> Effect<Action> {
    switch action {
        // Welcome actions
      case .routeAction(id: _, action: .welcome(.navigation(.nextStep))):
        state.routes.push(.terms(.init()))
        return .none
        
      case .routeAction(id: _, action: .welcome(.navigation(.backToAuth))):
        return .send(.navigation(.backToRoot))
        
        // Terms actions
      case .routeAction(id: _, action: .terms(.navigation(.nextStep))):
        state.routes.push(.profile(.init()))
        return .none
        
      case .routeAction(id: _, action: .terms(.navigation(.backStep))):
        return .send(.view(.backAction))
        
        // Profile Setup actions
      case .routeAction(id: _, action: .profile(.navigation(.completeOnboarding))):
        return .send(.navigation(.presentMember))
        
      case .routeAction(id: _, action: .profile(.navigation(.backStep))):
        return .send(.view(.backAction))
        
      default:
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
      case .backToRoot:
        // Go back to Auth coordinator
        return .none
        
      case .presentStaff:
        // Navigate to staff main
        return .none
        
      case .presentMember:
        // Navigate to member main
        return .none
        
      case .cleanup:
        return .none
    }
  }
}

// MARK: - Onboarding Coordinator View

public struct OnboardingCoordinatorView: View {
  @Bindable private var store: StoreOf<OnboardingCoordinator>
  
  public init(store: StoreOf<OnboardingCoordinator>) {
    self.store = store
  }
  
  public var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screens in
      switch screens.case {
        case let .welcome(welcomeState):
          WelcomeView(store: Store(initialState: welcomeState) {
            WelcomeFeature()
          })
          .navigationBarBackButtonHidden()

        case let .terms(termsState):
          TermsView(store: Store(initialState: termsState) {
            TermsFeature()
          })
          .navigationBarBackButtonHidden()

        case let .profile(profileState):
          ProfileSetupView(store: Store(initialState: profileState) {
            ProfileSetupFeature()
          })
          .navigationBarBackButtonHidden()
      }
    }
  }
}

// MARK: - Feature Implementations

@Reducer
public struct WelcomeFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  @CasePathable
  public enum Action {
    case navigation(NavigationAction)
  }
  
  @CasePathable
  public enum NavigationAction {
    case nextStep
    case backToAuth
  }
  
  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

@Reducer
public struct TermsFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  @CasePathable
  public enum Action {
    case navigation(NavigationAction)
  }
  
  @CasePathable
  public enum NavigationAction {
    case nextStep
    case backStep
  }
  
  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

@Reducer
public struct ProfileSetupFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  @CasePathable
  public enum Action {
    case navigation(NavigationAction)
  }
  
  @CasePathable
  public enum NavigationAction {
    case completeOnboarding
    case backStep
  }
  
  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

// MARK: - Views

public struct WelcomeView: View {
  @Bindable var store: StoreOf<WelcomeFeature>

  public var body: some View {
    VStack(spacing: 20) {
      Text("Welcome!")
        .font(.largeTitle)
        .bold()

      Text("온보딩을 시작합니다")
        .font(.body)
        .foregroundColor(.secondary)

      Button("Next") {
        store.send(.navigation(.nextStep))
      }

      Button("Back to Login") {
        store.send(.navigation(.backToAuth))
      }
    }
    .padding()
  }
}

public struct TermsView: View {
  @Bindable var store: StoreOf<TermsFeature>
  
  public var body: some View {
    VStack(spacing: 20) {
      Text("Terms & Conditions")
        .font(.largeTitle)
        .bold()
      
      Text("약관에 동의해주세요")
        .font(.body)
        .foregroundColor(.secondary)
      
      Button("Accept & Continue") {
        store.send(.navigation(.nextStep))
      }
      
      Button("Back") {
        store.send(.navigation(.backStep))
      }
    }
    .padding()
  }
}

public struct ProfileSetupView: View {
  @Bindable var store: StoreOf<ProfileSetupFeature>
  
  public var body: some View {
    VStack(spacing: 20) {
      Text("Profile Setup")
        .font(.largeTitle)
        .bold()
      
      Text("프로필을 설정하세요")
        .font(.body)
        .foregroundColor(.secondary)
      
      Button("Complete Onboarding") {
        store.send(.navigation(.completeOnboarding))
      }
      
      Button("Back") {
        store.send(.navigation(.backStep))
      }
    }
    .padding()
  }
}
