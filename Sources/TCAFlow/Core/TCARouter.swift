@_spi(Internals) import ComposableArchitecture
import Perception
import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

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
        return ScreenStore(store: store.scope(stateKP, action: actionKP))
    }

    public var body: some View {
        WithPerceptionTracking {
            let routes = store.currentState
            if !routes.isEmpty {
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
    }

    @ViewBuilder
    func _screenView(at index: Int) -> some View {
        if Screen.self is (any ObservableState).Type {
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
                        // 스와이프백 애니메이션과 함께 업데이트
                        let _ = withAnimation(.easeOut(duration: 0.25)) {
                            store.send(.updateRoutes(trimmed))
                        }
                    }
                }
            }
        )
    }

    var body: some View {
        WithPerceptionTracking {
            Group {
                if Screen.self is (any ObservableState).Type {
                    WithPerceptionTracking { screenContent(scopedScreenStore(index)) }
                } else {
                    screenContent(scopedScreenStore(index))
                }
            }
            .navigationDestination(isPresented: isPresentedBinding) {
                Group {
                    if routes.count > index + 1 {
                        _InlineRouteChain(
                            store: store,
                            scopedScreenStore: scopedScreenStore,
                            screenContent: screenContent,
                            index: index + 1
                        )
                    } else {
                        EmptyView()
                    }
                }
            }
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
            #if canImport(UIKit) && !os(watchOS)
            _UIKitNavStackHost(
                store: store,
                scopedScreenStore: scopedScreenStore,
                screenContent: screenContent,
                rootIndex: 0
            )
            #else
            _SwiftUINavStackHost(
                store: store,
                scopedScreenStore: scopedScreenStore,
                screenContent: screenContent,
                rootIndex: 0
            )
            #endif
        }
        .modifier(_SheetMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
        .modifier(_CoverMod(store: store, scopedScreenStore: scopedScreenStore, screenContent: screenContent))
    }
}

// MARK: - SwiftUI Navigation Fallback

@MainActor
private struct _SwiftUINavStackHost<Screen, ScreenAction, ScreenContent: View>: View {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    let rootIndex: Int

    @State private var coordinatorID = UUID()
    @State private var path: [_RouteIndex] = []

    private func computePath() -> [_RouteIndex] {
        let routes = store.currentState
        var indices: [_RouteIndex] = []
        guard rootIndex + 1 < routes.count else { return [] }
        for i in (rootIndex + 1)..<routes.count {
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
        let desired = rootIndex + path.count + 1
        guard routes.count > desired else { return }
        isSyncing = true

        // 스와이프백 처리를 위한 애니메이션과 함께 업데이트
        DispatchQueue.main.async {
            let _ = withAnimation(.easeOut(duration: 0.25)) {
                store.send(.updateRoutes(Array(routes.prefix(desired))))
            }

            // 동기화 플래그를 지연 해제하여 스와이프 제스처와 충돌 방지
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSyncing = false
            }
        }
    }

