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

extension EnvironmentValues {
    var _isInsideNavStack: Bool {
        get { self[_InsideNavStackKey.self] }
        set { self[_InsideNavStackKey.self] = newValue }
    }
}


// MARK: - TCAFlowRouter

@MainActor
public struct TCAFlowRouter<Screen, ScreenAction, ScreenContent: View>: View {
    @Perception.Bindable private var store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    private let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    @Environment(\._isInsideNavStack) private var isInsideNavStack


    public init(
        _ store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
        @ViewBuilder screenContent: @escaping (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    ) {
        self.store = store
        self.screenContent = screenContent
    }

    func scopedScreenStore(at index: Int) -> ScreenStore<Screen, ScreenAction> {
        let stateKP: KeyPath<[Route<Screen>], Screen> = \.[screenAt: index]
        let actionKP: CaseKeyPath<IndexedRouterAction<Screen, ScreenAction>, ScreenAction> = \.[id: index]
        return ScreenStore(store: store.scope(state: stateKP, action: actionKP))
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.currentState
            if !routes.isEmpty {
                let firstRoute = routes[0]
                if firstRoute.embedInNavigationView && isInsideNavStack {
                    // 부모 NavigationStack 안에서는 별도 NavStack 없이
                    // navigationDestination 체이닝으로 push 처리
                    _InlineRouteChain(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        index: 0
                    )
                } else if firstRoute.embedInNavigationView {
                    _NavStackHost(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent
                    )
                } else {
                    _screenView(at: 0)
                        .modifier(_SheetMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
                        .modifier(_CoverMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
                }
            }
        }
    }

    @ViewBuilder
    func _screenView(at index: Int) -> some View {
        if Screen.self is ObservableState.Type {
            WithPerceptionTracking { screenContent(scopedScreenStore(at: index)) }
        } else {
            screenContent(scopedScreenStore(at: index))
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

    private var hasNext: Bool {
        routes.count > index + 1 && routes[index + 1].isPush
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { hasNext },
            set: { presented in
                if !presented {
                    // 스와이프백 또는 pop: 현재 인덱스 이후 routes 제거
                    let trimmed = Array(routes.prefix(index + 1))
                    if routes.count != trimmed.count {
                        store.send(.updateRoutes(trimmed))
                    }
                }
            }
        )
    }

    var body: some View {
        WithPerceptionTracking {
            Group {
                if Screen.self is ObservableState.Type {
                    WithPerceptionTracking { screenContent(scopedScreenStore(index)) }
                } else {
                    screenContent(scopedScreenStore(index))
                }
            }
            .navigationDestination(isPresented: isPresentedBinding) {
                if routes.count > index + 1 {
                    _InlineRouteChain(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        index: index + 1
                    )
                }
            }
        }
    }
}

// MARK: - _NavStackHost

@MainActor
private struct _NavStackHost<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    @State private var coordinatorID = UUID()
    @State private var path: [_RouteIndex] = []

    private func computePath() -> [_RouteIndex] {
        let routes = store.currentState
        var indices: [_RouteIndex] = []
        for i in 1..<routes.count {
            if routes[i].isPresented { break }
            indices.append(_RouteIndex(coordinatorID: coordinatorID, index: i))
        }
        return indices
    }

    private func syncFromStore(animated: Bool = false) {
        let expected = computePath()
        guard path != expected, !isSyncing else { return }
        isSyncing = true
        if animated {
            var transaction = Transaction(animation: .easeInOut(duration: 0.35))
            transaction.disablesAnimations = false
            withTransaction(transaction) {
                path = expected
            }
        } else {
            path = expected
        }
        isSyncing = false
    }

    @State private var isSyncing = false

    private func syncToStore() {
        guard !isSyncing else { return }
        let routes = store.currentState
        let desired = path.count + 1
        guard routes.count > desired else { return }
        isSyncing = true
        store.send(.updateRoutes(Array(routes.prefix(desired))))
        isSyncing = false
    }

    private var routeCount: Int { store.currentState.count }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if Screen.self is ObservableState.Type {
                    WithPerceptionTracking { screenContent(scopedScreenStore(0)) }
                } else {
                    screenContent(scopedScreenStore(0))
                }
            }
            .navigationDestination(for: _RouteIndex.self) { routeIndex in
                if routeIndex.coordinatorID == coordinatorID {
                    if Screen.self is ObservableState.Type {
                        WithPerceptionTracking { screenContent(scopedScreenStore(routeIndex.index)) }
                    } else {
                        screenContent(scopedScreenStore(routeIndex.index))
                    }
                }
            }
        }
        .environment(\._isInsideNavStack, true)
        .onAppear { syncFromStore() }
        .onChange(of: path) { _ in syncToStore() }
        .background(
            WithPerceptionTracking {
                Color.clear
                    .onChange(of: routeCount) { _ in
                        syncFromStore(animated: true)
                    }
            }
        )
        .modifier(_SheetMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
        .modifier(_CoverMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
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

    @State private var coordinatorID = UUID()
    @State private var path: [_RouteIndex] = []

    private func computePath() -> [_RouteIndex] {
        let routes = store.currentState
        var indices: [_RouteIndex] = []
        for i in (idx + 1)..<routes.count {
            if routes[i].isPresented { break }
            indices.append(_RouteIndex(coordinatorID: coordinatorID, index: i))
        }
        return indices
    }

    private var routeCount: Int { store.currentState.count }

    var body: some View {
        WithPerceptionTracking {
            let routes = store.currentState
            if idx < routes.count {
                let route = routes[idx]
                if route.embedInNavigationView {
                    NavigationStack(path: $path) {
                        screenContent(scopedScreenStore(idx))
                            .navigationDestination(for: _RouteIndex.self) { routeIndex in
                                if routeIndex.coordinatorID == coordinatorID {
                                    screenContent(scopedScreenStore(routeIndex.index))
                                }
                            }
                    }
                    .environment(\._isInsideNavStack, true)
                    .onAppear { path = computePath() }
                    .onChange(of: routeCount) { _ in
                        DispatchQueue.main.async {
                            let expected = computePath()
                            if path != expected { path = expected }
                        }
                    }
                    .onChange(of: path) { _ in
                        let routes = store.currentState
                        let desired = idx + 1 + path.count
                        if routes.count > desired {
                            store.send(.updateRoutes(Array(routes.prefix(desired))))
                        }
                    }
                } else {
                    screenContent(scopedScreenStore(idx))
                }
            }
        }
    }
}
