# TCAFlowExamples 설정 가이드

TCAFlowExamples 프로젝트에서 의존성 문제를 해결하는 방법입니다.

## 🚀 빠른 해결책

### 방법 1: Xcode에서 패키지 추가 (권장)

1. **Xcode에서 프로젝트 열기**
   ```bash
   cd Example/TCAFlowExamples
   open TCAFlowExamples.xcodeproj
   ```

2. **패키지 의존성 추가**
   - Project Navigator에서 `TCAFlowExamples` 프로젝트 선택
   - `Package Dependencies` 탭으로 이동
   - `+` 버튼 클릭

3. **TCA 추가**
   - URL: `https://github.com/pointfreeco/swift-composable-architecture`
   - Version: `1.25.5` 이상
   - Target에 `ComposableArchitecture` 추가

4. **TCAFlow 추가**
   - `Add Local...` 선택
   - `TCAFlow` 루트 폴더 선택 (상위 디렉토리 2단계)
   - Target에 `TCAFlow` 추가

5. **빌드 & 실행**
   - ⌘+R로 실행

### 방법 2: 터미널에서 확인

현재 예제 앱이 제대로 설정되었는지 확인:

```bash
cd Example/TCAFlowExamples
xcodebuild -project TCAFlowExamples.xcodeproj -scheme TCAFlowExamples -showBuildSettings | grep PACKAGE
```

## 🔧 트러블슈팅

### 문제 1: "No such module 'ComposableArchitecture'"
**해결**: 위의 방법 1을 따라 TCA 패키지 추가

### 문제 2: "No such module 'TCAFlow'"  
**해결**: 로컬 TCAFlow 패키지 추가

### 문제 3: 빌드 오류
**해결**: Clean Build Folder (⌘+Shift+K) 후 다시 빌드

## 📱 대안: Package.swift 기반 예제

iOS 시뮬레이터에서 직접 실행할 수는 없지만, 코드를 확인할 수 있습니다:

```bash
cd Example/TCAFlowExamplesSPM
swift build
```

## ✅ 성공 확인

올바르게 설정되면 다음과 같은 화면을 볼 수 있습니다:
- 홈 화면에 4개 버튼
- 각 화면 간 부드러운 애니메이션
- TCAFlow의 모든 네비게이션 기능

## 🆘 도움말

문제가 계속되면:
1. Xcode 재시작
2. Derived Data 삭제 (`~/Library/Developer/Xcode/DerivedData`)  
3. Package 캐시 삭제 (`~/.swiftpm`)

이 가이드로도 해결되지 않으면 이슈를 남겨주세요!