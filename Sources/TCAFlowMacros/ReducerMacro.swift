import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @Reducer macro that matches TCACoordinators behavior for Screen enums
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

        // Parse macro arguments
        let stateOptions = try Self.parseStateOptions(from: node)

        // Extract cases from the enum
        var cases: [(name: String, associatedType: String)] = []
        for member in enumDecl.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    guard let parameterClause = element.parameterClause,
                          let firstParam = parameterClause.parameters.first else {
                        throw MacroExpansionErrorMessage("All cases in @Reducer enum must have associated types")
                    }
                    let associatedType = firstParam.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    cases.append((name: caseName, associatedType: associatedType))
                }
            }
        }

        guard !cases.isEmpty else {
            throw MacroExpansionErrorMessage("@Reducer enum must have at least one case")
        }

        var members: [DeclSyntax] = []

        // Generate State enum
        let stateCases = cases.map { caseInfo in
            "case \(caseInfo.name)(\(caseInfo.associatedType).State)"
        }.joined(separator: "\n      ")

        // Determine state conformances based on options
        var stateConformances = ["ComposableArchitecture.CaseReducerState"]
        if stateOptions.contains("equatable") {
            stateConformances.append("Swift.Equatable")
        }
        let stateConformanceList = stateConformances.joined(separator: ", ")

        let stateEnum: DeclSyntax = """
        @CasePaths.CasePathable
        @dynamicMemberLookup
        @ComposableArchitecture.ObservableState
        \(raw: accessModifier)enum State: \(raw: stateConformanceList) {
          \(raw: accessModifier)typealias StateReducer = \(raw: enumName)
          \(raw: stateCases)
        }
        """
        members.append(stateEnum)

        // Generate Action enum
        let actionCases = cases.map { caseInfo in
            "case \(caseInfo.name)(\(caseInfo.associatedType).Action)"
        }.joined(separator: "\n      ")

        let actionEnum: DeclSyntax = """
        @CasePaths.CasePathable
        \(raw: accessModifier)enum Action {
          \(raw: actionCases)
        }
        """
        members.append(actionEnum)

        // Generate body with case reducers
        let caseReducers = cases.map { caseInfo in
            """
            .ifCaseLet(\\Self.State.\(caseInfo.name), action: \\Self.Action.\(caseInfo.name)) {
              \(caseInfo.associatedType)()
            }
            """
        }.joined(separator: "\n        ")

        let bodyComputed: DeclSyntax = """
        \(raw: accessModifier)static var body: some ComposableArchitecture.Reducer<Self.State, Self.Action> {
          ComposableArchitecture.EmptyReducer<Self.State, Self.Action>()
          \(raw: caseReducers)
        }
        """
        members.append(bodyComputed)

        // Generate CaseScope for TCACoordinators-style pattern matching
        let caseScopeMembers = cases.map { caseInfo in
            "case \(caseInfo.name)(ComposableArchitecture.StoreOf<\(caseInfo.associatedType)>)"
        }.joined(separator: "\n      ")

        let caseScopeProperties = cases.map { caseInfo in
            """
            var \(caseInfo.name): CasePaths.AnyCasePath<CaseScope, ComposableArchitecture.StoreOf<\(caseInfo.associatedType)>> {
              CasePaths.AnyCasePath(
                embed: { @Sendable in CaseScope.\(caseInfo.name)($0) },
                extract: { guard case let .\(caseInfo.name)(store) = $0 else { return nil }; return store }
              )
            }
            """
        }.joined(separator: "\n\n        ")

        let storeScopes = cases.map { caseInfo in
            """
            case .\(caseInfo.name):
              return .\(caseInfo.name)(store.scope(state: \\.\(caseInfo.name), action: \\.\(caseInfo.name)))
            """
        }.joined(separator: "\n          ")

        let caseScopeEnum: DeclSyntax = """
        @dynamicMemberLookup
        \(raw: accessModifier)enum CaseScope: ComposableArchitecture._CaseScopeProtocol, CasePaths.CasePathable {
          \(raw: caseScopeMembers)

          \(raw: accessModifier)struct AllCasePaths {
            \(raw: caseScopeProperties)
          }

          \(raw: accessModifier)static var allCasePaths: AllCasePaths { AllCasePaths() }
        }

        @preconcurrency
        @MainActor
        \(raw: accessModifier)static func scope(_ store: ComposableArchitecture.Store<Self.State, Self.Action>) -> CaseScope {
          switch store.state {
          \(raw: storeScopes)
          }
        }
        """
        members.append(caseScopeEnum)

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

        // Generate CaseReducer and Reducer conformances
        let reducerConformanceExtension = try ExtensionDeclSyntax("extension \(raw: enumName): ComposableArchitecture.CaseReducer, ComposableArchitecture.Reducer") {
            // Empty body - conformance is provided by generated members
        }

        return [reducerConformanceExtension]
    }

    // Parse macro arguments like @Reducer(state: .equatable)
    private static func parseStateOptions(from node: AttributeSyntax) throws -> Set<String> {
        var options: Set<String> = []

        guard case let .argumentList(arguments) = node.arguments else {
            return options
        }

        for argument in arguments {
            if let label = argument.label?.text, label == "state" {
                let expression = argument.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if expression == ".equatable" {
                    options.insert("equatable")
                }
            }
        }

        return options
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