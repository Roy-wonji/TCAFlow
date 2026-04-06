//
//  AppCoordinator.swift
//  TCAFlowExamples
//
//  Created by Wonji Suh  on 4/6/26.
//

import Foundation
import ComposableArchitecture
import TCAFlow

// MARK: - AppScreen
@Reducer
enum AppScreen {
    case home(Home.State)
    case explore(Explore.State)
    case profile(Profile.State)
    case settings(Settings.State)
}

// MARK: - AppCoordinator
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

        // 각 화면 액션들
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
                state.routes.goTo(.profile(.init()))
                return .none

            case .home(.settingsTapped):
                state.routes.push(.settings(.init()))
                return .none

            // Explore 액션들
            case .explore(.backTapped):
                state.routes.pop()
                return .none

            case .explore(.goToHomeTapped):
                state.routes.goBackTo(.home(.init()))
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
        // TCA 표준 forEach 사용 - 각 화면 처리
        .forEach(\.routes, action: \.router) {
            AppScreen()
        }
    }
}