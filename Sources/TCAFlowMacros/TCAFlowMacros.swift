import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct FlowCoordinatorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let embedInNavigationView = try Self.embedInNavigationView(from: node)

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@FlowCoordinator는 struct에만 적용할 수 있습니다")
        }

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

        var screenCases: [(name: String, type: String)] = []
        for member in screenEnum.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text

                    if let parameterClause = element.parameterClause,
                       let firstParam = parameterClause.parameters.first {
                        let typeName = firstParam.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        screenCases.append((name: caseName, type: typeName))
                    }
                }
            }
        }

        guard let firstScreen = screenCases.first else {
            throw MacroExpansionErrorMessage("@FlowCoordinator.Screen은 최소 1개 이상의 case를 포함해야 합니다")
        }

        var members: [DeclSyntax] = []

        let appScreenCases = screenCases
            .map { "case \($0.name)(\($0.type))" }
            .joined(separator: "\n    ")

        let stateCases = screenCases
            .map { "case \($0.name)(\($0.type).State)" }
            .joined(separator: "\n      ")

        let actionCases = screenCases
            .map { "case \($0.name)(\($0.type).Action)" }
            .joined(separator: "\n      ")

        let caseReducers = screenCases
            .map { screenCase in
                """
                .ifCaseLet(\\Self.State.Cases.\(screenCase.name), action: \\Self.Action.Cases.\(screenCase.name)) {
                  \(screenCase.type)()
                }
                """
            }
            .joined(separator: "\n        ")

        let caseScopeCases = screenCases
            .map { "case \($0.name)(ComposableArchitecture.StoreOf<\($0.type)>)" }
            .joined(separator: "\n      ")

        let casePathProperties = screenCases
            .map { screenCase in
                """
                var \(screenCase.name): CasePaths.AnyCasePath<CaseScope, ComposableArchitecture.StoreOf<\(screenCase.type)>> {
                  CasePaths.AnyCasePath(
                    embed: { @Sendable in CaseScope.\(screenCase.name)($0) },
                    extract: { guard case let .\(screenCase.name)(store) = $0 else { return nil }; return store }
                  )
                }
                """
            }
            .joined(separator: "\n\n        ")

        let storeScopes = screenCases
            .map { screenCase in
                """
                case .\(screenCase.name):
                  return .\(screenCase.name)(store.scope(state: \\.\(screenCase.name), action: \\.\(screenCase.name))!)
                """
            }
            .joined(separator: "\n      ")

        let appScreenEnum: DeclSyntax = """
        enum AppScreen: Swift.Sendable, ComposableArchitecture.CaseReducer, ComposableArchitecture.Reducer {
            \(raw: appScreenCases)

            @CasePaths.CasePathable
            @dynamicMemberLookup
            @ComposableArchitecture.ObservableState
            enum State: ComposableArchitecture.CaseReducerState, CasePaths.CasePathable, CasePaths.CasePathIterable, ComposableArchitecture.ObservableState, Observation.Observable {
              typealias StateReducer = AppScreen
              \(raw: stateCases)
            }

            @CasePaths.CasePathable
            enum Action: CasePaths.CasePathable, CasePaths.CasePathIterable {
              \(raw: actionCases)
            }

            @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
            static var body: ComposableArchitecture.Reduce<Self.State, Self.Action> {
              ComposableArchitecture.Reduce(
                ComposableArchitecture.EmptyReducer<Self.State, Self.Action>()
                \(raw: caseReducers)
              )
            }

            @dynamicMemberLookup
            enum CaseScope: ComposableArchitecture._CaseScopeProtocol, CasePaths.CasePathable {
              \(raw: caseScopeCases)

              struct AllCasePaths {
                \(raw: casePathProperties)
              }

              static var allCasePaths: AllCasePaths { AllCasePaths() }
            }

            @preconcurrency @MainActor
            static func scope(_ store: ComposableArchitecture.Store<Self.State, Self.Action>) -> CaseScope {
              switch store.state {
              \(raw: storeScopes)
              }
            }
        }
        """
        members.append(appScreenEnum)

        let stateStruct: DeclSyntax = """
        @ComposableArchitecture.ObservableState
        struct State: Swift.Equatable {
            var routes = TCAFlow.RouteStack<AppScreen.State>([
                TCAFlow.Route.root(.\(raw: firstScreen.name)(\(raw: firstScreen.type).State()), embedInNavigationView: \(raw: embedInNavigationView))
            ])
        }
        """
        members.append(stateStruct)

        let actionEnum: DeclSyntax = """
        @CasePaths.CasePathable
        enum Action {
            case route(TCAFlow.FlowActionOf<AppScreen>)
        }
        """
        members.append(actionEnum)

        return members
    }

    private static func embedInNavigationView(from node: AttributeSyntax) throws -> String {
        guard case let .argumentList(arguments)? = node.arguments else {
            return "true"
        }

        guard let firstArgument = arguments.first else {
            return "true"
        }

        if let label = firstArgument.label?.text, label != "navigation" {
            throw MacroExpansionErrorMessage("@FlowCoordinator는 'navigation' argument만 지원합니다")
        }

        let value = firstArgument.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value == "true" || value == "false" else {
            throw MacroExpansionErrorMessage("@FlowCoordinator(navigation:)은 true 또는 false만 지원합니다")
        }

        return value
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
