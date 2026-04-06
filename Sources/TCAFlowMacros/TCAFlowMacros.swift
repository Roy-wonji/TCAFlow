import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @FlowCoordinator 매크로 구현
public struct FlowCoordinatorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // struct 내부에서 Screen enum 찾기
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@FlowCoordinator는 struct에만 적용할 수 있습니다")
        }

        // Screen enum 찾기
        var screenEnum: EnumDeclSyntax?
        for member in structDecl.memberBlock.members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "Screen" {
                screenEnum = enumDecl
                break
            }
        }

        guard let screenEnum = screenEnum else {
            throw MacroExpansionErrorMessage("@FlowCoordinator는 'Screen' enum을 포함해야 합니다")
        }

        // Screen cases 추출
        var screenCases: [(name: String, type: String)] = []
        for member in screenEnum.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text

                    // 연관 값에서 타입 추출 (예: case home(Home) -> "Home")
                    if let parameterClause = element.parameterClause,
                       let firstParam = parameterClause.parameters.first {
                        let typeName = firstParam.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        screenCases.append((name: caseName, type: typeName))
                    }
                }
            }
        }

        // 생성할 코드들
        var members: [DeclSyntax] = []

        // 1. @ObservableState struct State 생성
        let stateStruct: DeclSyntax = """
        @ObservableState
        struct State: Equatable {
            var routes: IdentifiedArrayOf<Route<AppScreen.State>> = [
                Route(.home(.init()))
            ]
        }
        """
        members.append(stateStruct)

        // 2. Action enum 생성
        var actionCases = ["case router(FlowActionOf<AppScreen>)"]
        for screenCase in screenCases {
            actionCases.append("case \(screenCase.name)(\(screenCase.type).Action)")
        }

        let actionEnum: DeclSyntax = """
        enum Action {
            \(raw: actionCases.joined(separator: "\n    "))
        }
        """
        members.append(actionEnum)

        // 3. body reducer 생성 (기본 네비게이션 로직 포함)
        var switchCases: [String] = []

        for (index, screenCase) in screenCases.enumerated() {
            let caseName = screenCase.name
            let typeName = screenCase.type

            // 각 화면별 기본 네비게이션 로직
            let nextScreenIndex = (index + 1) % screenCases.count
            let nextScreen = screenCases[nextScreenIndex].name

            switchCases.append("""
            case .\(caseName)(.goNext):
                state.routes.push(.\(nextScreen)(.init()))
                return .none

            case .\(caseName)(.goBack):
                state.routes.pop()
                return .none
            """)
        }

        let bodyReducer: DeclSyntax = """
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                \(raw: switchCases.joined(separator: "\n                "))
                default:
                    return .none
                }
            }
            .forEach(\\.routes, action: \\.router) {
                AppScreen()
            }
        }
        """
        members.append(bodyReducer)

        return members
    }
}

/// 매크로 오류 메시지
struct MacroExpansionErrorMessage: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

/// 컴파일러 플러그인 등록
@main
struct TCAFlowPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FlowCoordinatorMacro.self,
    ]
}