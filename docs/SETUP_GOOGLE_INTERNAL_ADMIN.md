# Google Workspace MCP 설정 가이드 (Internal 모드 - 관리자용)

> Google Workspace를 사용하는 회사의 관리자가 설정하는 방법입니다.

---

## 이 가이드가 맞는 경우

- [x] 회사가 Google Workspace를 사용합니다 (예: @회사.com 이메일)
- [x] 회사의 IT 관리자이거나 Google Cloud Console 권한이 있습니다
- [x] 회사 직원들이 사용할 수 있도록 설정하려고 합니다

---

## Internal 모드 장점

| 항목 | Internal 모드 |
|------|---------------|
| 사용자 수 | **무제한** |
| 토큰 만료 | **없음** (계속 사용 가능) |
| Google 검토 | 불필요 |
| 경고 화면 | 없음 |

---

## 자동 설정 (권장)

installer의 google 모듈이 자동으로 설정을 안내합니다.

**Windows:** `Win + R` 후 실행
```powershell
powershell -ep bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1))) -modules 'google'"
```

**Mac/Linux:** 터미널에서 실행
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | MODULES="google" bash
```

실행 후 "Admin" 선택 → 안내에 따라 설정 완료.

> 아래 수동 설정은 자동 설치가 안 되거나 참고가 필요한 경우에만 확인하세요.

---

## 수동 설정 (참고용)

### 1단계: Google Cloud Console 설정

### 1-1. 프로젝트 생성

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 상단의 프로젝트 선택 → **새 프로젝트**
3. 프로젝트 이름: `Google Workspace MCP`
4. **만들기** 클릭

### 1-2. API 활성화

1. 왼쪽 메뉴 **APIs & Services** → **Enable APIs and Services**
2. 아래 6개 API를 각각 검색해서 **사용** 클릭:

| API | 검색어 |
|-----|--------|
| Gmail API | gmail |
| Google Calendar API | calendar |
| Google Drive API | drive |
| Google Docs API | docs |
| Google Sheets API | sheets |
| Google Slides API | slides |

### 1-3. OAuth 동의 화면 설정 (중요!)

1. 왼쪽 메뉴 **OAuth consent screen**
2. 왼쪽 메뉴에서 **대상** 클릭
3. **시작하기** 클릭

#### 앱 정보 입력

| 항목 | 입력 값 |
|------|---------|
| 앱 이름 | `Google Workspace MCP` |
| 사용자 지원 이메일 | 본인 이메일 |
| **대상** | **내부 (Internal)** ← 반드시! |
| 연락처 정보 | 본인 이메일 |

**저장** 클릭

### 1-4. 데이터 액세스 (Scopes) 설정

1. 왼쪽 메뉴 **데이터 액세스**
2. **범위 추가** 클릭
3. 아래 7개 범위 선택:

| API | 범위 (검색) |
|-----|-------------|
| Gmail API | `gmail.modify` |
| Gmail API | `gmail.send` |
| Calendar API | `calendar` |
| Drive API | `drive` |
| Docs API | `documents` |
| Sheets API | `spreadsheets` |
| Slides API | `presentations` |

4. **저장** 클릭

### 1-5. OAuth 클라이언트 ID 생성

1. 왼쪽 메뉴 **클라이언트**
2. **+ OAuth 클라이언트 만들기**
3. 설정:

| 항목 | 값 |
|------|-----|
| 애플리케이션 유형 | **데스크톱 앱** |
| 이름 | `MCP Client` |

4. **만들기** 클릭
5. **JSON 다운로드** 아이콘 클릭
6. 파일 이름을 `client_secret.json`으로 변경

---

## 2단계: 직원 배포 준비

### 직원에게 전달할 파일

`client_secret.json` 파일만 전달하면 됩니다.

### 직원 안내 메시지 예시

```
안녕하세요, Google MCP 설정 안내입니다.

1. 첨부된 client_secret.json 파일을 저장하세요

2. 아래 설치 명령어를 실행하세요:

   Windows: Win+R 누르고 아래 명령어 실행
   powershell -ep bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1))) -modules 'google'"

   Mac: 터미널에서 아래 명령어 실행
   curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | MODULES="google" bash

3. Google MCP 설정에서 "Employee" 선택
4. client_secret.json 파일 위치로 복사
5. Google 계정으로 로그인

문의: IT팀
```

---

## 보안 주의사항

**외부 공개 금지:**
- `client_secret.json` - 회사 내부에서만 공유
- 회사 외부 사람에게 절대 전달하지 마세요

---

## 다음 단계

- 직원들에게 위의 "직원 안내 메시지 예시"를 공유하세요
- 다른 모듈도 함께 설치할 수 있습니다:
  - Atlassian: `-modules 'google,atlassian'` (Docker 필요)
  - Notion: `-modules 'google,notion'`
  - GitHub: `-modules 'google,github'`
  - Figma: `-modules 'google,figma'`
  - 전체: `-all`
