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
