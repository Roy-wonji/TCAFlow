// MARK: - ForEachRoute 매크로 없이 사용하는 예제

import TCAFlow
import ComposableArchitecture

// MARK: - Clean Coordinator Implementation (매크로 없이 깔끔한 방식)

struct SimpleCoordinator: Reducer {
    @ObservableState
    struct State: Equatable {
        var routes = RouteStack<Screen>([
            Route.root(.home(HomeFeature.State()))
        ])
    }

    enum Screen: Equatable {
        case home(HomeFeature.State)
        case detail(DetailFeature.State)
        case settings(SettingsFeature.State)
    }

    @CasePathable
    enum ScreenAction: Equatable {
        case home(HomeFeature.Action)
        case detail(DetailFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @CasePathable
    enum Action {
        case route(FlowAction<ScreenAction>)
        case navigate(NavigationAction)
    }

    enum NavigationAction {
        case pushDetail
        case pushSettings
        case popToRoot
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .navigate(navAction):
                return handleNavigation(navAction, state: &state)

            case let .route(routeAction):
                // 🎯 라우트 액션을 깔끔하게 처리
                guard let (id, screenAction) = routeAction.routeInfo else {
                    return .none // pathChanged는 자동 처리됨
                }
                return handleScreenAction(screenAction, id: id, state: &state)
            }
        }
        // 🎯 pathChanged 자동 처리!
        .forEachRoute(\.routes, action: \.route)
    }

    // 각 스크린 액션을 깔끔하게 처리
    private func handleScreenAction(
        _ screenAction: ScreenAction,
        id: UUID,
        state: inout State
    ) -> Effect<Action> {
        switch screenAction {
        case let .home(homeAction):
            return handleHomeAction(homeAction, state: &state)

        case let .detail(detailAction):
            return handleDetailAction(detailAction, id: id, state: &state)

        case let .settings(settingsAction):
            return handleSettingsAction(settingsAction, state: &state)
        }
    }

    private func handleNavigation(
        _ action: NavigationAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .pushDetail:
            state.routes.push(.detail(DetailFeature.State()))
            return .none

        case .pushSettings:
            state.routes.push(.settings(SettingsFeature.State()))
            return .none

        case .popToRoot:
            state.routes.popToRoot()
            return .none
        }
    }

    // 각 Feature별 액션 처리를 Extension으로 분리 가능
    private func handleHomeAction(
        _ action: HomeFeature.Action,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .navigateToDetail:
            return .send(.navigate(.pushDetail))

        case .navigateToSettings:
            return .send(.navigate(.pushSettings))

        case .titleChanged:
            // HomeFeature 내부에서 처리되므로 별도 처리 불필요
            return .none
        }
    }

    private func handleDetailAction(
        _ action: DetailFeature.Action,
        id: UUID,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .close:
            state.routes.pop()
            return .none

        case .contentChanged:
            // DetailFeature 내부에서 처리되므로 별도 처리 불필요
            return .none
        }
    }

    private func handleSettingsAction(
        _ action: SettingsFeature.Action,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .close:
            state.routes.pop()
            return .none

        case .toggleNotifications:
            // SettingsFeature 내부에서 처리되므로 별도 처리 불필요
            return .none
        }
    }
}

// MARK: - 더욱 간단한 예제: 최소한의 보일러플레이트

struct MinimalCoordinator: Reducer {
    @ObservableState
    struct State: Equatable {
        var routes = RouteStack<Screen>([
            Route.root(.home(HomeFeature.State()))
        ])
    }

    enum Screen: Equatable {
        case home(HomeFeature.State)
        case detail(DetailFeature.State)
        case settings(SettingsFeature.State)
    }

