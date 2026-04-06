//
//  Features.swift
//  TCAFlowExamples
//
//  Created by Wonji Suh  on 4/6/26.
//

import Foundation
import SwiftUI
import ComposableArchitecture

// MARK: - Home Feature
@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        var title = "홈"
        var message = "TCAFlow 예제 앱입니다"
    }

    enum Action {
        case exploreTapped
        case profileTapped
        case settingsTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

struct HomeView: View {
    let store: StoreOf<Home>

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 30) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text(store.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(store.message)
                .font(.body)
                .foregroundColor(.secondary)

            VStack(spacing: 20) {
                Button("🔍 탐색하기") {
                    store.send(.exploreTapped)
                }
                .buttonStyle(.borderedProminent)

                Button("👤 프로필") {
                    store.send(.profileTapped)
                }
                .buttonStyle(.bordered)

                Button("⚙️ 설정") {
                    store.send(.settingsTapped)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("홈")
    }
}

// MARK: - Explore Feature
@Reducer
struct Explore {
    @ObservableState
    struct State: Equatable {
        var items = ["아이템 1", "아이템 2", "아이템 3", "아이템 4", "아이템 5"]
        var selectedItem: String?
    }

    enum Action {
        case backTapped
        case goToHomeTapped
        case itemTapped(String)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .itemTapped(let item):
                state.selectedItem = item
                return .none

            case .backTapped, .goToHomeTapped:
                return .none
            }
        }
    }
}

struct ExploreView: View {
    let store: StoreOf<Explore>

    var body: some View {
        @Bindable var store = store

        VStack {
            if let selectedItem = store.selectedItem {
                Text("선택된 아이템: \(selectedItem)")
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            List {
                ForEach(store.items, id: \.self) { item in
                    Button(item) {
                        store.send(.itemTapped(item))
                    }
                    .foregroundColor(.primary)
                }
            }

            HStack {
                Button("← 뒤로") {
                    store.send(.backTapped)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("🏠 홈으로") {
                    store.send(.goToHomeTapped)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("탐색")
    }
}

// MARK: - Profile Feature
@Reducer
struct Profile {
    @ObservableState
    struct State: Equatable {
        var name = "사용자"
        var email = "user@example.com"
        var bio = "TCAFlow를 사용해서 네비게이션을 구현하는 개발자입니다."
    }

    enum Action {
        case backTapped
        case settingsTapped
        case editProfileTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

struct ProfileView: View {
    let store: StoreOf<Profile>

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 30) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }

            VStack(spacing: 10) {
                Text(store.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text(store.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(store.bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 15) {
                Button("✏️ 프로필 편집") {
                    store.send(.editProfileTapped)
                }
                .buttonStyle(.borderedProminent)

                Button("⚙️ 설정") {
                    store.send(.settingsTapped)
                }
                .buttonStyle(.bordered)

                Button("← 뒤로") {
                    store.send(.backTapped)
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("프로필")
    }
}

// MARK: - Settings Feature
@Reducer
struct Settings {
    @ObservableState
    struct State: Equatable {
        var notificationsEnabled = true
        var darkModeEnabled = false
        var language = "한국어"
    }

    enum Action {
        case backTapped
        case goToRootTapped
        case notificationToggled
        case darkModeToggled
        case languageChanged(String)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .notificationToggled:
                state.notificationsEnabled.toggle()
                return .none

            case .darkModeToggled:
                state.darkModeEnabled.toggle()
                return .none

            case .languageChanged(let language):
                state.language = language
                return .none

            case .backTapped, .goToRootTapped:
                return .none
            }
        }
    }
}

struct SettingsView: View {
    let store: StoreOf<Settings>

    var body: some View {
        @Bindable var store = store

        VStack {
            Form {
                Section("알림") {
                    Toggle("푸시 알림", isOn: $store.notificationsEnabled.sending(\.notificationToggled))
                }

                Section("표시") {
                    Toggle("다크 모드", isOn: $store.darkModeEnabled.sending(\.darkModeToggled))
                }

                Section("언어") {
                    Picker("언어 선택", selection: $store.language.sending(\.languageChanged)) {
                        Text("한국어").tag("한국어")
                        Text("English").tag("English")
                        Text("日本語").tag("日本語")
                    }
                }
            }

            HStack(spacing: 20) {
                Button("← 뒤로") {
                    store.send(.backTapped)
                }
                .buttonStyle(.bordered)

                Button("🏠 홈으로") {
                    store.send(.goToRootTapped)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("설정")
    }
}