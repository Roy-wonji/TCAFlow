@_spi(Internals) import ComposableArchitecture
import Perception
import SwiftUI

// MARK: - Route Helpers

extension Route {
    public var isSheet: Bool {
        if case .sheet = self { return true }
        return false
    }

    public var isCover: Bool {
        if case .cover = self { return true }
        return false
    }
}

// MARK: - ScreenStore

@MainActor
public struct ScreenStore<Screen, ScreenAction> {
    private let _store: Store<Screen, ScreenAction>
    init(store: Store<Screen, ScreenAction>) { self._store = store }
}

extension ScreenStore where Screen: CaseReducerState, Screen.StateReducer.Action == ScreenAction {
    public var `case`: Screen.StateReducer.CaseScope { _store.case }
}

extension ScreenStore {
    public var store: Store<Screen, ScreenAction> { _store }
}

// MARK: - _RouteIndex

struct _RouteIndex: Hashable {
    let coordinatorID: UUID
    let index: Int
}

// MARK: - Environment

private struct _InsideNavStackKey: EnvironmentKey {
    static let defaultValue = false
}

private struct _NavigationHostActiveKey: EnvironmentKey {
    static let defaultValue = Binding.constant(false)
}

extension EnvironmentValues {
    var _isInsideNavStack: Bool {
        get { self[_InsideNavStackKey.self] }
        set { self[_InsideNavStackKey.self] = newValue }
    }

    var _isNavigationHostActive: Binding<Bool> {
        get { self[_NavigationHostActiveKey.self] }
        set { self[_NavigationHostActiveKey.self] = newValue }
    }
}


// MARK: - TCAFlowRouter

@MainActor
public struct TCAFlowRouter<Screen, ScreenAction, ScreenContent: View>: View {
    @Perception.Bindable private var store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    private let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    @State private var screenStates: _RouteScreenStateCache<Screen>
    @State private var routeCount: Int

    @Environment(\._isInsideNavStack) private var isInsideNavStack


    public init(
        _ store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
        @ViewBuilder screenContent: @escaping (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    ) {
        self.store = store
        self.screenContent = screenContent
        self._screenStates = State(initialValue: _RouteScreenStateCache(routes: store.currentState))
        self._routeCount = State(initialValue: store.currentState.count)
    }

    func scopedScreenStore(at index: Int) -> ScreenStore<Screen, ScreenAction> {
        let state = screenStates.state(at: index, routes: store.currentState)
        let stateKP: KeyPath<[Route<Screen>], Screen> = \.[retaining: state]
        let actionKP: CaseKeyPath<IndexedRouterAction<Screen, ScreenAction>, ScreenAction> = \.[id: index]
        return ScreenStore(store: store.scope(stateKP, action: actionKP))
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.currentState
            if routeCount > 0, !routes.isEmpty {
                let firstRoute = routes[0]
                switch firstRoute.navigationContext.resolved(
                    isInsideNavigationStack: isInsideNavStack
                ) {
                case .inherited:
                    _InlineRouteChain(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        index: 0
                    )

                case .standalone, .automatic:
                    _StandaloneNavStackHost(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent
                    )

                case .disabled:
                    _screenView(at: 0)
                        .modifier(_SheetMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
                        .modifier(_CoverMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
                }
            }
        }
        .onReceive(store.publisher) { routes in
            screenStates.update(routes)
            routeCount = routes.count
        }
    }

    @ViewBuilder
    func _screenView(at index: Int) -> some View {
        if store.currentState.indices.contains(index) {
            if Screen.self is (any ObservableState).Type {
                WithPerceptionTracking { screenContent(scopedScreenStore(at: index)) }
            } else {
                screenContent(scopedScreenStore(at: index))
            }
        }
    }
}

// MARK: - _InlineRouteChain
/// 부모 NavigationStack 안에서 중첩 코디네이터의 push를
/// navigationDestination(isPresented:) 체이닝으로 처리하는 재귀 뷰.
/// overlay 없이 부모 NavigationStack이 모든 전환 애니메이션과 스와이프백을 처리한다.

@MainActor
private struct _InlineRouteChain<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    let index: Int

    private var routes: [Route<Screen>] { store.currentState }

    @State private var hasNext = false
    @Environment(\._isNavigationHostActive) private var isNavigationHostActive

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { hasNext },
            set: { presented in
                hasNext = presented
                if !presented, routes.indices.contains(index) {
                    // 스와이프백 또는 pop: 현재 인덱스 이후 routes 제거
                    let trimmed = Array(routes.prefix(index + 1))
                    if routes.count != trimmed.count {
                        // 스와이프백 애니메이션과 함께 업데이트
                        let _ = withAnimation(.easeOut(duration: 0.25)) {
                            store.send(.updateRoutes(trimmed))
                        }
                    }
                }
            }
        )
    }

    @ViewBuilder
    private func destination() -> some View {
        let nextIndex = index + 1
        WithPerceptionTracking {
            if routes.indices.contains(nextIndex) {
                if routes[nextIndex].isPush {
                    _InlineRouteChain(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        index: nextIndex
                    )
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        }
    }

    var body: some View {
        WithPerceptionTracking {
            // Keep the retained screen mounted until SwiftUI finishes an interactive pop.
            // Removing it as soon as the route array shrinks exposes the hosting
            // controller's default background during the transition.
            Group {
                if Screen.self is (any ObservableState).Type {
                    WithPerceptionTracking { screenContent(scopedScreenStore(index)) }
                } else {
                    screenContent(scopedScreenStore(index))
                }
            }
            .modifier(_ActiveNavigationDestinationModifier(
                isActive: isNavigationHostActive.wrappedValue,
                isPresented: isPresentedBinding,
                destination: destination
            ))
            .onReceive(store.publisher) { routes in
                hasNext = routes.count > index + 1 && routes[index + 1].isPush
            }
        }
    }
}

@MainActor
private struct _ActiveNavigationDestinationModifier<Destination: View>: ViewModifier {
    let isActive: Bool
    let isPresented: Binding<Bool>
    let destination: @MainActor () -> Destination

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            content.navigationDestination(isPresented: isPresented) {
                destination()
            }
        } else {
            content
        }
    }
}

