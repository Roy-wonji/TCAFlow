import ComposableArchitecture
import SwiftUI
import TCAFlow

// MARK: - DeepLink Handler

struct DemoDeepLinkHandler: DeepLinkHandler {
  typealias Screen = DemoCoordinator.DemoScreen.State

  func routes(for url: URL) -> [Route<Screen>]? {
    guard let host = url.host else { return nil }
    let params = url.deepLinkParameters

    switch host {
    case "detail":
      return [
        .root(.home(.init()), embedInNavigationView: true),
        .push(.detail(.init(
          title: params["title"] ?? "Detail",
          message: params["message"] ?? ""
        )))
      ]
    case "settings":
      return [
        .root(.home(.init()), embedInNavigationView: true),
        .push(.settings(.init()))
      ]
    default:
      return nil
    }
  }
}

@FlowCoordinator(screen: "DemoScreen", navigation: true)
struct DemoCoordinator {}

extension DemoCoordinator {
  @Reducer
  enum DemoScreen {
    case home(HomeFeature)
    case flow(FlowFeature)
    case detail(DetailFeature)
    case settings(SettingsFeature)
    case nested(NestedCoordinator)
  }
}

extension DemoCoordinator {
  func handleRoute(state: inout State, action: Action) -> Effect<Action> {
    switch action {
      case .router(.routeAction(_, .home(.startFlow))):
        state.routes.push(.flow(.init()))
        return .none

      case .router(.routeAction(_, .home(.pushOneView))):
        state.routes.push(.detail(.init(title: "Push된 화면", message: "간단한 Push 테스트입니다")))
        return .none

      case .router(.routeAction(_, .home(.openNestedCoordinator))):
        state.routes.push(.nested(.init(routes: [.root(.step1(.init()), embedInNavigationView: true)])))
        return .none

      case .router(.routeAction(_, .home(.jumpToSettings))):
        state.routes.push(.settings(.init()))
        return .none

      // 1.1.0: Half Sheet
      case .router(.routeAction(_, .home(.openHalfSheet))):
        state.routes.presentSheet(.settings(.init()), configuration: .halfAndFull)
        return .none

      // 1.1.0: DeepLink
      case .router(.routeAction(_, .home(.openDeepLink))):
        state.routes.handleDeepLink(
          URL(string: "app://detail?title=DeepLink&message=딥링크로 이동했습니다")!,
          handler: DemoDeepLinkHandler()
        )
        return .none

      case .router(.routeAction(_, .flow(.nextStep))):
        state.routes.push(.detail(.init(title: "Flow Step 2", message: "다음 단계로 이동했습니다")))
        return .none

      case .router(.routeAction(_, .flow(.goToDetailSmartly))):
        state.routes.goTo(.detail(.init(title: "From Flow", message: "Flow에서 goTo로 이동했습니다")))
        return .none

      case .router(.routeAction(_, .flow(.goToHomeDirectly))):
        state.routes.goTo(\.home)
        return .none

      case .router(.routeAction(_, .detail(.goBack))):
        state.routes.goBack()
        return .none

      case .router(.routeAction(_, .detail(.goToRoot))):
        state.routes.goBackToRoot()
        return .none

      case .router(.routeAction(_, .detail(.goToHomeDirectly))):
        state.routes.goTo(\.home)
        return .none

      case .router(.routeAction(_, .detail(.goToSettingsSmartly))):
        state.routes.goTo(.settings(.init()))
        return .none

      case .router(.routeAction(_, .settings(.goBack))):
        state.routes.goBack()
        return .none

      case .router(.routeAction(_, .settings(.goToHomeDirectly))):
        state.routes.goTo(\.home)
        return .none

      case .router(.routeAction(_, .settings(.goToFlowSmartly))):
        state.routes.goTo(.flow(.init()))
        return .none

      case .router(.routeAction(_, .nested(.backToMain))):
        state.routes.goBackToRoot()
        return .none

      case .router(.routeAction(_, .home(.goToSettingsSmartly))):
        state.routes.goTo(.settings(.init()))
        return .none

      case .router(.routeAction(_, .home(.goToFlowOrCreate))):
        state.routes.goTo(.flow(.init()))
        return .none

      default:
        return .none
    }
  }
}
