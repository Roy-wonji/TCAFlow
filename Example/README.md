# 🚀 TCAFlow iOS 예제 프로젝트

**5분만에 완성하는 TCAFlow 예제!**

## 📱 Xcode 프로젝트 생성 (5분 가이드)

### 1단계: 새 iOS 프로젝트 생성
```
1. Xcode 실행
2. "Create New Project" 클릭
3. iOS → App 선택
4. 다음 정보 입력:
   - Product Name: TCAFlowExample
   - Interface: SwiftUI
   - Language: Swift
   - Bundle Identifier: com.yourname.tcaflowexample
   - Use Core Data: 체크 해제
   - Include Tests: 체크 해제 (간단하게 하기 위해)
5. 저장 위치 선택 후 Create
```

### 2단계: TCAFlow 패키지 추가
```
1. 프로젝트 네비게이터에서 프로젝트 파일(파란 아이콘) 선택
2. "Package Dependencies" 탭 클릭
3. "+" 버튼 클릭
4. "Add Local..." 버튼 클릭
5. TCAFlow 폴더 선택 (이 README가 있는 상위 폴더)
   경로: /Users/suhwonji/Desktop/SideProject/TCAFlow
6. "Add Package" 클릭
7. TCAFlow 체크하고 "Add Package" 클릭
```

### 3단계: TCA 패키지 추가
```
1. 다시 "+" 버튼 클릭
2. 다음 URL 입력:
   https://github.com/pointfreeco/swift-composable-architecture
3. "Add Package" 클릭
4. Version: "Up to Next Major" → "1.25.5" 입력
5. "Add Package" 클릭
6. "ComposableArchitecture" 체크하고 "Add Package" 클릭
```

### 4단계: 소스 파일 교체
기존 파일들을 아래 내용으로 교체하세요:

#### 📄 TCAFlowExampleApp.swift
```swift
import SwiftUI
import TCAFlow
import ComposableArchitecture

@main
struct TCAFlowExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(initialState: AppCoordinator.State()) {
                    AppCoordinator()
                }
            )
            .onAppear {
                print("🚀 TCAFlow 예제 앱 시작!")
                print("✅ Hashable 제약 없음")
                print("✅ 스크린 직접 넣기")
            }
        }
    }
}
```

#### 📄 ContentView.swift (교체)
```swift
import SwiftUI
import TCAFlow
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    var body: some View {
        NavigationStack(path: $store.routes) {
            HomeView(store: store.scope(state: \.homeState, action: \.home))
                .navigationDestination(for: Route<AppScreen.State>.self) { route in
                    screenView(for: route.state)
                }
        }
    }

    @ViewBuilder
    private func screenView(for screenState: AppScreen.State) -> some View {
        switch screenState {
        case .detail(let detailState):
            DetailView(
                store: Store(initialState: detailState) { Detail() },
                coordinator: store
            )
        case .profile(let profileState):
            ProfileView(
                store: Store(initialState: profileState) { Profile() },
                coordinator: store
            )
        case .settings(let settingsState):
            SettingsView(
                store: Store(initialState: settingsState) { Settings() },
                coordinator: store
            )
        case .map(let mapState):
            MapView(
                store: Store(initialState: mapState) { MapFeature() },
                coordinator: store
            )
        default:
            EmptyView()
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
```

