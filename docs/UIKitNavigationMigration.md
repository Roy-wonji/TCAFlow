# UIKit navigation migration checkpoint

Status: internal prototype, not the default router. No public API or package dependency changes.

## Implemented foundation

- `Sources/TCAFlow/Core/NavigationStackState.swift`: desired/displayed snapshots,
  serialized transitions, latest-snapshot coalescing, cancellation and stale-callback guards.
- `Sources/TCAFlow/Core/UIKitNavigationHost.swift`: an internal representable owning
  a fresh navigation controller, stable hosting-controller identities, deferred reconciliation,
  and teardown. This is not an external UIKit attachment API.
- `Tests/TCAFlowTests/NavigationStackStateTests.swift`: deterministic state-machine
  cases, including 1,000 unchanged snapshots and a reset during a user transition.
- `Tests/TCAFlowTests/UIKitNavigationDriverTests.swift`: controller reuse,
  programmatic pop and teardown checks. These require an iOS test host.
- `Tests/TCAFlowTests/RouterNestedPushTests.swift`: public-API baseline cases for
  Home → nested root → Chat → Final, and a seeded deep link.

The existing `TCAFlowRouter` still uses the released SwiftUI implementation.
The new host is internal and intentionally has no automatic production selector.

## Required next gates

1. Compile and run the state tests, then the iOS baseline and driver tests. None
   have been executed for this checkpoint because builds/simulators were stopped.
2. Establish title, toolbar, dismiss, safe-area, keyboard and interactive-pop
   behavior in a mounted UIKit host against the released router. Cancellation must
   be verified with a real gesture, not just synthetic transition inputs.
3. Implement typed Store segment registration and nested root flattening. Entry
   generations must be independent of the existing index-based scope cache. Test
   remove/reinsert, same-index screen replacement, deep links and parent removal.
4. Connect modal/tab boundaries and external UIKit attachments, preserving external
   prefix controllers, delegate behavior and transition ownership.
5. Only after parity is demonstrated, select UIKit internally on iOS without
   changing existing consumer calls. Keep the other platforms' existing behavior.

## Explicit limitations

- The prototype currently receives already constructed entries; it does not yet
  discover nested TCA stores or synchronize popped entries back into typed routes.
- External navigation controllers with existing screens/delegates are rejected;
  their prefix and callback adapter are not implemented.
- Modal presentation, inherited environment propagation and generation allocation
  are not integrated. No UIKit behavior equivalence is claimed.
- There is no release, commit or consumer migration in this checkpoint.

## Reference boundaries

Apple documents [hosting SwiftUI in UIKit](https://developer.apple.com/documentation/swiftui/uihostingcontroller),
but that alone does not establish title/toolbar/dismiss parity for this router.
The driver uses [transition completion](https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinator/animate(alongsidetransition:completion:))
and [cancellation state](https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinatorcontext/iscancelled)
when a transition coordinator is available; a didShow notification alone is not
treated as proof that a pop succeeded. Actual owned controller identities are compared.
