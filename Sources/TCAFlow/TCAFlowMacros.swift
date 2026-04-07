import Foundation

/// Generates TCAFlow coordinator boilerplate from a nested `Screen` enum.
///
/// Use this macro when you want to write only the route cases and keep the generated
/// `@Reducer` screen enum, `State`, and `Action` out of the example code:
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
@attached(member, names: named(AppScreen), named(State), named(Action))
public macro FlowCoordinator() = #externalMacro(module: "TCAFlowMacros", type: "FlowCoordinatorMacro")

/// @ForEachRoute 매크로 정의
@attached(peer)
public macro ForEachRoute() = #externalMacro(module: "TCAFlowMacros", type: "ForEachRouteMacro")
