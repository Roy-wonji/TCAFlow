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
        // 1. extension인지 확인
        guard let extensionDecl = declaration.as(ExtensionDeclSyntax.self) else {
            context.addDiagnostics(
                from: FlowCoordinatorError.notAnExtension,
                node: node
            )
            return []
        }

        // 2. @Reducer enum 찾기
        guard let screenEnum = findReducerEnum(in: extensionDecl) else {
            context.addDiagnostics(
                from: FlowCoordinatorError.noReducerEnum,
                node: node
            )
            return []
        }

        let screenName = screenEnum.name.trimmedDescription

        // 3. 첫번째 case 추출
        guard let firstCase = findFirstCase(in: screenEnum) else {
            context.addDiagnostics(
                from: FlowCoordinatorError.noEnumCases,
                node: node
            )
            return []
        }

        // 4. navigation 파라미터 읽기
        let navigation = extractNavigationParam(from: node)

        // 5. 이미 존재하는 멤버 확인
        let existingMembers = extensionDecl.memberBlock.members.map {
            $0.decl.trimmedDescription
        }.joined()

        let hasState = existingMembers.contains("struct State")
        let hasAction = existingMembers.contains("enum Action")
        let hasBody = existingMembers.contains("var body")

        var results: [DeclSyntax] = []

        // 6. State 생성
        if !hasState {
            let stateDecl: DeclSyntax = """
                @ObservableState
                struct State: Equatable {
                    var routes: [Route<\(raw: screenName).State>]
                    init() {
                        self.routes = [.root(.\(raw: firstCase)(.init()), embedInNavigationView: \(raw: navigation))]
                    }
                }
                """
            results.append(stateDecl)
        }

        // 7. Action 생성
        if !hasAction {
            let actionDecl: DeclSyntax = """
                @CasePathable
                enum Action {
                    case router(IndexedRouterActionOf<\(raw: screenName)>)
                }
                """
            results.append(actionDecl)
        }

        // 8. body 생성 (항상 생성 - forEachRoute 자동 적용)
        // 사용자는 body 대신 routeReducer를 작성
        if !hasBody {
            let bodyDecl: DeclSyntax = """
                var body: some Reducer<State, Action> {
                    self.routeReducer
                        .forEachRoute(\\.routes, action: \\.router)
                }
                """
            results.append(bodyDecl)
        }

        return results
    }
}


// MARK: - Helpers

private func findReducerEnum(in extensionDecl: ExtensionDeclSyntax) -> EnumDeclSyntax? {
    for member in extensionDecl.memberBlock.members {
        guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { continue }
        let hasReducerAttr = enumDecl.attributes.contains { attr in
            guard let attribute = attr.as(AttributeSyntax.self) else { return false }
            return attribute.attributeName.trimmedDescription == "Reducer"
        }
        if hasReducerAttr {
            return enumDecl
        }
    }
    return nil
}

private func findFirstCase(in enumDecl: EnumDeclSyntax) -> String? {
    for member in enumDecl.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        guard let firstElement = caseDecl.elements.first else { continue }
        return firstElement.name.trimmedDescription
    }
    return nil
}

private func extractNavigationParam(from node: AttributeSyntax) -> Bool {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        return true // default
    }
    for arg in arguments {
        if arg.label?.trimmedDescription == "navigation",
           let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self) {
            return boolLiteral.literal.text == "true"
        }
    }
    return true // default
}

// MARK: - Errors

enum FlowCoordinatorError: String, Error, DiagnosticMessage {
    case notAnExtension
    case noReducerEnum
    case noEnumCases

    var message: String {
        switch self {
        case .notAnExtension:
            return "@FlowCoordinator can only be applied to an extension"
        case .noReducerEnum:
            return "@FlowCoordinator requires a @Reducer enum inside the extension"
        case .noEnumCases:
            return "Screen enum must have at least one case"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "TCAFlowMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}
