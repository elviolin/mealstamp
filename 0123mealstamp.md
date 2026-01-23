# MealStamp 프로젝트 메모 (2025.01.23)

---

## 프로젝트 개요

- **앱 이름**: MealStamp (밀스탬프)
- **기능**: 음식 사진 촬영 → AI 칼로리 분석 → 영양정보 카드 생성
- **기술 스택**: Framer (React 기반)
- **GitHub**: https://github.com/elviolin/mealstamp
- **주요 파일**:
  - `app` - 메인 Framer 컴포넌트 (~5000줄)
  - `nutrition-db.json` - 영양정보 DB (349개 음식)

---

## 완료된 작업 (2025.01.23 기준)

### 1. 이미지 저장/공유 통합
- iOS에서 저장 버튼이 공유 시트 띄우는 문제 해결
- "저장하기" 단일 버튼으로 통합 (navigator.share 사용)

### 2. 당(Sugar) 영양소 추가
- AI 프롬프트에 당 계산 추가
- HealthCard에 당 표시 (식이섬유 왼쪽)
- 6개 언어 번역 추가 (ko, ja, en, zh, fr, de)

### 3. 양 단위 입력 버그 수정
- 단위 제안이 사라지는 버그 수정
- blurTimeoutRef로 타이머 충돌 해결

