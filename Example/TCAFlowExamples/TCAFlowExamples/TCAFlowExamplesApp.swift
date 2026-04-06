//
//  TCAFlowExamplesApp.swift
//  TCAFlowExamples
//
//  Created by Wonji Suh  on 4/6/26.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCAFlowExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(initialState: AppCoordinator.State()) {
                    AppCoordinator()
                }
            )
        }
    }
}