#### 📄 AppScreen.swift (새로 생성)
```swift
import ComposableArchitecture
import CoreLocation

// MARK: - 앱 스크린 (Hashable 제약 없음!)
@Reducer
enum AppScreen {
    case home(Home.State)
    case detail(Detail.State)
    case profile(Profile.State)
    case settings(Settings.State)
    case map(MapFeature.State)  // CLLocationCoordinate2D!
}

// MARK: - Home
@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        var counter = 0
    }

    enum Action {
        case increment, decrement
        case detailButtonTapped, profileButtonTapped
        case settingsButtonTapped, mapButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .increment: state.counter += 1; return .none
            case .decrement: state.counter -= 1; return .none
            default: return .none
            }
        }
    }
}

// MARK: - Detail
@Reducer
struct Detail {
    @ObservableState
    struct State: Equatable {
        let id = UUID().uuidString
        var name: String
        var isLoading = false
        init(name: String = "상세 정보") { self.name = name }
    }

    enum Action {
        case load, updateName(String)
        case backButtonTapped, profileButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                state.isLoading = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    await send(.updateName("로드된 데이터"))
                }
            case let .updateName(name):
                state.name = name; state.isLoading = false; return .none
            default: return .none
            }
        }
    }
}

// MARK: - Profile
@Reducer
struct Profile {
    @ObservableState
    struct State: Equatable {
        var username: String; var email: String; var isEditing = false
        init(username: String = "사용자", email: String = "user@example.com") {
            self.username = username; self.email = email
        }
    }

    enum Action {
        case editButtonTapped, saveButtonTapped
        case updateUsername(String), updateEmail(String)
        case backButtonTapped, settingsButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .editButtonTapped: state.isEditing.toggle(); return .none
            case .saveButtonTapped: state.isEditing = false; return .none
            case let .updateUsername(name): state.username = name; return .none
            case let .updateEmail(email): state.email = email; return .none
            default: return .none
            }
        }
    }
}

// MARK: - Settings
@Reducer
struct Settings {
    @ObservableState
    struct State: Equatable {
        var isDarkMode = false, notificationsEnabled = true
        var version = "1.0.0"
    }

    enum Action {
        case toggleDarkMode, toggleNotifications
        case backButtonTapped, resetToDefaults
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleDarkMode: state.isDarkMode.toggle(); return .none
            case .toggleNotifications: state.notificationsEnabled.toggle(); return .none
            case .resetToDefaults: state = State(); return .none
            default: return .none
            }
        }
    }
}

// MARK: - Map (🔥 CLLocationCoordinate2D!)
@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        let location: CLLocationCoordinate2D  // 🔥 Hashable 아님!
        var title: String, zoom: Double

        init(location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), title: String = "서울시청", zoom: Double = 1.0) {
            self.location = location; self.title = title; self.zoom = zoom
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.location.latitude == rhs.location.latitude &&
            lhs.location.longitude == rhs.location.longitude &&
            lhs.title == rhs.title && lhs.zoom == rhs.zoom
        }
    }

    enum Action {
        case updateLocation(CLLocationCoordinate2D), updateTitle(String)
        case zoomIn, zoomOut, backButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .updateLocation(loc):
                state = State(location: loc, title: state.title, zoom: state.zoom); return .none
            case let .updateTitle(title): state.title = title; return .none
            case .zoomIn: state.zoom = min(state.zoom * 2, 16.0); return .none
            case .zoomOut: state.zoom = max(state.zoom / 2, 0.25); return .none
            default: return .none
            }
        }
    }
}
```

#### 📄 AppCoordinator.swift (새로 생성)
```swift
import TCAFlow
import ComposableArchitecture

@Reducer
struct AppCoordinator {
    @ObservableState
    struct State: Equatable {
        // 🔥 TCAFlow - Hashable 제약 없음!
        var routes: IdentifiedArrayOf<Route<AppScreen.State>> = []
        var homeState = Home.State()
    }

    enum Action {
        case router(FlowActionOf<AppScreen>)
        case home(Home.Action), detail(Detail.Action)
        case profile(Profile.Action), settings(Settings.Action)
        case map(MapFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.homeState, action: \.home) { Home() }

        Reduce { state, action in
            switch action {
            // 🔥 기본 push
            case .home(.detailButtonTapped):
                print("🔥 Detail로 이동")
                state.routes.push(.detail(.init(name: "홈에서 온 상세정보")))
                return .none

            // 🔥 goTo (있으면 그곳으로)
            case .home(.profileButtonTapped):
                print("🔥 Profile로 이동 (goTo)")
                state.routes.goTo(.profile(.init()))
                return .none

            case .home(.settingsButtonTapped):
                print("🔥 Settings로 이동")
                state.routes.push(.settings(.init()))
                return .none

            // 🔥 CLLocationCoordinate2D!
            case .home(.mapButtonTapped):
                print("🔥 Map으로 이동 (CLLocationCoordinate2D!)")
                state.routes.push(.map(.init()))
                return .none

            // 🔥 뒤로 가기들
            case .detail(.backButtonTapped), .profile(.backButtonTapped),
                 .settings(.backButtonTapped), .map(.backButtonTapped):
                print("🔥 뒤로 가기")
                state.routes.pop()
                return .none

            case .detail(.profileButtonTapped):
                state.routes.push(.profile(.init(username: "Detail 사용자")))
                return .none

            case .profile(.settingsButtonTapped):
                state.routes.push(.settings(.init()))
                return .none

            default: return .none
            }
        }
        // 🔥 TCACoordinators와 동일!
        .forEach(\.routes, action: \.router) { AppScreen() }
    }
}
```

