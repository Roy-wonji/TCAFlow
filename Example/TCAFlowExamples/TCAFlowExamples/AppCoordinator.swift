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
@FlowCoordinator
@Reducer
struct AppCoordinator {
    enum Screen {
        case home(Home)
        case explore(Explore)
        case profile(Profile)
        case settings(Settings)
    }
}
