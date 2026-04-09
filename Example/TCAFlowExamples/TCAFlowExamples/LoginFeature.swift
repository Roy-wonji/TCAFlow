import ComposableArchitecture
import SwiftUI

// MARK: - Login Feature

@Reducer
public struct LoginFeature {
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
    case presentSignUp
    case presentStaff
    case presentMember
    case presentWeb
  }

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

// MARK: - Login View

public struct LoginView: View {
  @Bindable var store: StoreOf<LoginFeature>

  public var body: some View {
    VStack(spacing: 20) {
      Text("Login Screen")
        .font(.largeTitle)
        .bold()

      Button("Sign Up") {
        store.send(.navigation(.presentSignUp))
      }

      Button("Staff Login") {
        store.send(.navigation(.presentStaff))
      }

      Button("Member Login") {
        store.send(.navigation(.presentMember))
      }

      Button("Show Web") {
        store.send(.navigation(.presentWeb))
      }
    }
    .padding()
  }
}
