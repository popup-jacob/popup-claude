# Google Workspace MCP 설정 가이드 (External 모드 - 관리자용)

> Google Workspace가 없는 회사나 개인이 설정하는 방법입니다.

---

## 이 가이드가 맞는 경우

- [x] 회사가 Google Workspace를 사용하지 않습니다 (일반 Gmail 사용)
- [x] 또는 개인적으로 사용하려고 합니다
- [x] Google Cloud Console에 접근할 수 있습니다

---

## External 모드 특징

| 항목 | External 모드 |
|------|---------------|
| 사용자 수 | **최대 100명** |
| 토큰 만료 | **7일마다 재로그인 필요** |
| Google 검토 | 100명 초과시 필요 |
| 경고 화면 | "확인되지 않은 앱" 경고 표시 |

---

## 관리자가 할 일 요약

```
1. Google Cloud Console 설정 (20분)
   └── client_secret.json 생성
   └── 테스트 사용자 등록 (100명까지)

2. 팀원에게 배포 파일 전달
   └── client_secret.json + 기존 .tar 파일 + 스크립트
```

---

## 1단계: Google Cloud Console 설정

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

### 1-3. OAuth 동의 화면 설정

1. 왼쪽 메뉴 **OAuth consent screen**
2. **시작하기** 클릭

#### 앱 정보 입력

| 항목 | 입력 값 |
|------|---------|
| 앱 이름 | `Google Workspace MCP` |
| 사용자 지원 이메일 | 본인 이메일 |
| **대상** | **외부 (External)** |
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

### 1-5. 테스트 사용자 추가 (중요!)

1. 왼쪽 메뉴 **대상**
2. **테스트 사용자** 섹션
3. **사용자 추가** 클릭
4. 사용할 팀원들의 Gmail 주소 입력 (최대 100명)
5. **저장** 클릭

> 여기에 등록된 사람만 사용 가능!

### 1-6. OAuth 클라이언트 ID 생성

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

## 2단계: 팀원 배포 준비

### 팀원에게 전달할 파일

```
📁 google-mcp-setup/
├── client_secret.json          ← 방금 다운로드한 것
├── google-workspace-mcp.tar    ← 기존 Docker 이미지 (재사용)
├── setup_employee.ps1          ← Windows용 스크립트 (재사용)
└── setup_employee.sh           ← Mac용 스크립트 (재사용)
```

### 파일 위치

| 파일 | 위치 |
|------|------|
| `client_secret.json` | Google Cloud Console에서 다운로드 |
| `google-workspace-mcp.tar` | 기존에 만들어둔 Docker 이미지 |
| `setup_employee.ps1` | `google-workspace-mcp/scripts/` |
| `setup_employee.sh` | `google-workspace-mcp/scripts/` |

### 팀원 안내 메시지 예시

```
안녕하세요, Google MCP 설정 파일입니다.

1. 첨부 파일 4개를 한 폴더에 저장하세요
2. Docker Desktop을 실행하세요
3. Windows: setup_employee.ps1 더블클릭
   Mac: 터미널에서 ./setup_employee.sh 실행
4. 안내에 따라 진행하세요

※ 7일마다 재로그인이 필요합니다 (External 모드 제한)

문의: 관리자
```

---

## 100명 초과 사용하려면

| 방법 | 설명 |
|------|------|
| Google 검토 신청 | 개인정보처리방침, 데모영상 필요. 몇 주 소요 |
| Google Workspace 전환 | 회사 도메인 이메일 사용. Internal 모드로 무제한 |

---

## 보안 주의사항

**외부 공개 금지:**
- `client_secret.json` - 팀 내부에서만 공유
- 팀 외부 사람에게 절대 전달하지 마세요

---

## 다음 단계

- 팀원들에게 [직원용 설정 가이드](SETUP_GOOGLE_EXTERNAL_EMPLOYEE.md) 공유
- Jira도 연동하려면 [Jira 설정 가이드](SETUP_JIRA_DEVELOPER.md) 참고
