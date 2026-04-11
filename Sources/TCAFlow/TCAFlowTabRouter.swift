import ComposableArchitecture
import Perception
import SwiftUI

// MARK: - TabRouterAction

/// 탭 기반 코디네이터의 액션.
@CasePathable
public enum TabRouterAction<Tab, TabAction> {
    /// 탭 선택 변경
    case selectTab(Int)
    /// 특정 탭의 액션
    case tabAction(index: Int, action: TabAction)
    /// 현재 활성 탭을 다시 탭했을 때 (popToRoot)
    case tabReselected(Int)
}

public typealias IndexedTabRouterAction<Tab, TabAction> = TabRouterAction<Tab, TabAction>

// MARK: - TCAFlowTabRouter

/// 탭 기반 네비게이션을 관리하는 뷰.
/// 각 탭은 독립적인 NavigationStack을 가집니다.
///
/// 사용법:
/// ```swift
/// struct MainTabView: View {
///     @Bindable var store: StoreOf<MainTabCoordinator>
///
///     var body: some View {
///         TCAFlowTabRouter(
///             store: store,
///             selectedTab: $store.selectedTab.sending(\.selectTab),
///             tabs: [
///                 TabItem(title: "홈", icon: "house", tag: 0),
///                 TabItem(title: "검색", icon: "magnifyingglass", tag: 1),
///                 TabItem(title: "프로필", icon: "person", tag: 2)
///             ]
///         ) { index in
///             switch index {
///             case 0: HomeCoordinatorView(store: store.scope(state: \.homeState, action: \.home))
///             case 1: SearchCoordinatorView(store: store.scope(state: \.searchState, action: \.search))
///             case 2: ProfileCoordinatorView(store: store.scope(state: \.profileState, action: \.profile))
///             default: EmptyView()
///             }
///         }
///     }
/// }
/// ```
@MainActor
public struct TCAFlowTabRouter<Content: View>: View {
    private let selectedTab: Binding<Int>
    private let tabs: [TabItem]
    private let content: (Int) -> Content
    private let onReselect: ((Int) -> Void)?

    public init(
        selectedTab: Binding<Int>,
        tabs: [TabItem],
        onReselect: ((Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.selectedTab = selectedTab
        self.tabs = tabs
        self.onReselect = onReselect
        self.content = content
    }

    public var body: some View {
        TabView(selection: Binding(
            get: { selectedTab.wrappedValue },
            set: { newTab in
                if newTab == selectedTab.wrappedValue {
                    // 같은 탭 재탭 → popToRoot 콜백
                    onReselect?(newTab)
                }
                selectedTab.wrappedValue = newTab
            }
        )) {
            ForEach(tabs) { tab in
                content(tab.tag)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab.tag)
            }
        }
    }
}

// MARK: - TabItem

/// 탭 아이템 정의
public struct TabItem: Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let icon: String
    public let tag: Int

    public init(title: String, icon: String, tag: Int) {
        self.id = tag
        self.title = title
        self.icon = icon
        self.tag = tag
    }
}

// MARK: - TabCoordinatorState Protocol

/// 탭 코디네이터 State가 구현해야 하는 프로토콜.
/// 각 탭의 routes에 접근할 수 있게 합니다.
///
/// 사용법:
/// ```swift
/// struct MainTabState: TabCoordinatorState {
///     var selectedTab: Int = 0
///     var homeRoutes: [Route<HomeScreen.State>] = [.root(.home(.init()))]
///     var searchRoutes: [Route<SearchScreen.State>] = [.root(.search(.init()))]
///
///     mutating func popToRoot(tab: Int) {
///         switch tab {
///         case 0: homeRoutes.goBackToRoot()
///         case 1: searchRoutes.goBackToRoot()
///         default: break
///         }
///     }
/// }
/// ```
public protocol TabCoordinatorState {
    var selectedTab: Int { get set }
    mutating func popToRoot(tab: Int)
}