// MARK: - Standalone Navigation Host

@MainActor
private struct _StandaloneNavStackHost<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    var body: some View {
        Group {
            _SwiftUINavStackHost(
                store: store,
                scopedScreenStore: scopedScreenStore,
                screenContent: screenContent,
                rootIndex: 0
            )
        }
        .modifier(_SheetMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
        .modifier(_CoverMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
    }
}

// MARK: - SwiftUI Navigation Host

@MainActor
private struct _SwiftUINavStackHost<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    let rootIndex: Int

    @State private var coordinatorID = UUID()
    @State private var path: [_RouteIndex] = []
    @State private var isNavigationHostActive = true

    init(
        store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
        scopedScreenStore: @escaping @MainActor (Int) -> ScreenStore<Screen, ScreenAction>,
        screenContent: @escaping (ScreenStore<Screen, ScreenAction>) -> ScreenContent,
        rootIndex: Int
    ) {
        self.store = store
        self.scopedScreenStore = scopedScreenStore
        self.screenContent = screenContent
        self.rootIndex = rootIndex
        let id = UUID()
        _coordinatorID = State(initialValue: id)
        _path = State(initialValue: Self.computePath(
            for: store.currentState, rootIndex: rootIndex, coordinatorID: id
        ))
    }

    private static func computePath(
        for routes: [Route<Screen>], rootIndex: Int, coordinatorID: UUID
    ) -> [_RouteIndex] {
        var indices: [_RouteIndex] = []
        guard rootIndex + 1 < routes.count else { return [] }
        for i in (rootIndex + 1)..<routes.count {
            if routes[i].isPresented { break }
            indices.append(_RouteIndex(coordinatorID: coordinatorID, index: i))
        }
        return indices
    }

    private var pathBinding: Binding<[_RouteIndex]> {
        Binding(
            get: { path },
            set: { newPath in
                let previousCount = path.count
                path = newPath
                guard newPath.count < previousCount else { return }
                let routes = store.currentState
                let desiredCount = rootIndex + newPath.count + 1
                guard routes.count > desiredCount else { return }
                store.send(.updateRoutes(Array(routes.prefix(desiredCount))))
            }
        )
    }

