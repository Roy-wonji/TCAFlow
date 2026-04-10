import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - FlowCoordinatorMacro

public struct FlowCoordinatorMacro {}

// MARK: - MemberMacro

extension FlowCoordinatorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // struct 또는 extension 모두 지원
        guard let screenEnum = findReducerEnum(in: declaration) else {
            context.addDiagnostics(from: FlowCoordinatorError.noReducerEnum, node: node)
            return []
        }

        let screenName = screenEnum.name.trimmedDescription

        guard let firstCase = findFirstCase(in: screenEnum) else {
            context.addDiagnostics(from: FlowCoordinatorError.noEnumCases, node: node)
            return []
        }

        let navigation = extractNavigationParam(from: node)

        // 이미 존재하는 멤버 확인
        let existingMembers = declaration.memberBlock.members.map {
            $0.decl.trimmedDescription
        }.joined()

        let hasState = existingMembers.contains("struct State")
        let hasAction = existingMembers.contains("enum Action")
        let hasBody = existingMembers.contains("var body")

        var results: [DeclSyntax] = []

        if !hasState {
            results.append("""
                @ObservableState
                struct State: Equatable {
                    var routes: [Route<\(raw: screenName).State>]
                    init() {
                        self.routes = [.root(.\(raw: firstCase)(.init()), embedInNavigationView: \(raw: navigation))]
                    }
                }
                """)
        }

        if !hasAction {
            results.append("""
                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<\(raw: screenName)>)
                }
                """)
        }

        if !hasBody {
            results.append("""
                var body: some Reducer<State, Action> {
                    Reduce { state, action in
                        return self.handleRoute(state: &state, action: action)
                    }
                    .forEachRoute(\\.routes, action: \\.router)
                }
                """)
        }

        return results
    }
}

// MARK: - ExtensionMacro (struct에 붙었을 때 Reducer conformance + Equatable 추가)

extension FlowCoordinatorMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // struct에 붙었을 때만 Reducer conformance + Equatable 생성
        guard declaration.is(StructDeclSyntax.self) else { return [] }

        let typeName = type.trimmedDescription

        guard let screenEnum = findReducerEnum(in: declaration) else { return [] }
        let screenName = screenEnum.name.trimmedDescription

        var extensions: [ExtensionDeclSyntax] = []

        // Reducer conformance
        let reducerExt: DeclSyntax = "extension \(raw: typeName): Reducer {}"
        if let ext = reducerExt.as(ExtensionDeclSyntax.self) {
            extensions.append(ext)
        }

        return extensions
    }
}

// MARK: - Helpers

private func findReducerEnum(in declaration: some DeclGroupSyntax) -> EnumDeclSyntax? {
    for member in declaration.memberBlock.members {
        guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { continue }
        let hasReducerAttr = enumDecl.attributes.contains { attr in
            guard let attribute = attr.as(AttributeSyntax.self) else { return false }
            return attribute.attributeName.trimmedDescription == "Reducer"
        }
        if hasReducerAttr { return enumDecl }
    }
    return nil
}

private func findFirstCase(in enumDecl: EnumDeclSyntax) -> String? {
    for member in enumDecl.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
              let firstElement = caseDecl.elements.first else { continue }
        return firstElement.name.trimmedDescription
    }
    return nil
}

private func extractNavigationParam(from node: AttributeSyntax) -> Bool {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return true }
    for arg in arguments {
        if arg.label?.trimmedDescription == "navigation",
           let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self) {
            return boolLiteral.literal.text == "true"
        }
    }
    return true
}

// MARK: - Errors

enum FlowCoordinatorError: String, Error, DiagnosticMessage {
    case noReducerEnum
    case noEnumCases

    var message: String {
        switch self {
        case .noReducerEnum:
            return "@FlowCoordinator requires a @Reducer enum inside"
        case .noEnumCases:
            return "Screen enum must have at least one case"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "TCAFlowMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}
