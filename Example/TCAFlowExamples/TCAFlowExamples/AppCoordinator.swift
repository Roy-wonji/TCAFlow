//
//  AppCoordinator.swift
//  TCAFlowExamples
//
//  Created by Wonji Suh  on 4/6/26.
//

import Foundation
import ComposableArchitecture

// MARK: - AppScreen
@Reducer
enum AppScreen {
    case home(Home.State)
    case explore(Explore.State)
    case profile(Profile.State)
    case settings(Settings.State)
}

// MARK: - AppCoordinator (기본 TCA 방식)
@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        var routes: [AppScreen.State] = [.home(.init())]
        var currentIndex: Int = 0
    }

    enum Action {
        case home(Home.Action)
        case explore(Explore.Action)
        case profile(Profile.Action)
        case settings(Settings.Action)

        // 네비게이션 액션들
        case navigateTo(AppScreen.State)
        case goBack
        case goToRoot
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.routes[0], action: \.home, child: Home.init)

        Reduce { state, action in
            switch action {
            // 네비게이션 액션 처리
            case .navigateTo(let screen):
                state.routes.append(screen)
                state.currentIndex = state.routes.count - 1
                return .none

            case .goBack:
                if state.routes.count > 1 {
                    state.routes.removeLast()
                    state.currentIndex = state.routes.count - 1
                }
                return .none

            case .goToRoot:
                state.routes = Array(state.routes.prefix(1))
                state.currentIndex = 0
                return .none

            // 각 화면에서 오는 액션들
            case .home(.exploreTapped):
                return .send(.navigateTo(.explore(.init())))

            case .home(.profileTapped):
                return .send(.navigateTo(.profile(.init())))

            case .home(.settingsTapped):
                return .send(.navigateTo(.settings(.init())))

            case .explore(.backTapped):
                return .send(.goBack)

            case .explore(.goToHomeTapped):
                return .send(.goToRoot)

            case .profile(.backTapped):
                return .send(.goBack)

            case .profile(.settingsTapped):
                return .send(.navigateTo(.settings(.init())))

            case .settings(.backTapped):
                return .send(.goBack)

            case .settings(.goToRootTapped):
                return .send(.goToRoot)

            default:
                return .none
            }
        }
    }
}