    var body: some View {
        NavigationStack(path: pathBinding) {
            Group {
                if store.currentState.indices.contains(rootIndex) {
                    if Screen.self is (any ObservableState).Type {
                        WithPerceptionTracking { screenContent(scopedScreenStore(rootIndex)) }
                    } else {
                        screenContent(scopedScreenStore(rootIndex))
                    }
                }
            }
            .environment(\._isInsideNavStack, true)
            .environment(\._isNavigationHostActive, $isNavigationHostActive)
            .navigationDestination(for: _RouteIndex.self) { routeIndex in
                // A popped destination remains visible while the transition completes.
                // Its scoped Store retains the last route state for that lifetime.
                if routeIndex.coordinatorID == coordinatorID {
                    Group {
                        if Screen.self is (any ObservableState).Type {
                            WithPerceptionTracking { screenContent(scopedScreenStore(routeIndex.index)) }
                        } else {
                            screenContent(scopedScreenStore(routeIndex.index))
                        }
                    }
                    .environment(\._isInsideNavStack, true)
                    .environment(\._isNavigationHostActive, $isNavigationHostActive)
                }
            }
        }
        .onAppear { isNavigationHostActive = true }
        .onDisappear { isNavigationHostActive = false }
        .onReceive(store.publisher) { routes in
            let expected = Self.computePath(for: routes, rootIndex: rootIndex, coordinatorID: coordinatorID)
            guard path != expected else { return }
            path = expected
        }
    }
}

// MARK: - Sheet Modifier

@MainActor
private struct _SheetMod<Screen, ScreenAction, ScreenContent: View>: ViewModifier {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    private var sheetConfig: SheetConfiguration {
        store.currentState.first(where: { $0.isSheet })?.sheetConfiguration ?? .default
    }

    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(
            get: { store.currentState.contains(where: { $0.isSheet }) },
            set: { if !$0, let i = store.currentState.firstIndex(where: { $0.isSheet }) {
                store.send(.updateRoutes(Array(store.currentState.prefix(i))))
            }}
        )) {
            if let idx = store.currentState.firstIndex(where: { $0.isSheet }) {
                _Presented(idx: idx, store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent)
                    .environment(\._isInsideNavStack, false)
                    .presentationDetents(sheetConfig.detents)
                    .presentationDragIndicator(sheetConfig.showDragIndicator ? .visible : .hidden)
            }
        }
    }
}

// MARK: - Cover Modifier

@MainActor
private struct _CoverMod<Screen, ScreenAction, ScreenContent: View>: ViewModifier {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    func body(content: Content) -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        content.fullScreenCover(isPresented: Binding(
            get: { store.currentState.contains(where: { $0.isCover }) },
            set: { if !$0, let i = store.currentState.firstIndex(where: { $0.isCover }) {
                store.send(.updateRoutes(Array(store.currentState.prefix(i))))
            }}
        )) {
            if let idx = store.currentState.firstIndex(where: { $0.isCover }) {
                _Presented(idx: idx, store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent)
                    .environment(\._isInsideNavStack, false)
            }
        }
        #else
        content.sheet(isPresented: Binding(
            get: { store.currentState.contains(where: { $0.isCover }) },
            set: { if !$0, let i = store.currentState.firstIndex(where: { $0.isCover }) {
                store.send(.updateRoutes(Array(store.currentState.prefix(i))))
            }}
        )) {
            if let idx = store.currentState.firstIndex(where: { $0.isCover }) {
                _Presented(idx: idx, store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent)
                    .environment(\._isInsideNavStack, false)
            }
        }
        #endif
    }
}

// MARK: - Presented Content

@MainActor
private struct _Presented<Screen, ScreenAction, ScreenContent: View>: View {
    let idx: Int
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    @Environment(\._isInsideNavStack) private var isInsideNavStack

    var body: some View {
        WithPerceptionTracking {
            let routes = store.currentState
            if idx < routes.count {
                let route = routes[idx]
                switch route.navigationContext.resolved(
                    isInsideNavigationStack: isInsideNavStack
                ) {
                case .standalone, .automatic:
                    _SwiftUINavStackHost(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        rootIndex: idx
                    )

                case .inherited:
                    _InlineRouteChain(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        index: idx
                    )

                case .disabled:
                    screenContent(scopedScreenStore(idx))
                }
            }
        }
    }
}
