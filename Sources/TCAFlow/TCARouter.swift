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

// MARK: - _StackReplacerHolder

/// Observable object that allows a nested TCAFlowRouter to register its content
/// for stack replacement rendering in the parent _NavStackHost.
@MainActor
final class _StackReplacerHolder: ObservableObject {
    @Published var content: AnyView?
    @Published var isActive = false
    var onDismiss: (() -> Void)?
}

private struct _StackReplacerHolderKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: _StackReplacerHolder? = nil
}

extension EnvironmentValues {
    var _stackReplacerHolder: _StackReplacerHolder? {
        get { self[_StackReplacerHolderKey.self] }
        set { self[_StackReplacerHolderKey.self] = newValue }
    }
}

// MARK: - TCAFlowRouter

@MainActor
public struct TCAFlowRouter<Screen, ScreenAction, ScreenContent: View>: View {
    @Perception.Bindable private var store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    private let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    @Environment(\._isInsideNavStack) private var isInsideNavStack
    @Environment(\._stackReplacerHolder) private var stackReplacerHolder

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
                    // Register for stack replacement in parent
                    _StackReplacementRegistrar(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        holder: stackReplacerHolder
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

// MARK: - _StackReplacementRegistrar
/// Invisible view placed inside parent's navigationDestination.
/// On appear: tells parent to show the nested NavigationStack as overlay.
/// On disappear (swipe back): tells parent to hide it.

@MainActor
private struct _StackReplacementRegistrar<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    let holder: _StackReplacerHolder?

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                holder?.content = AnyView(
                    _NavStackHost(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent
                    )
                )
                withAnimation(.easeInOut(duration: 0.35)) {
                    holder?.isActive = true
                }
            }
            .onDisappear {
                withAnimation(.easeInOut(duration: 0.35)) {
                    holder?.isActive = false
                }
                holder?.content = nil
            }
    }
}

// MARK: - _EdgeSwipeBackModifier
/// 중첩 코디네이터 overlay 루트에서 에지 스와이프백을 감지하여 부모로 돌아가는 제스처

#if os(iOS)
@MainActor
private struct _EdgeSwipeBackModifier: ViewModifier {
    let onSwipeBack: () -> Void
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    func body(content: Content) -> some View {
        content
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .global)
                    .updating($dragOffset) { value, state, _ in
                        // 왼쪽 가장자리 30pt 이내에서 시작한 오른쪽 드래그만 처리
                        if value.startLocation.x < 30 && value.translation.width > 0 {
                            state = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.startLocation.x < 30 && value.translation.width > 80 {
                            onSwipeBack()
                        }
                    }
            )
    }
}
#endif

// MARK: - _NavStackHost

@MainActor
private struct _NavStackHost<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    @State private var coordinatorID = UUID()
    @State private var path: [_RouteIndex] = []
    @StateObject private var stackReplacer = _StackReplacerHolder()

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
        guard path != expected else { return }
        if animated {
            var transaction = Transaction(animation: .easeInOut(duration: 0.35))
            transaction.disablesAnimations = false
            withTransaction(transaction) {
                path = expected
            }
        } else {
            path = expected
        }
    }

    private func syncToStore() {
        let routes = store.currentState
        let desired = path.count + 1
        if routes.count > desired {
            store.send(.updateRoutes(Array(routes.prefix(desired))))
        }
    }

    private var routeCount: Int { store.currentState.count }

    var body: some View {
        ZStack {
            // Layer 1: This coordinator's NavigationStack
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
            .environment(\._stackReplacerHolder, stackReplacer)
            .onAppear {
                syncFromStore()
                // 중첩 코디네이터에서 스와이프백 시 부모 routes pop
                stackReplacer.onDismiss = { [weak store] in
                    guard let store = store else { return }
                    let routes = store.currentState
                    if routes.count > 1 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            store.send(.updateRoutes(Array(routes.dropLast())))
                        }
                    }
                }
            }
            .onChange(of: path) { _ in syncToStore() }
            .background(
                // routeCount 관찰은 WithPerceptionTracking 안에서,
                // NavigationStack은 바깥에 두어 애니메이션 컨텍스트 보존
                WithPerceptionTracking {
                    Color.clear
                        .onChange(of: routeCount) { _ in
                            syncFromStore(animated: true)
                        }
                }
            )
            .opacity(stackReplacer.isActive ? 0 : 1)
            .animation(.easeInOut(duration: 0.35), value: stackReplacer.isActive)

            // Layer 2: Stack replacement content (nested coordinator's NavigationStack)
            if stackReplacer.isActive, let content = stackReplacer.content {
                #if os(iOS)
                content
                    .transition(.move(edge: .trailing))
                    .modifier(_EdgeSwipeBackModifier {
                        // 중첩 코디네이터의 루트에서 스와이프백 → 부모로 pop
                        stackReplacer.onDismiss?()
                    })
                #else
                content
                    .transition(.move(edge: .trailing))
                #endif
            }
        }
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