    @CasePathable
    enum ScreenAction: Equatable {
        case home(HomeFeature.Action)
        case detail(DetailFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @CasePathable
    enum Action {
        case route(FlowAction<ScreenAction>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .route(routeAction):
                // 🎯 RouteAction 헬퍼로 깔끔하게 처리
                if routeAction.isPathChanged {
                    return .none // 자동 처리됨
                }

                guard let (_, screenAction) = routeAction.routeInfo else { return .none }

                // 네비게이션 액션만 여기서 처리, 나머지는 각 Feature에서
                switch screenAction {
                case .home(.navigateToDetail):
                    state.routes.push(.detail(DetailFeature.State()))
                    return .none

                case .home(.navigateToSettings):
                    state.routes.push(.settings(SettingsFeature.State()))
                    return .none

                case .detail(.close), .settings(.close):
                    state.routes.pop()
                    return .none

                default:
                    // Feature 내부 액션들은 자동으로 각 Feature에서 처리됨
                    return .none
                }
            }
        }
        .forEachRoute(\.routes, action: \.route)
        // 🎯 각 Feature의 리듀서는 TCA의 기본 forEach 패턴 사용
        .forEach(\.routes.routes, action: \.route.routeAction) {
            EmptyReducer<Screen, ScreenAction>()
        }
    }
}

// MARK: - Feature Definitions

struct HomeFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var title = "Home"
    }

    @CasePathable
    enum Action: Equatable {
        case navigateToDetail
        case navigateToSettings
        case titleChanged(String)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .titleChanged(let newTitle):
                state.title = newTitle
                return .none
            case .navigateToDetail, .navigateToSettings:
                // 네비게이션은 상위 coordinator에서 처리
                return .none
            }
        }
    }
}

struct DetailFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var content = "Detail Content"
    }

    @CasePathable
    enum Action: Equatable {
        case close
        case contentChanged(String)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .contentChanged(let newContent):
                state.content = newContent
                return .none
            case .close:
                return .none
            }
        }
    }
}

struct SettingsFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var isNotificationsEnabled = false
    }

    @CasePathable
    enum Action: Equatable {
        case toggleNotifications
        case close
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleNotifications:
                state.isNotificationsEnabled.toggle()
                return .none
            case .close:
                return .none
            }
        }
    }
}

// MARK: - 사용 예제 비교

/*
// ❌ 기존 방식 (매크로 없이 수동 처리)
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .route(let routeAction):
            switch routeAction {
            case .routeAction(let id, let screenAction):
                switch screenAction {
                case .home(let homeAction):
                    // 수동으로 각 액션 처리...
                    return handleHomeAction(homeAction, id: id, state: &state)
                case .detail(let detailAction):
                    // 수동으로 각 액션 처리...
                    return handleDetailAction(detailAction, id: id, state: &state)
                // ... 계속 반복
                }
            case .pathChanged(let path):
                // 수동으로 경로 변경 처리...
                let routeIDs = [state.routes.routes.first?.id].compactMap { $0 } + path
                while let last = state.routes.routes.last, !routeIDs.contains(last.id) {
                    state.routes.pop()
                }
                return .none
            }
        }
    }
}

// ✅ 새로운 방식 (TCAFlow 헬퍼 사용)
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .route(let routeAction):
            // 🎯 헬퍼로 깔끔하게 처리
            guard let (id, screenAction) = routeAction.routeInfo else {
                return .none // pathChanged는 자동 처리됨
            }
            return handleScreenAction(screenAction, id: id, state: &state)
        }
    }
    .forEachRoute(\.routes, action: \.route) // 🎯 pathChanged 자동 처리
}

// 🚀 더 간단한 방식 (네비게이션만 처리)
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .route(let routeAction):
            guard let (_, screenAction) = routeAction.routeInfo else { return .none }

            // 네비게이션 액션만 처리하고 나머지는 각 Feature가 알아서 처리
            switch screenAction {
            case .home(.navigateToDetail):
                state.routes.push(.detail(DetailFeature.State()))
                return .none
            case .detail(.close):
                state.routes.pop()
                return .none
            default:
                return .none
            }
        }
    }
    .forEachRoute(\.routes, action: \.route)
}
*/