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

        // 1. AppScreen @Reducer enum 생성
        var appScreenCases: [String] = []
        for screenCase in screenCases {
            appScreenCases.append("case \(screenCase.name)(\(screenCase.type).State)")
        }

        let appScreenEnum: DeclSyntax = """
        @Reducer
        enum AppScreen {
            \(raw: appScreenCases.joined(separator: "\n    "))
        }
        """
        members.append(appScreenEnum)

        // 2. @ObservableState struct State 생성
        let firstScreen = screenCases.first?.name ?? "home"
        let stateStruct: DeclSyntax = """
        @ObservableState
        struct State: Equatable {
            var routes: IdentifiedArrayOf<Route<AppScreen.State>> = [
                Route(.\(raw: firstScreen)(.init()))
            ]
        }
        """
        members.append(stateStruct)

        // 3. Action enum 생성
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

        // 4. body reducer 생성 (실제 네비게이션 로직 포함)
        let bodyReducer: DeclSyntax = """
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                // Home 액션들
                case .home(.exploreTapped):
                    state.routes.push(.explore(.init()))
                    return .none

                case .home(.profileTapped):
                    state.routes.goTo(.profile(.init()))
                    return .none

                case .home(.settingsTapped):
                    state.routes.push(.settings(.init()))
                    return .none

                // Explore 액션들
                case .explore(.backTapped):
                    state.routes.pop()
                    return .none

                case .explore(.goToHomeTapped):
                    state.routes.goBackTo(.home(.init()))
                    return .none

                // Profile 액션들
                case .profile(.backTapped):
                    state.routes.pop()
                    return .none

                case .profile(.settingsTapped):
                    state.routes.push(.settings(.init()))
                    return .none

                // Settings 액션들
                case .settings(.backTapped):
                    state.routes.pop()
                    return .none

                case .settings(.goToRootTapped):
                    state.routes.popToRoot()
                    return .none

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
