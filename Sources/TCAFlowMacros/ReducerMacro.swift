import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @Reducer macro similar to TCACoordinators but without hashable requirement
public struct ReducerMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@Reducer can only be applied to enums")
        }

        let enumName = enumDecl.name.text
        let accessModifier = Self.accessModifier(for: declaration)

        // Extract cases from the enum
        var cases: [(name: String, associatedType: String?)] = []
        for member in enumDecl.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    let associatedType = element.parameterClause?.parameters.first?.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    cases.append((name: caseName, associatedType: associatedType))
                }
            }
        }

        guard !cases.isEmpty else {
            throw MacroExpansionErrorMessage("@Reducer enum must have at least one case")
        }

        var members: [DeclSyntax] = []

        // Generate State enum
        let stateCases = cases.compactMap { caseInfo in
            guard let associatedType = caseInfo.associatedType else { return nil }
            return "case \(caseInfo.name)(\(associatedType).State)"
        }.joined(separator: "\n      ")

        if !stateCases.isEmpty {
            let stateEnum: DeclSyntax = """
            @CasePathable
            @dynamicMemberLookup
            @ComposableArchitecture.ObservableState
            \(raw: accessModifier)enum State: ComposableArchitecture.CaseReducerState {
              \(raw: accessModifier)typealias StateReducer = \(raw: enumName)
              \(raw: stateCases)
            }
            """
            members.append(stateEnum)
        }

        // Generate Action enum
        let actionCases = cases.compactMap { caseInfo in
            guard let associatedType = caseInfo.associatedType else { return nil }
            return "case \(caseInfo.name)(\(associatedType).Action)"
        }.joined(separator: "\n      ")

        if !actionCases.isEmpty {
            let actionEnum: DeclSyntax = """
            @CasePathable
            \(raw: accessModifier)enum Action {
              \(raw: actionCases)
            }
            """
            members.append(actionEnum)
        }

        // Generate body with case reducers
        let caseReducers = cases.compactMap { caseInfo in
            guard let associatedType = caseInfo.associatedType else { return nil }
            return """
            .ifCaseLet(\\Self.State.\(caseInfo.name), action: \\Self.Action.\(caseInfo.name)) {
              \(associatedType)()
            }
            """
        }.joined(separator: "\n        ")

        if !caseReducers.isEmpty {
            let bodyComputed: DeclSyntax = """
            \(raw: accessModifier)static var body: some ComposableArchitecture.Reducer<Self.State, Self.Action> {
              ComposableArchitecture.EmptyReducer<Self.State, Self.Action>()
              \(raw: caseReducers)
            }
            """
            members.append(bodyComputed)
        }

        return members
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }

        let enumName = enumDecl.name.text

        // Generate CaseReducer and Reducer conformance
        let reducerConformanceExtension = try ExtensionDeclSyntax("extension \(raw: enumName): ComposableArchitecture.CaseReducer, ComposableArchitecture.Reducer") {
            // Empty extension body - conformance is handled by the generated members
        }

        return [reducerConformanceExtension]
    }

    private static func accessModifier(for declaration: some DeclGroupSyntax) -> String {
        let modifiers: DeclModifierListSyntax

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            modifiers = enumDecl.modifiers
        } else {
            return ""
        }

        for modifier in modifiers {
            let name = modifier.name.text
            if name == "public" || name == "open" || name == "package" {
                return "\(name) "
            }
        }

        return ""
    }
}

/// Convenience macro for Screen reducers - same as @Reducer but with clearer name
public struct ScreenReducerMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try ReducerMacro.expansion(of: node, providingMembersOf: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return try ReducerMacro.expansion(of: node, attachedTo: declaration, providingExtensionsOf: type, conformingTo: protocols, in: context)
    }
}