# FlowCoordinator Macro

`@FlowCoordinator`는 coordinator feature 안의 nested `Screen` enum을 읽어 TCA routing boilerplate를 생성합니다.

생성되는 screen enum 이름은 coordinator 이름에서 `Coordinator` suffix를 제거하고 `Screen`을 붙인 형태입니다.

- `AppCoordinator` -> `AppScreen`
- `HomeCoordinator` -> `HomeScreen`
- `ProfileFlow` -> `ProfileFlowScreen`

## 입력 코드

작성자는 화면 목록만 선언합니다.

```swift
@FlowCoordinator(navigation: true)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
    case settings(SettingsFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .route(.routeAction(_, .home(.detailButtonTapped)))):
        state.routes.push(.detail(DetailFeature.State()))
        return .none

      case .route:
        return .none
      }
    }
  }
}
```

## 생성되는 멤버

macro는 coordinator 안에 다음 멤버를 생성합니다.

- `<CoordinatorName>Screen`: `CaseReducer`/`Reducer` screen reducer enum
- `<CoordinatorName>Screen.State`: 각 화면 state를 담는 enum
- `<CoordinatorName>Screen.Action`: 각 화면 action을 담는 enum
- `<CoordinatorName>Screen.CaseScope`: `TCARouter` view builder에서 사용하는 screen store enum
- `State`: `RouteStack<<CoordinatorName>Screen.State>`를 가진 coordinator state
- `Action`: `case route(FlowActionOf<<CoordinatorName>Screen>)`를 가진 coordinator action

개념적으로는 아래 코드가 생성됩니다.

```swift
enum AppScreen: CaseReducer, Reducer {
  case home(HomeFeature)
  case detail(DetailFeature)

  @ObservableState
  enum State {
    case home(HomeFeature.State)
    case detail(DetailFeature.State)
  }

  enum Action {
    case home(HomeFeature.Action)
    case detail(DetailFeature.Action)
  }
}

@ObservableState
struct State: Equatable {
  var routes = RouteStack<AppScreen.State>([
    Route.root(.home(HomeFeature.State()), embedInNavigationView: true)
  ])
}

enum Action {
  case route(FlowActionOf<AppScreen>)
}
```

실제 생성 코드는 TCA의 case reducer, case path, observation 요구사항에 맞춰 더 많은 protocol conformance를 포함합니다.

`HomeCoordinator`라면 위 예제의 `AppScreen` 자리에 `HomeScreen`이 생성됩니다.

## 규칙

`@FlowCoordinator`는 `struct`에만 붙일 수 있습니다.

```swift
@FlowCoordinator
struct AppCoordinator { ... }
```

`Screen` enum이 반드시 필요합니다.

```swift
enum Screen {
  case home(HomeFeature)
}
```

각 `Screen` case는 feature reducer 타입을 associated value로 가져야 합니다.

```swift
case home(HomeFeature)
case detail(DetailFeature)
```

첫 번째 `Screen` case가 root route가 됩니다.

```swift
enum Screen {
  case home(HomeFeature)      // root
  case detail(DetailFeature)
}
```

macro가 생성하는 root route는 기본적으로 `embedInNavigationView: true`입니다. `@FlowCoordinator(navigation: false)`를 쓰면 root route가 `NavigationStack` 없이 렌더링됩니다.

```swift
@FlowCoordinator(navigation: false)
@Reducer
struct AppCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case detail(DetailFeature)
  }
}
```

직접 coordinator state를 작성하는 경우에는 다음처럼 `false`를 선택할 수 있습니다.

```swift
var routes: RouteStack<AppScreen.State> = [
  .root(.home(HomeFeature.State()), embedInNavigationView: false)
]
```

## Nested Coordinator

다른 coordinator를 screen case로 넣을 수 있습니다.

```swift
@FlowCoordinator(navigation: true)
@Reducer
struct HomeCoordinator: Sendable {
  enum Screen {
    case home(HomeFeature)
    case profile(ProfileCoordinator)
  }
}
```

parent reducer에서는 generated screen state를 바로 push할 수 있습니다.

```swift
state.routes.push(.profile(.init()))
```

child coordinator가 parent stack 안에서 이어서 동작해야 하면 child를 `navigation: false`로 두는 방식이 가장 단순합니다.

```swift
@FlowCoordinator(navigation: false)
@Reducer
struct ProfileCoordinator: Sendable {
  enum Screen {
    case profileHome(ProfileHomeFeature)
    case profileDetail(ProfileDetailFeature)
  }
}
```

child가 독립적인 `NavigationStack`을 가져야 하면 `navigation: true`도 그대로 사용할 수 있습니다. example 앱에는 `@FlowCoordinator(navigation: true)`인 nested `ProfileCoordinator` 예제가 포함되어 있습니다.

## Action 처리 패턴

화면 action은 `.route(.element(.element(id, screenAction)))` 형태로 들어옵니다.

```swift
case .route(.routeAction(let id, let screenAction)):
  switch screenAction {
  case .counter(.summaryButtonTapped):
    if let route = state.routes.routes[id: id],
       case .counter(let counterState) = route.state {
      state.routes.push(
        .summary(
          SummaryFeature.State(
            sessionName: counterState.session.name,
            finalCount: counterState.count
          )
        )
      )
    }

  case .summary(.restartButtonTapped):
    state.routes.popToRoot()
  }
  return .none
```

binding action처럼 child state를 직접 갱신해야 하는 경우에는 route id로 해당 route를 찾아 enum case를 갱신합니다.

```swift
case .settings(.binding(let bindingAction)):
  if let isEnabled = BindingAction<SettingsFeature.State>.allCasePaths.isNotificationsEnabled
    .extract(from: bindingAction),
    case .settings(var childState) = state.routes.routes[id: id]?
      .state {
    childState.isNotificationsEnabled = isEnabled
    state.routes.routes[id: id]?.state = .settings(childState)
  }
```

## Extension 매크로

TCAFlow는 extension에서 사용할 수 있는 매크로들도 제공합니다.

### @NestedCoordinatorExtension

nested coordinator를 처리하는 extension에 사용합니다. boilerplate reducer 함수를 자동 생성합니다.

```swift
@NestedCoordinatorExtension
private extension AppCoordinator {
  static func reduceProfileCoordinator(
    state: inout ProfileCoordinator.State,
    action: ProfileCoordinator.Action
  ) {
    // coordinator logic
  }
}
```

### @RouteStackExtensions

RouteStack 관련 extension 메서드들을 자동 생성합니다.

```swift
@RouteStackExtensions
extension RouteStack {
  // 추가 메서드들이 자동 생성됩니다
}
```

### @ViewTransitions

SwiftUI View transition extension 메서드들을 자동 생성합니다.

```swift
@ViewTransitions
extension View {
  // transition 관련 메서드들이 자동 생성됩니다
}
```

## Extension 사용 패턴

extension 매크로를 사용하면 다음과 같은 이점이 있습니다:

1. **boilerplate 코드 감소**: 반복적인 extension 코드를 자동 생성
2. **일관성 유지**: 매크로로 생성된 코드는 항상 일관된 패턴을 따름
3. **유지보수성**: 매크로 로직 변경으로 모든 extension을 일괄 업데이트 가능
