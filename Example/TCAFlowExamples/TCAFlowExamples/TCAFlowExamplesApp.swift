import SwiftUI
import ComposableArchitecture

@main
struct TCAFlowExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            AuthCoordinatorView(
                store: Store(initialState: AuthCoordinator.State()) {
                    AuthCoordinator()
                }
            )
        }
    }
}
