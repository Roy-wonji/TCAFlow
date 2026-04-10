import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TCAFlowMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        FlowCoordinatorMacro.self,
    ]
}