    private var routeCount: Int { store.currentState.count }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if Screen.self is (any ObservableState).Type {
                    WithPerceptionTracking { screenContent(scopedScreenStore(rootIndex)) }
                } else {
                    screenContent(scopedScreenStore(rootIndex))
                }
            }
            .navigationDestination(for: _RouteIndex.self) { routeIndex in
                if routeIndex.coordinatorID == coordinatorID {
                    if Screen.self is (any ObservableState).Type {
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
    }
}

#if canImport(UIKit) && !os(watchOS)
// MARK: - UIKitNavigation Host

/// SwiftUI 진입점의 standalone 흐름을 UIKitNavigation이 소유하도록 연결한다.
/// NavigationStackController는 representable 생명주기 동안 한 번만 생성된다.
@MainActor
private struct _UIKitNavStackHost<Screen, ScreenAction, ScreenContent: View>: UIViewControllerRepresentable {
    let store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
    let scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent
    let rootIndex: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(
            store: store,
            scopedScreenStore: scopedScreenStore,
            screenContent: screenContent,
            rootIndex: rootIndex
        )
    }

    func makeUIViewController(context: Context) -> NavigationStackController {
        let coordinator = context.coordinator
        coordinator.synchronizeFromStore(animated: false)

        let navigationController = NavigationStackController(path: coordinator.$path) {
            coordinator.makeScreenViewController(at: coordinator.rootIndex)
        }
        navigationController.navigationDestination(for: _RouteIndex.self) { [weak coordinator] routeIndex in
            guard
                let coordinator,
                routeIndex.coordinatorID == coordinator.coordinatorID
            else { return UIViewController() }
            return coordinator.makeScreenViewController(at: routeIndex.index)
        }
        return navigationController
    }

    func updateUIViewController(
        _ navigationController: NavigationStackController,
        context: Context
    ) {
        context.coordinator.update(
            store: store,
            scopedScreenStore: scopedScreenStore,
            screenContent: screenContent,
            rootIndex: rootIndex
        )
        context.coordinator.refreshRoot(in: navigationController)
        context.coordinator.synchronizeFromStore(animated: true)
    }

    static func dismantleUIViewController(
        _ navigationController: NavigationStackController,
        coordinator: Coordinator
    ) {
        coordinator.invalidate()
        navigationController.delegate = nil
    }

    @MainActor
    final class Coordinator: NSObject {
        let coordinatorID = UUID()

        var store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>
        var scopedScreenStore: @MainActor (Int) -> ScreenStore<Screen, ScreenAction>
        var screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent
        var rootIndex: Int
        private var isApplyingStorePath = false
        private var isActive = true

        @UIBinding var path: [_RouteIndex] = [] {
            didSet { synchronizeToStore() }
        }

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
        }

        func update(
            store: Store<[Route<Screen>], IndexedRouterAction<Screen, ScreenAction>>,
            scopedScreenStore: @escaping @MainActor (Int) -> ScreenStore<Screen, ScreenAction>,
            screenContent: @escaping (ScreenStore<Screen, ScreenAction>) -> ScreenContent,
            rootIndex: Int
        ) {
            self.store = store
            self.scopedScreenStore = scopedScreenStore
            self.screenContent = screenContent
            self.rootIndex = rootIndex
        }

        func makeScreenViewController(at index: Int) -> UIViewController {
            UIHostingController(rootView: hostedScreen(at: index))
        }

        func refreshRoot(in navigationController: NavigationStackController) {
            guard
                let root = navigationController.viewControllers.first as? UIHostingController<AnyView>
            else { return }
            root.rootView = hostedScreen(at: rootIndex)
        }

        func synchronizeFromStore(animated: Bool) {
            guard isActive else { return }
            let expected = expectedPath()
            guard path != expected else { return }

            isApplyingStorePath = true
            withUITransaction(\.uiKit.disablesAnimations, !animated) {
                path = expected
            }
            isApplyingStorePath = false
        }

        private func synchronizeToStore() {
            guard isActive, !isApplyingStorePath else { return }
            guard path.allSatisfy({ $0.coordinatorID == coordinatorID }) else {
                synchronizeFromStore(animated: false)
                return
            }

            let routes = store.currentState
            let desiredCount = rootIndex + path.count + 1
            guard routes.count > desiredCount else { return }
            store.send(.updateRoutes(Array(routes.prefix(desiredCount))))
        }

        private func expectedPath() -> [_RouteIndex] {
            let routes = store.currentState
            guard rootIndex + 1 < routes.count else { return [] }

            var result: [_RouteIndex] = []
            for index in (rootIndex + 1)..<routes.count {
                if routes[index].isPresented { break }
                result.append(_RouteIndex(coordinatorID: coordinatorID, index: index))
            }
            return result
        }

        private func hostedScreen(at index: Int) -> AnyView {
            AnyView(
                _HostedScreen(
                    screenStore: scopedScreenStore(index),
                    screenContent: screenContent
                )
                .environment(\._isInsideNavStack, true)
            )
        }

        func invalidate() {
            isActive = false
        }
    }
}

@MainActor
private struct _HostedScreen<Screen, ScreenAction, ScreenContent: View>: View {
    let screenStore: ScreenStore<Screen, ScreenAction>
    let screenContent: (ScreenStore<Screen, ScreenAction>) -> ScreenContent

    var body: some View {
        Group {
            if Screen.self is (any ObservableState).Type {
                WithPerceptionTracking { screenContent(screenStore) }
            } else {
                screenContent(screenStore)
            }
        }
    }
}
#endif

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
                    #if canImport(UIKit) && !os(watchOS)
                    _UIKitNavStackHost(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        rootIndex: idx
                    )
                    #else
                    _SwiftUINavStackHost(
                        store: store,
                        scopedScreenStore: scopedScreenStore,
                        screenContent: screenContent,
                        rootIndex: idx
                    )
                    #endif

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
