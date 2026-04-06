//
//  ContentView.swift
//  TCAFlowExamples
//
//  Created by Wonji Suh  on 4/6/26.
//

import SwiftUI
import ComposableArchitecture
import TCAFlow

struct ContentView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        TCAFlowRouter(store.routes) { screen in
            switch screen.case {
            case .home(let homeStore):
                HomeView(store: homeStore)
                    .navigationBarBackButtonHidden()
                    .leadingTransition()

            case .explore(let exploreStore):
                ExploreView(store: exploreStore)
                    .navigationBarBackButtonHidden()
                    .bottomTransition()

            case .profile(let profileStore):
                ProfileView(store: profileStore)
                    .navigationBarBackButtonHidden()
                    .slideTransition()

            case .settings(let settingsStore):
                SettingsView(store: settingsStore)
                    .navigationBarBackButtonHidden()
                    .fadeTransition()
            }
        }
        .animation(.easeInOut(duration: 0.1), value: store.routes.count)
        .transaction { transaction in
            if store.routes.count > 1 {
                transaction.animation = .easeInOut(duration: 0.1)
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: AppCoordinator.State()) {
            AppCoordinator()
        }
    )
}