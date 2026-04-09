import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftUI

public struct FlowCoordinatorMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let embedInNavigationView = try Self.embedInNavigationView(from: node)

        // struct 또는 extension 지원
        let coordinatorName: String
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            coordinatorName = structDecl.name.text
        } else if let extensionDecl = declaration.as(ExtensionDeclSyntax.self) {
            coordinatorName = extensionDecl.extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw MacroExpansionErrorMessage("@FlowCoordinator는 struct 또는 extension에만 적용할 수 있습니다")
        }

        let screenTypeName = Self.screenTypeName(for: coordinatorName)

        // Screen enum 찾기 (struct 또는 extension에서)
        var screenEnum: EnumDeclSyntax?
        let memberBlock: MemberBlockSyntax

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            memberBlock = structDecl.memberBlock
        } else if let extensionDecl = declaration.as(ExtensionDeclSyntax.self) {
            memberBlock = extensionDecl.memberBlock
        } else {
            throw MacroExpansionErrorMessage("지원하지 않는 선언 타입입니다")
        }

        for member in memberBlock.members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "Screen" {
                screenEnum = enumDecl
                break
            }
        }

        // Screen enum과 기존 Action enum 확인
        var screenCases: [(name: String, type: String)] = []
        var existingActionEnum: EnumDeclSyntax?

        // 기존 Action enum 찾기
        for member in memberBlock.members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "Action" {
                existingActionEnum = enumDecl
            }
        }

        if let screenEnum = screenEnum {
            // 기존 방식: 내부 Screen enum에서 case 추출
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
        } else {
            // extension으로 Screen을 정의할 수 있도록 빈 enum과 기본 구조만 생성
            return try Self.generateExtensionFriendlyStructure(
                coordinatorName: coordinatorName,
                screenTypeName: screenTypeName,
                embedInNavigationView: embedInNavigationView
            )
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
        enum \(raw: screenTypeName): Swift.Sendable, ComposableArchitecture.CaseReducer, ComposableArchitecture.Reducer {
            \(raw: appScreenCases)

            @CasePaths.CasePathable
            @dynamicMemberLookup
            @ComposableArchitecture.ObservableState
            enum State: ComposableArchitecture.CaseReducerState, CasePaths.CasePathable, CasePaths.CasePathIterable, ComposableArchitecture.ObservableState, Observation.Observable {
              typealias StateReducer = \(raw: screenTypeName)
              \(raw: stateCases)
            }

            @CasePaths.CasePathable
            enum Action: CasePaths.CasePathable, CasePaths.CasePathIterable {
              \(raw: actionCases)
            }

            static var body: some ComposableArchitecture.Reducer<Self.State, Self.Action> {
              ComposableArchitecture.EmptyReducer<Self.State, Self.Action>()
              \(raw: caseReducers)
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
            public var routes: TCAFlow.RouteStack<\(raw: screenTypeName).State>

            public init() {
                self.routes = TCAFlow.RouteStack([
                    TCAFlow.Route.root(\(raw: screenTypeName).State.\(raw: firstScreen.name)(\(raw: firstScreen.type).State()), embedInNavigationView: \(raw: embedInNavigationView))
                ])
            }
        }
        """
        members.append(stateStruct)

        // 기존 Action enum이 있으면 route case만 추가, 없으면 새로 생성
        if existingActionEnum != nil {
            // 기존 Action enum이 있는 경우, route case만 추가하는 extension 생성
            let routeCaseExtension: DeclSyntax = """
            // MARK: - TCAFlow Route Action Extension
            // route case가 기존 Action enum에 자동으로 추가됩니다.
            // 기존 액션들은 그대로 유지됩니다.
            """
            members.append(routeCaseExtension)

            // 경고 메시지 추가
            let warningComment: DeclSyntax = """
            /*
            ⚠️ @FlowCoordinator 매크로 경고:

            기존 Action enum이 감지되었습니다.
            TCAFlow를 사용하려면 기존 Action enum에 다음 case를 수동으로 추가하세요:

            @CasePaths.CasePathable
            enum Action {
                // 기존 액션들...
                case async(SomeAsyncAction)
                case action(SomeAction)

                // 👇 이 case를 추가하세요
                case route(TCAFlow.FlowAction<\(raw: screenTypeName)>)
            }
            */
            """
            members.append(warningComment)
        } else {
            // 기존 Action enum이 없는 경우, 새로 생성
            let actionEnum: DeclSyntax = """
            @CasePaths.CasePathable
            enum Action {
                case route(TCAFlow.FlowAction<\(raw: screenTypeName)>)
            }
            """
            members.append(actionEnum)
        }

        return members
    }

    // MARK: - ExtensionMacro 구현

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // extension에서는 추가 extension을 생성하지 않음
        // 대신 해당 extension 내부의 Screen enum을 처리함
        return []
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

    private static func screenTypeName(for coordinatorName: String) -> String {
        let baseName: String
        if coordinatorName.hasSuffix("Coordinator") {
            baseName = String(coordinatorName.dropLast("Coordinator".count))
        } else {
            baseName = coordinatorName
        }
        return "\(baseName)Screen"
    }

    /// Extension으로 Screen을 정의할 수 있는 기본 구조 생성
    private static func generateExtensionFriendlyStructure(
        coordinatorName: String,
        screenTypeName: String,
        embedInNavigationView: String
    ) throws -> [DeclSyntax] {

        var members: [DeclSyntax] = []

        // 1. 빈 Screen enum 정의 (extension에서 case 추가 가능)
        let emptyScreenEnum: DeclSyntax = """
        enum \(raw: screenTypeName): Swift.Sendable, Swift.Equatable {
            // Screen cases should be defined in extension
            // Example:
            // extension \(raw: coordinatorName) {
            //   enum Screen {
            //     case home(HomeFeature.State)
            //     case detail(DetailFeature.State)
            //   }
            // }
        }
        """
        members.append(emptyScreenEnum)

        // 2. State 구조체 (RouteStack 타입만 정의, 초기값은 extension에서)
        let stateStruct: DeclSyntax = """
        @ComposableArchitecture.ObservableState
        struct State: Swift.Equatable {
            var routes: TCAFlow.RouteStack<\(raw: screenTypeName)>

            init(routes: TCAFlow.RouteStack<\(raw: screenTypeName)> = []) {
                self.routes = routes
            }
        }
        """
        members.append(stateStruct)

        // 3. Action enum (기본 구조)
        let actionEnum: DeclSyntax = """
        @CasePaths.CasePathable
        enum Action {
            case route(TCAFlow.FlowAction<\(raw: screenTypeName)Action>)
        }
        """
        members.append(actionEnum)

        // 4. Action enum 정의 (extension에서 정의할 수 있도록 빈 구조)
        let actionEnumDef: DeclSyntax = """
        @CasePaths.CasePathable
        enum \(raw: screenTypeName)Action: Swift.Equatable {
            // Actions should be defined in extension
            // Example:
            // extension \(raw: screenTypeName)Action {
            //   case home(HomeFeature.Action)
            //   case detail(DetailFeature.Action)
            // }
        }
        """
        members.append(actionEnumDef)

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

/// Nested coordinator를 위한 extension 매크로
public struct NestedCoordinatorExtensionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // nested coordinator reducer 함수 자동 생성
        let nestedReducerMethod: DeclSyntax = """
        static func reduceNestedCoordinator<T: FlowCoordinating>(
            state: inout T.State,
            action: T.Action
        ) -> ComposableArchitecture.Effect<T.Action> {
            return .none
        }
        """

        return [nestedReducerMethod]
    }
}

/// RouteStack extension 매크로 - 단순화된 버전
public struct RouteStackExtensionsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let extensionMethods: [DeclSyntax] = [
            """
            public var currentRoute: Route<State>? {
                self.routes.currentRoute
            }
            """,
            """
            public var depth: Int {
                self.routes.depth
            }
            """,
            """
            public mutating func push(_ state: State) {
                self.routes.push(state)
            }
            """
        ]

        return extensionMethods
    }
}

/// View transition extension 매크로 - 단순화된 버전
public struct ViewTransitionsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let transitionMethods: [DeclSyntax] = [
            """
            public func slideTransition() -> some View {
                self.transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    )
                )
            }
            """,
            """
            public func fadeTransition() -> some View {
                self.transition(.opacity)
            }
            """,
            """
            public func scaleTransition() -> some View {
                self.transition(.scale.combined(with: .opacity))
            }
            """
        ]

        return transitionMethods
    }
}

/// ForEachRoute 매크로 (미구현)
public struct ForEachRouteMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

/// FlowScreen 매크로 - Screen enum을 extension으로 정의
public struct FlowScreenMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@FlowScreen은 struct에만 적용할 수 있습니다")
        }

        let coordinatorName = structDecl.name.text
        let screenTypeName = Self.screenTypeName(for: coordinatorName)

        // 빈 Screen enum 정의만 생성 (실제 case는 extension으로 정의)
        let screenEnumStub: DeclSyntax = """
        enum \(raw: screenTypeName): Swift.Sendable {
            // Screen cases are defined in extensions
        }
        """

        return [screenEnumStub]
    }

    private static func screenTypeName(for coordinatorName: String) -> String {
        let baseName: String
        if coordinatorName.hasSuffix("Coordinator") {
            baseName = String(coordinatorName.dropLast("Coordinator".count))
        } else {
            baseName = coordinatorName
        }
        return "\(baseName)Screen"
    }
}

/// 개별 Screen case 추가 매크로
public struct FlowScreenCaseMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // 이 매크로는 Screen enum에 case를 추가하는 extension을 생성
        guard declaration.is(EnumDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@FlowScreenCase는 enum에만 적용할 수 있습니다")
        }

        // extension 생성 로직 (나중에 구현)
        return []
    }
}

/// 컴파일러 플러그인 등록
@main
struct TCAFlowPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FlowCoordinatorMacro.self,
        NestedCoordinatorExtensionMacro.self,
        RouteStackExtensionsMacro.self,
        ViewTransitionsMacro.self,
        ForEachRouteMacro.self,
        FlowScreenMacro.self,
        FlowScreenCaseMacro.self,
    ]
}