### 4. COMPLETE 화면 레이아웃 개선
- 디자인 옵션을 상단으로 이동
- 저장 버튼을 하단에 분리
- 다크 테마 적용 (#1a1a1a 배경, 글래스모피즘)

### 5. 키보드 버튼 위치 수정
- transform에서 bottom 속성으로 변경
- 키보드 위에 버튼 정확히 고정

### 6. 칼로리 정확도 개선 - 3단계 하이브리드 시스템
```
음식 입력 → [1] 로컬 DB (349개) - 즉시
         → [2] 식약처 API (6만개+) - 0.5~1초
         → [3] GPT API - 최후 수단 2~3초
```

**구현 상세:**
- `nutrition-db.json`: 349개 음식 영양정보 (식약처/USDA/일본 표준성분표 기반)
- GitHub raw URL에서 로드 + localStorage 24시간 캐싱
- 식약처 공공데이터 API 연동 (`lookupFoodAPI` 함수)
- API 키: `3f79c616d1de48c4a7a5bfc7b61a5e07` (임시)

### 7. 스마트 양 단위 제안
- nutrition DB의 serving 정보 기반 단위 제안
- 예: "흰쌀밥" → `1공기`, `반공기`, `210g`, `100g`
- DB에 없으면 카테고리 기반 폴백

---

## 최근 커밋 내역

```
c018924 - fix: 양 단위 제안 - 실제 사용하는 단위로 수정
9f7ef60 - feat: 스마트 양 단위 제안
68a456d - feat: 3단계 하이브리드 영양정보 조회
daa939a - feat: 외부 영양 DB 통합 (349개 음식)
```

---

## 다음 작업: 앱 래핑 (iOS/Android)

### 선택한 방법
**Capacitor + Codemagic** (무료, Mac 없이 가능)

### 전체 절차

```
[1단계] 준비물 설치        ← 다음 세션에서 시작
[2단계] Framer 사이트 내보내기
[3단계] Capacitor 프로젝트 생성
[4단계] GitHub 업로드
[5단계] Codemagic 연결
[6단계] 개발자 계정 등록
[7단계] 앱스토어 제출
```

---

## 1단계: 준비물 설치 (사용자가 미리 해올 것)

### 필수 설치 프로그램

| 프로그램 | 다운로드 링크 | 설치 방법 |
|----------|--------------|----------|
| **Node.js** | https://nodejs.org | LTS 버전 다운로드 → 설치 (기본 옵션 유지) |
| **Git** | https://git-scm.com | 다운로드 → 설치 (기본 옵션 유지) |
| **VS Code** | https://code.visualstudio.com | 다운로드 → 설치 |

### 계정 (미리 만들어두면 좋음)
- **GitHub**: https://github.com (이미 있음: elviolin)
- **Codemagic**: https://codemagic.io (GitHub로 가입 가능)

### 나중에 필요 (앱 제출 시)
- **Apple Developer**: https://developer.apple.com ($99/년)
- **Google Play Console**: https://play.google.com/console ($25 1회)

### 설치 확인 방법
Windows 명령 프롬프트 또는 PowerShell에서:
```bash
node --version    # v18.x.x 또는 v20.x.x 나오면 성공
git --version     # git version 2.x.x 나오면 성공
```

---

## 2단계: Framer 사이트 내보내기

### 방법 A: Framer 유료 플랜인 경우
1. Framer 프로젝트 열기
2. 우측 상단 "Publish" 클릭
3. "Export Code" 옵션 사용 (Pro 플랜 이상)

### 방법 B: 무료 플랜인 경우
1. Framer에서 배포된 URL 사용
2. Capacitor에서 WebView로 URL 로드
3. (이 방법으로 진행 예정)

---

## 3단계: Capacitor 프로젝트 생성

### 폴더 구조 (생성 예정)
```
mealstamp-app/
├── package.json
├── capacitor.config.ts
├── www/
│   └── index.html (Framer URL을 WebView로 로드)
├── android/
│   └── (Android 프로젝트)
└── ios/
    └── (iOS 프로젝트)
```

### 실행할 명령어 (Claude가 가이드)
```bash
# 1. 프로젝트 폴더 생성
mkdir mealstamp-app
cd mealstamp-app

# 2. npm 초기화
npm init -y

# 3. Capacitor 설치
npm install @capacitor/core @capacitor/cli @capacitor/ios @capacitor/android

# 4. Capacitor 초기화
npx cap init "MealStamp" "com.mealstamp.app"

# 5. www 폴더 생성 및 index.html 작성 (WebView용)

# 6. 플랫폼 추가
npx cap add android
npx cap add ios

# 7. 빌드
npx cap sync
```

---

## 4단계: GitHub 업로드

```bash
cd mealstamp-app
git init
git add .
git commit -m "Initial Capacitor setup"
git remote add origin https://github.com/elviolin/mealstamp-app.git
git push -u origin main
```

---

## 5단계: Codemagic 설정

### Codemagic이란?
- 클라우드에서 iOS/Android 앱을 빌드해주는 서비스
- Mac 없이도 iOS 앱 빌드 가능
- 무료 플랜: 월 500분 빌드 시간

### 설정 절차
1. https://codemagic.io 접속
2. GitHub 계정으로 로그인
3. mealstamp-app 저장소 연결
4. codemagic.yaml 파일 추가 (Claude가 작성)
5. 빌드 실행

### codemagic.yaml 예시 (나중에 작성)
```yaml
workflows:
  ios-android:
    name: iOS & Android Build
    max_build_duration: 60
    environment:
      vars:
        BUNDLE_ID: "com.mealstamp.app"
    scripts:
      - npm install
      - npx cap sync
    artifacts:
      - android/app/build/outputs/**/*.apk
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect: # iOS
        api_key: $APP_STORE_API_KEY
      google_play: # Android
        credentials: $GOOGLE_PLAY_CREDENTIALS
```

---

## 6단계: 개발자 계정 등록

### Apple Developer Program
- URL: https://developer.apple.com/programs/
- 비용: $99/년
- 필요 서류: 신분증, 결제 카드
- 승인까지 24~48시간

### Google Play Console
- URL: https://play.google.com/console
- 비용: $25 (1회)
- 바로 사용 가능

---

## 7단계: 앱스토어 제출

### 필요한 자료 (미리 준비)
| 항목 | 사이즈 | 용도 |
|------|--------|------|
| 앱 아이콘 | 1024x1024px | 스토어 표시 |
| 스크린샷 (iPhone) | 1290x2796px | 앱스토어 |
| 스크린샷 (Android) | 1080x1920px | 플레이스토어 |
| 앱 설명 | 4000자 이내 | 스토어 설명 |
| 개인정보처리방침 URL | - | 필수 |

### iOS 제출 절차
1. Codemagic에서 .ipa 파일 빌드
2. App Store Connect에서 앱 등록
3. 앱 정보 입력 (이름, 설명, 스크린샷)
4. 빌드 업로드
5. 심사 제출 (1~3일 소요)

### Android 제출 절차
1. Codemagic에서 .apk/.aab 파일 빌드
2. Google Play Console에서 앱 등록
3. 앱 정보 입력
4. 빌드 업로드
5. 심사 제출 (몇 시간 ~ 1일)

---

## 예상 소요 시간

| 단계 | 예상 시간 |
|------|----------|
| 1단계 준비물 설치 | 30분 |
| 2~4단계 프로젝트 설정 | 1~2시간 |
| 5단계 Codemagic 설정 | 1시간 |
| 6단계 개발자 계정 | 1~2일 (승인 대기) |
| 7단계 앱 제출 | 2~3시간 |
| **총 예상** | **1~2일 (승인 대기 제외)** |

---

## 다음 세션에서 할 일

### 사용자가 미리 해올 것
1. [ ] Node.js 설치 (https://nodejs.org)
2. [ ] Git 설치 (https://git-scm.com)
3. [ ] VS Code 설치 (https://code.visualstudio.com)
4. [ ] 설치 확인: `node --version`, `git --version`

### Claude와 함께 할 것
1. [ ] Capacitor 프로젝트 생성
2. [ ] WebView로 Framer URL 로드하는 설정
3. [ ] GitHub에 새 저장소 생성 및 업로드
4. [ ] Codemagic 연결 및 설정
5. [ ] 테스트 빌드 실행

---

## 참고: 현재 Framer 배포 URL

(아래에 Framer 배포 URL을 적어두세요)
```
https://your-framer-site.framer.app
```

---

## 문제 발생 시 체크리스트

### Node.js 설치 안됨
- Windows: 관리자 권한으로 설치
- 환경 변수 PATH에 Node.js 추가됐는지 확인

### Git 명령어 안됨
- 터미널 재시작
- 환경 변수 PATH 확인

### Capacitor 오류
- `npm cache clean --force` 후 재설치
- Node.js 버전 확인 (18 이상 권장)

### Codemagic 빌드 실패
- codemagic.yaml 문법 확인
- 환경 변수 설정 확인

---

## 연락처 & 리소스

- **GitHub 저장소**: https://github.com/elviolin/mealstamp
- **Capacitor 문서**: https://capacitorjs.com/docs
- **Codemagic 문서**: https://docs.codemagic.io

---

*이 메모를 다음 세션에서 Claude에게 주면 바로 이어서 작업 가능합니다.*
