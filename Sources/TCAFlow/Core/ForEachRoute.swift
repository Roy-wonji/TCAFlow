@_spi(Internals) import ComposableArchitecture
import CasePaths
import Foundation

// MARK: - OnRoutes

/// Wraps a screen reducer to work on Route<ScreenState> by scoping into .screen.
struct OnRoutes<WrappedReducer: Reducer>: Reducer {
  typealias State = Route<WrappedReducer.State>
  typealias Action = WrappedReducer.Action
  let wrapped: WrappedReducer

  var body: some ReducerOf<Self> {
    Scope(state: \.screen, action: \.self) { wrapped }
  }
}

// MARK: - _ForEachIndexReducer

/// Array-index-based ForEach reducer (adapted from TCA's deprecated version).
extension Reducer {
  func forEachIndex<ElementState, ElementAction, Element: Reducer>(
    _ toElementsState: WritableKeyPath<State, [ElementState]>,
    action toElementAction: CaseKeyPath<Action, (id: Int, action: ElementAction)>,
    @ReducerBuilder<ElementState, ElementAction> element: () -> Element,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _ForEachIndexReducer<Self, Element>
  where ElementState == Element.State, ElementAction == Element.Action {
    _ForEachIndexReducer(
      parent: self,
      toElementsState: toElementsState,
      toElementAction: toElementAction,
      element: element(),
      fileID: fileID,
      line: line
    )
  }
}

struct _ForEachIndexReducer<Parent: Reducer, Element: Reducer>: Reducer
where Parent.Action: CasePathable {
  let parent: Parent
  let toElementsState: WritableKeyPath<Parent.State, [Element.State]>
  let toElementAction: CaseKeyPath<Parent.Action, (id: Int, action: Element.Action)>
  let element: Element
  let fileID: StaticString
  let line: UInt

  @ReducerBuilder<Parent.State, Parent.Action>
  var body: some ReducerOf<Parent> {
    Reduce { state, action in
      guard let (index, elementAction) = action[case: toElementAction] else { return .none }
      if state[keyPath: toElementsState][safe: index] == nil {
        runtimeWarn(
          "forEachRoute at \"\(fileID):\(line)\" received action for index \(index) but array has \(state[keyPath: toElementsState].count) elements."
        )
        return .none
      }
      let casePath = AnyCasePath(toElementAction)
      return element
        .reduce(into: &state[keyPath: toElementsState][index], action: elementAction)
        .map { casePath.embed((id: index, action: $0)) }
    }
    parent
  }
}

// MARK: - UpdateRoutesOnInteraction

extension Reducer {
  func updatingRoutesOnInteraction<Screen>(
    updateRoutes: CaseKeyPath<Action, [Route<Screen>]>,
    toLocalState: WritableKeyPath<State, [Route<Screen>]>
  ) -> some ReducerOf<Self> where Action: CasePathable {
    CombineReducers {
      self
      Reduce { state, action in
        if let routes = action[case: updateRoutes] {
          state[keyPath: toLocalState] = routes
        }
        return .none
      }
    }
  }
}

// MARK: - ForEachIndexedRoute

/// The core reducer that combines child screen reducers with coordinator logic.
struct ForEachIndexedRoute<
  CoordinatorReducer: Reducer,
  ScreenReducer: Reducer
>: Reducer
where CoordinatorReducer.Action: CasePathable,
      ScreenReducer.Action: CasePathable
{
  let coordinatorReducer: CoordinatorReducer
  let screenReducer: ScreenReducer
  let toLocalState: WritableKeyPath<CoordinatorReducer.State, [Route<ScreenReducer.State>]>
  let toLocalAction: CaseKeyPath<CoordinatorReducer.Action, IndexedRouterActionOf<ScreenReducer>>

  var body: some ReducerOf<CoordinatorReducer> {
    // Screen reducers: run child reducer for each route action
    EmptyReducer()
      .forEachIndex(toLocalState, action: toLocalAction.appending(path: \.routeAction)) {
        OnRoutes(wrapped: screenReducer)
      }
      .updatingRoutesOnInteraction(
        updateRoutes: toLocalAction.appending(path: \.updateRoutes),
        toLocalState: toLocalState
      )

    // Coordinator reducer: handles navigation logic
    coordinatorReducer
  }
}

// MARK: - Reducer + forEachRoute

public extension Reducer {
  /// forEachRoute with explicit screen reducer.
  func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction>(
    _ routes: WritableKeyPath<State, [Route<ScreenState>]>,
    action: CaseKeyPath<Action, IndexedRouterAction<ScreenState, ScreenAction>>,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerOf<Self>
  where Action: CasePathable,
        ScreenState == ScreenReducer.State,
        ScreenAction == ScreenReducer.Action,
        ScreenAction: CasePathable
  {
    ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      toLocalState: routes,
      toLocalAction: action
    )
  }

  /// forEachRoute with automatic screen reducer inference (for @Reducer enum).
  func forEachRoute<ScreenState, ScreenAction>(
    _ routes: WritableKeyPath<Self.State, [Route<ScreenState>]>,
    action: CaseKeyPath<Self.Action, IndexedRouterAction<ScreenState, ScreenAction>>
  ) -> some ReducerOf<Self>
  where Action: CasePathable,
        ScreenState: CaseReducerState,
        ScreenState.StateReducer.Action == ScreenAction,
        ScreenAction: CasePathable
  {
    ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: ScreenState.StateReducer.body,
      toLocalState: routes,
      toLocalAction: action
    )
  }
}
