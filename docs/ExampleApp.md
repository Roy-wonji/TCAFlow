# Example App

example iOS 앱은 `Example/TCAFlowExamples` 아래에 있습니다.

## 실행

Tuist project 파일이 이미 생성되어 있으면 Xcode에서 아래 project를 열면 됩니다.

```text
Example/TCAFlowExamples/TCAFlowExamples.xcodeproj
```

터미널 빌드는 다음 명령으로 확인할 수 있습니다.

```sh
xcodebuild \
  -project Example/TCAFlowExamples/TCAFlowExamples.xcodeproj \
  -scheme TCAFlowExamples \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/TCAFlowExamplesDerivedData \
  build
```

Tuist project를 다시 생성해야 하면 example 디렉터리에서 실행합니다.

```sh
cd Example/TCAFlowExamples
tuist generate
```

## 구성

example 앱의 coordinator는 `AppCoordinator`입니다.

```swift
@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case single(SingleViewFeature)
    case counter(CounterFeature)
    case summary(SummaryFeature)
    case settings(SettingsFeature)
  }
}
```

현재 example은 다음 흐름을 보여줍니다.

- `Home` -> `SingleView`: 화면 하나만 push하고 pop하는 흐름
- `Home` -> `Counter` -> `Summary`: 여러 화면을 stack에 쌓는 흐름
- `Summary` -> `Settings`: 특정 화면으로 이동하는 흐름
- `Counter`/`Summary` -> root: `popToRoot` 흐름

## View 연결

`AppCoordinatorView`는 coordinator store를 `RouteStack` store로 scope해서 `TCARouter`에 넘깁니다.

```swift
TCARouter(
  self.store.scope(state: \.routes, action: \.route)
) { screen in
  switch screen.case {
  case .home(let store):
    HomeView(store: store)

  case .single(let store):
    SingleView(store: store)

  case .counter(let store):
    CounterView(store: store)

  case .summary(let store):
    SummaryView(store: store)

  case .settings(let store):
    SettingsView(store: store)
  }
}
```

## iOS 16과 iOS 17

`TCARouter`는 library target에서 iOS 16을 지원하므로 SwiftUI `@Bindable`을 내부에서 사용하지 않습니다.

example app은 iOS 17 target이므로 각 feature view에서 `@SwiftUI.Bindable var store`를 사용합니다.

```swift
struct SummaryView: View {
  @SwiftUI.Bindable var store: StoreOf<SummaryFeature>
}
```