#### 📄 Views.swift (새로 생성)
```swift
import SwiftUI
import TCAFlow
import ComposableArchitecture
import CoreLocation

// MARK: - 홈 화면
struct HomeView: View {
    @Bindable var store: StoreOf<Home>

    var body: some View {
        VStack(spacing: 24) {
            Text("🚀 TCAFlow").font(.largeTitle).fontWeight(.bold)
            Text("Hashable 제약 제거!").foregroundColor(.secondary)

            // 카운터
            VStack {
                Text("카운터: \(store.counter)").font(.title2)
                HStack {
                    Button("−") { store.send(.decrement) }.buttonStyle(.bordered)
                    Button("+") { store.send(.increment) }.buttonStyle(.bordered)
                }
            }
            .padding().background(Color(.systemGray6)).cornerRadius(12)

            // 네비게이션 버튼들
            VStack(spacing: 12) {
                NavButton(icon: "doc", title: "상세 정보", subtitle: "기본 push") {
                    store.send(.detailButtonTapped)
                }
                NavButton(icon: "person", title: "프로필", subtitle: "goTo() 사용") {
                    store.send(.profileButtonTapped)
                }
                NavButton(icon: "gear", title: "설정", subtitle: "일반 네비게이션") {
                    store.send(.settingsButtonTapped)
                }
                NavButton(icon: "map", title: "지도", subtitle: "CLLocationCoordinate2D!") {
                    store.send(.mapButtonTapped)
                }
            }
            Spacer()
        }.padding()
    }
}

// MARK: - 상세 화면
struct DetailView: View {
    @Bindable var store: StoreOf<Detail>
    let coordinator: StoreOf<AppCoordinator>

    var body: some View {
        VStack(spacing: 24) {
            Text("📄 상세 정보").font(.largeTitle)
            
            VStack {
                Text("ID: \(store.id)").font(.caption).foregroundColor(.secondary)
                if store.isLoading {
                    ProgressView("로딩 중...")
                } else {
                    Text(store.name).font(.title2)
                }
            }.padding().background(Color.blue.opacity(0.1)).cornerRadius(12)

            Button("데이터 로드") { store.send(.load) }.buttonStyle(.borderedProminent)
            
            NavButton(icon: "person", title: "프로필로 이동", subtitle: "Detail → Profile") {
                store.send(.profileButtonTapped)
            }

            Spacer()
            Button("← 뒤로 가기") { store.send(.backButtonTapped) }.buttonStyle(.bordered)
        }
        .padding().navigationTitle("상세").navigationBarBackButtonHidden()
    }
}

// MARK: - 프로필 화면
struct ProfileView: View {
    @Bindable var store: StoreOf<Profile>
    let coordinator: StoreOf<AppCoordinator>

    var body: some View {
        VStack(spacing: 24) {
            Text("👤 프로필").font(.largeTitle)

            VStack {
                if store.isEditing {
                    TextField("사용자명", text: $store.username.sending(\.updateUsername))
                    TextField("이메일", text: $store.email.sending(\.updateEmail))
                } else {
                    HStack { Text("사용자명:"); Spacer(); Text(store.username) }
                    HStack { Text("이메일:"); Spacer(); Text(store.email) }
                }
            }.padding().background(Color.green.opacity(0.1)).cornerRadius(12)

            Button(store.isEditing ? "저장" : "편집") {
                store.send(store.isEditing ? .saveButtonTapped : .editButtonTapped)
            }.buttonStyle(.borderedProminent)

            NavButton(icon: "gear", title: "설정으로", subtitle: "Profile → Settings") {
                store.send(.settingsButtonTapped)
            }

            Spacer()
            Button("← 뒤로 가기") { store.send(.backButtonTapped) }.buttonStyle(.bordered)
        }
        .padding().navigationTitle("프로필").navigationBarBackButtonHidden()
    }
}

// MARK: - 설정 화면
struct SettingsView: View {
    @Bindable var store: StoreOf<Settings>
    let coordinator: StoreOf<AppCoordinator>

    var body: some View {
        VStack(spacing: 24) {
            Text("⚙️ 설정").font(.largeTitle)

            VStack {
                HStack {
                    Text("다크 모드"); Spacer()
                    Toggle("", isOn: $store.isDarkMode.sending(\.toggleDarkMode))
                }
                HStack {
                    Text("알림"); Spacer()
                    Toggle("", isOn: $store.notificationsEnabled.sending(\.toggleNotifications))
                }
                HStack { Text("버전"); Spacer(); Text(store.version) }
            }.padding().background(Color.orange.opacity(0.1)).cornerRadius(12)

            Button("기본값으로 재설정") { store.send(.resetToDefaults) }.buttonStyle(.bordered)
            Spacer()
            Button("← 뒤로 가기") { store.send(.backButtonTapped) }.buttonStyle(.bordered)
        }
        .padding().navigationTitle("설정").navigationBarBackButtonHidden()
    }
}

// MARK: - 지도 화면 (🔥 CLLocationCoordinate2D!)
struct MapView: View {
    @Bindable var store: StoreOf<MapFeature>
    let coordinator: StoreOf<AppCoordinator>

    var body: some View {
        VStack(spacing: 20) {
            Text("🗺️ 지도").font(.largeTitle)

            VStack {
                Text("📍 \(store.title)").font(.headline)
                Text("위도: \(store.location.latitude, specifier: "%.6f")")
                Text("경도: \(store.location.longitude, specifier: "%.6f")")
                Text("줌: \(store.zoom, specifier: "%.2f")x")
            }.padding().background(Color.blue.opacity(0.1)).cornerRadius(12)

            HStack {
                Button("줌 아웃") { store.send(.zoomOut) }.buttonStyle(.bordered)
                Spacer()
                Button("줌 인") { store.send(.zoomIn) }.buttonStyle(.bordered)
            }

            VStack {
                Button("서울로 이동") {
                    store.send(.updateLocation(CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)))
                    store.send(.updateTitle("서울시청"))
                }.buttonStyle(.borderedProminent)

                Button("부산으로 이동") {
                    store.send(.updateLocation(CLLocationCoordinate2D(latitude: 35.1796, longitude: 129.0756)))
                    store.send(.updateTitle("부산시청"))
                }.buttonStyle(.borderedProminent)
            }

            Text("🔥 CLLocationCoordinate2D를\nHashable 없이 사용!")
                .font(.caption).multilineTextAlignment(.center).foregroundColor(.green)
                .padding().background(Color.green.opacity(0.1)).cornerRadius(8)

            Spacer()
            Button("← 뒤로 가기") { store.send(.backButtonTapped) }.buttonStyle(.bordered)
        }
        .padding().navigationTitle("지도").navigationBarBackButtonHidden()
    }
}

// MARK: - 헬퍼 컴포넌트
struct NavButton: View {
    let icon: String; let title: String; let subtitle: String; let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(.blue).frame(width: 24)
                VStack(alignment: .leading) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }.padding().background(Color(.systemGray6)).cornerRadius(12)
        }.buttonStyle(.plain)
    }
}

#Preview { HomeView(store: Store(initialState: Home.State()) { Home() }) }
```

## 🎯 5단계: 실행
- ⌘+R 눌러서 실행하세요!
- 콘솔에서 네비게이션 로그 확인하세요.

## ✨ 체험할 기능들
1. **카운터** - TCA 기본 상태 관리
2. **상세 → 프로필** - 일반 네비게이션  
3. **홈 → 프로필** - `goTo()` (있으면 그곳으로)
4. **지도** - CLLocationCoordinate2D (Hashable 제약 없음!)

---

**5분만에 TCAFlow의 모든 핵심 기능을 체험하세요!** 🚀