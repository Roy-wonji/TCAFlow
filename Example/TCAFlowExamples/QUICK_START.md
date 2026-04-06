# 🚀 TCAFlowExamples 빠른 시작

## 패키지 의존성 추가

현재 Xcode 프로젝트가 열려있다면 다음 단계를 따르세요:

### 1. TCA 패키지 추가
```
Project → Package Dependencies → + → 
URL: https://github.com/pointfreeco/swift-composable-architecture
Version: 1.25.5+
Target: ComposableArchitecture
```

### 2. TCAFlow 로컬 패키지 추가  
```
+ → Add Local... → 
폴더: ../../ (TCAFlow 루트)
Target: TCAFlow
```

### 3. 실행
```
⌘+R
```

## ✅ 성공하면 이런 화면이 나타납니다:

```
📱 홈 화면
├─ 🔍 탐색하기 (애니메이션)
├─ 👤 프로필 (직접 이동)  
└─ ⚙️ 설정 (스택 push)
```

## 🔧 문제 해결

### "No such module" 오류
1. Clean Build Folder (⌘+Shift+K)
2. 패키지 의존성 다시 확인
3. Xcode 재시작

### 빌드 오류
1. iOS Deployment Target이 16.0인지 확인
2. Swift 6.0 호환성 확인

## 📚 더 보기
- [전체 문서](../SETUP_GUIDE.md)
- [TCAFlow API](../../DOCUMENTATION.md)