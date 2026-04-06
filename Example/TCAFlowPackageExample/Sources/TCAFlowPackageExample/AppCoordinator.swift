import Foundation
import ComposableArchitecture
import TCAFlow

// MARK: - Features
@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        let title = "🏠 홈 화면"
    }

    enum Action {
        case exploreTapped
        case profileTapped
        case settingsTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

@Reducer
struct Explore {
    @ObservableState
    struct State: Equatable {
        let title = "🔍 탐색 화면"
    }

    enum Action {
        case backTapped
        case goToHomeTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

@Reducer
struct Profile {
    @ObservableState
    struct State: Equatable {
        let title = "👤 프로필 화면"
    }

    enum Action {
        case backTapped
        case settingsTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

@Reducer
struct Settings {
    @ObservableState
    struct State: Equatable {
        let title = "⚙️ 설정 화면"
    }

    enum Action {
        case backTapped
        case goToRootTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

// MARK: - AppScreen
@Reducer
enum AppScreen {
    case home(Home.State)
    case explore(Explore.State)
    case profile(Profile.State)
    case settings(Settings.State)
}

// MARK: - 🪄 TCAFlow 사용!
@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: IdentifiedArrayOf<Route<AppScreen.State>> = [
            Route(.home(.init()))
        ]
    }

    enum Action {
        case router(FlowActionOf<AppScreen>)
        case home(Home.Action)
        case explore(Explore.Action)
        case profile(Profile.Action)
        case settings(Settings.Action)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // Home 액션들
            case .home(.exploreTapped):
                state.routes.push(.explore(.init()))
                return .none

            case .home(.profileTapped):
                state.routes.goTo(.profile(.init())) // 🎯 TCAFlow 직접 이동!
                return .none

            case .home(.settingsTapped):
                state.routes.push(.settings(.init()))
                return .none

            // Explore 액션들
            case .explore(.backTapped):
                state.routes.pop()
                return .none

            case .explore(.goToHomeTapped):
                state.routes.goBackTo(.home(.init())) // 🎯 TCAFlow 직접 뒤로!
                return .none

            // Profile 액션들
            case .profile(.backTapped):
                state.routes.pop()
                return .none

            case .profile(.settingsTapped):
                state.routes.push(.settings(.init()))
                return .none

            // Settings 액션들
            case .settings(.backTapped):
                state.routes.pop()
                return .none

            case .settings(.goToRootTapped):
                state.routes.popToRoot()
                return .none

            default:
                return .none
            }
        }
        .forEach(\.routes, action: \.router) {
            AppScreen()
        }
    }
}