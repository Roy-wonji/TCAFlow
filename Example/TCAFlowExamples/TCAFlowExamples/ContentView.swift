//
//  ContentView.swift
//  TCAFlowExamples
//
//  Created by Wonji Suh  on 4/6/26.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        NavigationStack {
            if let currentScreen = store.routes.last {
                screenView(currentScreen)
            } else {
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.routes.count)
    }

    @ViewBuilder
    private func screenView(_ screen: AppScreen.State) -> some View {
        switch screen {
        case .home(let homeState):
            HomeView(store: store.scope(state: \.routes[0], action: \.home))
                .navigationBarBackButtonHidden()
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))

        case .explore(let exploreState):
            ExploreView(store: store.scope(
                state: { _ in exploreState },
                action: { .explore($0) }
            ))
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))

        case .profile(let profileState):
            ProfileView(store: store.scope(
                state: { _ in profileState },
                action: { .profile($0) }
            ))
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .settings(let settingsState):
            SettingsView(store: store.scope(
                state: { _ in settingsState },
                action: { .settings($0) }
            ))
            .navigationBarBackButtonHidden()
            .transition(.opacity)
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