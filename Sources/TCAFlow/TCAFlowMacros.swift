import Foundation

/// Generates TCAFlow coordinator boilerplate from a nested `Screen` enum.
///
/// Use this macro when you want to write only the route cases and keep the generated
/// screen enum, `State`, and `Action` out of the example code.
///
/// The generated screen enum name is derived from the coordinator type name:
///
/// - `AppCoordinator` -> `AppScreen`
/// - `HomeCoordinator` -> `HomeScreen`
/// - `ProfileFlow` -> `ProfileFlowScreen`
///
/// ```swift
/// @FlowCoordinator
/// struct AppCoordinator {
///   enum Screen {
///     case home(HomeFeature)
///     case detail(DetailFeature)
///   }
/// }
/// ```
@attached(member, names: arbitrary, named(State), named(Action))
public macro FlowCoordinator(navigation: Bool = true) = #externalMacro(module: "TCAFlowMacros", type: "FlowCoordinatorMacro")

/// @ForEachRoute 매크로 정의
@attached(peer)
public macro ForEachRoute() = #externalMacro(module: "TCAFlowMacros", type: "ForEachRouteMacro")

/// Extension에서 nested coordinator 처리를 위한 매크로
@attached(member, names: arbitrary)
public macro NestedCoordinatorExtension() = #externalMacro(module: "TCAFlowMacros", type: "NestedCoordinatorExtensionMacro")

/// RouteStack extension 메서드들을 자동 생성하는 매크로
@attached(member, names: arbitrary)
public macro RouteStackExtensions() = #externalMacro(module: "TCAFlowMacros", type: "RouteStackExtensionsMacro")

/// View transition extension 메서드들을 자동 생성하는 매크로
@attached(member, names: arbitrary)
public macro ViewTransitions() = #externalMacro(module: "TCAFlowMacros", type: "ViewTransitionsMacro")
