import SwiftUI

@main
struct TCAFlowExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(
                store: .init(
                    initialState: AppCoordinator.State(),
                    reducer: { AppCoordinator() }
                )
            )
        }
    }
}
