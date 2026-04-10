import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct FlowCoordinatorMacro {}

// MARK: - MemberMacro

extension FlowCoordinatorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let params = extractParams(from: node)

        // Screen enum을 매크로 파라미터 또는 멤버에서 찾기
        let screenName: String
        let firstCase: String

        if let paramScreen = params.screen {
            // 파라미터로 전달된 경우 (struct에 붙었을 때)
            screenName = paramScreen
            // firstCase는 알 수 없으므로 빈 문자열 → State init에서 처리 안 함
            firstCase = ""
        } else if let enumDecl = findReducerEnum(in: declaration) {
            // 멤버에서 찾은 경우 (extension에 붙었을 때)
            screenName = enumDecl.name.trimmedDescription
            firstCase = findFirstCase(in: enumDecl) ?? ""
        } else {
            context.addDiagnostics(from: FlowCoordinatorError.noScreenInfo, node: node)
            return []
        }

        let navigation = params.navigation

        // 이미 존재하는 멤버 확인
        let existingMembers = declaration.memberBlock.members.map {
            $0.decl.trimmedDescription
        }.joined()

        let hasState = existingMembers.contains("struct State")
        let hasAction = existingMembers.contains("enum Action")
        let hasBody = existingMembers.contains("var body")

        var results: [DeclSyntax] = []

        if !hasState {
            if firstCase.isEmpty {
                // Screen enum이 extension에 있어서 firstCase를 모르는 경우
                // → 사용자가 init을 직접 작성해야 함
                results.append("""
                    @ObservableState
                    struct State: Equatable {
                        var routes: [Route<\(raw: screenName).State>]
                    }
                    """)
            } else {
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

// MARK: - ExtensionMacro

extension FlowCoordinatorMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else { return [] }
        let typeName = type.trimmedDescription

        let params = extractParams(from: node)
        let screenName = params.screen ?? ""

        var extensions: [ExtensionDeclSyntax] = []

        // Reducer conformance
        let reducerExt: DeclSyntax = "extension \(raw: typeName): Reducer {}"
        if let ext = reducerExt.as(ExtensionDeclSyntax.self) {
            extensions.append(ext)
        }

        // Screen.State: Equatable (screen 파라미터가 있을 때)
        if !screenName.isEmpty {
            let equatableExt: DeclSyntax = "extension \(raw: typeName).\(raw: screenName).State: Equatable {}"
            if let ext = equatableExt.as(ExtensionDeclSyntax.self) {
                extensions.append(ext)
            }
        }

        return extensions
    }
}

// MARK: - Param Extraction

private struct MacroParams {
    let screen: String?
    let navigation: Bool
}

private func extractParams(from node: AttributeSyntax) -> MacroParams {
    var screen: String? = nil
    var navigation = true

    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        return MacroParams(screen: nil, navigation: true)
    }

    for arg in arguments {
        if arg.label?.trimmedDescription == "screen",
           let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
           let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
            screen = segment.content.text
        }
        if arg.label?.trimmedDescription == "navigation",
           let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self) {
            navigation = boolLiteral.literal.text == "true"
        }
    }

    return MacroParams(screen: screen, navigation: navigation)
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

// MARK: - Errors

enum FlowCoordinatorError: String, Error, DiagnosticMessage {
    case noScreenInfo

    var message: String {
        switch self {
        case .noScreenInfo:
            return "@FlowCoordinator requires either a @Reducer enum inside, or a 'screen' parameter"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "TCAFlowMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}
