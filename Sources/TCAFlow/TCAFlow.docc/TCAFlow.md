# ``TCAFlow``

TCA(The Composable Architecture)용 Coordinator-style Navigation 라이브러리.

## Overview

TCAFlow는 [TCACoordinators](https://github.com/johnpatrickmorgan/TCACoordinators)와 동일한 API를 제공하면서 **`Hashable` 제약 없이** `Equatable`만으로 coordinator 패턴을 구현할 수 있는 라이브러리입니다.

NavigationStack 기반으로 push, sheet, fullScreenCover를 지원하며, 중첩된 coordinator(Nested Coordinator)도 완벽하게 지원합니다.

### 핵심 특징

- **Hashable 불필요** — Screen State에 `Equatable`만 요구
- **Native NavigationStack** — iOS 16+ NavigationStack API 직접 활용
- **TCA 전용** — FlowStacks 없이 TCA만 의존
- **Nested Coordinator** — 복잡한 플로우를 분리 가능
- **@FlowCoordinator 매크로** — 보일러플레이트 자동 생성
- **Swift 6 호환**

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:NavigationAPI>
- <doc:NestedCoordinator>
- <doc:FlowCoordinatorMacro>

### Core Types

- ``Route``
- ``RouterAction``
- ``TCAFlowRouter``
- ``ScreenStore``

### Type Aliases

- ``IndexedRouterAction``
- ``IndexedRouterActionOf``
- ``IdentifiedRouterAction``
- ``IdentifiedRouterActionOf``

### Reducer Extensions

- ``ComposableArchitecture/Reducer/forEachRoute(_:action:screenReducer:)``
- ``ComposableArchitecture/Reducer/forEachRoute(_:action:)``

### Utilities

- ``routeWithDelaysIfUnsupported(_:action:_:)``
- ``runtimeWarn(_:file:line:)``
