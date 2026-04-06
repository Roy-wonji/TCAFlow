import Foundation

/// @FlowCoordinator 매크로 정의
@attached(member, names: named(State), named(Action), named(body))
public macro FlowCoordinator() = #externalMacro(module: "TCAFlowMacros", type: "FlowCoordinatorMacro")

/// @ForEachRoute 매크로 정의
@attached(peer)
public macro ForEachRoute() = #externalMacro(module: "TCAFlowMacros", type: "ForEachRouteMacro")