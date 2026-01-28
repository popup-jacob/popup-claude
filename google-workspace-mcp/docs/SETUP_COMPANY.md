# Google Workspace MCP - 회사용 설정 가이드

> Google Workspace를 사용하는 회사에서 직원들이 사용할 수 있도록 설정하는 방법입니다.

## 장점

| 항목 | 내용 |
|------|------|
| 사용자 한도 | 무제한 (회사 직원 전체) |
| 토큰 만료 | 없음 (계속 사용 가능) |
| 경고 화면 | 없음 |
| 사용 가능 계정 | @회사도메인.com 만 |

---

## 사전 요구사항

- [ ] Google Workspace를 사용하는 회사 (예: @company.com 이메일)
- [ ] Google Cloud Console 접근 권한 (회사 관리자 또는 본인 계정)
- [ ] Docker Desktop 설치
- [ ] Node.js 20 이상 설치

---

## 1단계: 코드 다운로드

```bash
git clone <repository-url>
cd google-workspace-mcp
```

---

## 2단계: Google Cloud Console 설정

### 2-1. 프로젝트 생성

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 상단의 프로젝트 선택 → **새 프로젝트**
3. 프로젝트 이름 입력 (예: `Google Workspace MCP`)
4. **만들기** 클릭

### 2-2. API 활성화

1. 왼쪽 메뉴 **APIs & Services** → **Enable APIs and Services**
2. 아래 6개 API 검색해서 각각 **사용** 버튼 클릭:

| API 이름 | 검색어 |
|----------|--------|
| Gmail API | gmail |
| Google Calendar API | calendar |
| Google Drive API | drive |
| Google Docs API | docs |
| Google Sheets API | sheets |
| Google Slides API | slides |

### 2-3. OAuth 동의 화면 설정

1. 왼쪽 메뉴 **Google 인증 플랫폼** (또는 OAuth consent screen)
2. **시작하기** 클릭

#### 앱 정보 입력

| 항목 | 입력 값 |
|------|---------|
| 앱 이름 | `Google Workspace MCP` (원하는 이름) |
| 사용자 지원 이메일 | 본인 이메일 선택 |
| 대상 | **내부 (Internal)** ← 중요! |
| 연락처 정보 | 본인 이메일 입력 |

**저장** 클릭

### 2-4. 데이터 액세스 (Scopes) 설정

1. 왼쪽 메뉴 **데이터 액세스** 클릭
2. **범위 추가** 버튼 클릭
3. 아래 7개 범위 검색해서 선택:

| API | 범위 |
|-----|------|
| Gmail API | `.../auth/gmail.modify` |
| Gmail API | `.../auth/gmail.send` |
| Google Calendar API | `.../auth/calendar` |
| Google Drive API | `.../auth/drive` |
| Google Docs API | `.../auth/documents` |
| Google Sheets API | `.../auth/spreadsheets` |
| Google Slides API | `.../auth/presentations` |

4. **저장** 클릭

### 2-5. OAuth 클라이언트 ID 생성

1. 왼쪽 메뉴 **클라이언트** 클릭
2. **+ OAuth 클라이언트 만들기** 클릭
3. 설정:

| 항목 | 선택/입력 값 |
|------|-------------|
| 애플리케이션 유형 | **데스크톱 앱** |
| 이름 | `MCP Client` (원하는 이름) |

4. **만들기** 클릭

### 2-6. JSON 다운로드

1. 생성된 클라이언트 옆의 **다운로드 아이콘(⬇️)** 클릭
2. 다운로드된 파일 이름을 `client_secret.json`으로 변경

---

## 3단계: 파일 배치

프로젝트 폴더에 `.google-workspace` 폴더 생성 후 JSON 파일 이동:

```bash
mkdir .google-workspace
mv ~/Downloads/client_secret.json .google-workspace/
```

폴더 구조:
```
google-workspace-mcp/
├── .google-workspace/
│   └── client_secret.json    ← 여기에 배치
├── src/
├── package.json
└── ...
```

---

## 4단계: 빌드 및 테스트

### 로컬 테스트

```bash
npm install
npm run build
npm start
```

### Google 로그인 테스트

```bash
node -e "import('./dist/auth/oauth.js').then(m => m.getGoogleServices())"
```

브라우저가 열리면 **회사 계정** (@회사도메인.com)으로 로그인하세요.

---

## 5단계: Docker 이미지 빌드

```bash
docker build -t google-workspace-mcp .
```

---

## 6단계: Claude 연동 설정

### VS Code (Claude Code)

프로젝트 폴더에 `.mcp.json` 파일 생성:

```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "경로/.google-workspace:/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
```

**경로** 부분을 실제 경로로 변경하세요.

### Claude Desktop

`%APPDATA%\Claude\claude_desktop_config.json` (Windows) 또는
`~/Library/Application Support/Claude/claude_desktop_config.json` (Mac):

```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "경로/.google-workspace:/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
```

---

## 7단계: 직원 배포

### 각 직원이 해야 할 것

1. Docker Desktop 설치
2. Docker 이미지 받기 (회사 레지스트리 또는 직접 빌드)
3. `.mcp.json` 파일 복사
4. **본인 회사 계정으로 로그인** (최초 1회)

### 관리자가 해야 할 것

- Docker 이미지 배포 (회사 레지스트리에 push)
- 설정 파일 공유
- 사용 가이드 공유

---

## 사용 예시

Claude에서:

```
"내 캘린더 일정 보여줘"
"koyu@company.com한테 메일 보내줘"
"드라이브에서 기획서 찾아줘"
"새 문서 만들어줘"
```

---

## 문제 해결

### "내부 사용자만 앱에 액세스할 수 있습니다" 오류

→ Google Workspace가 아닌 계정(예: gmail.com)으로 로그인 시도함
→ 회사 계정 (@회사도메인.com)으로 로그인하세요

### Docker 이미지를 찾을 수 없음

→ Docker Desktop이 실행 중인지 확인
→ `docker build -t google-workspace-mcp .` 다시 실행

### 토큰 오류

→ `.google-workspace/token.json` 삭제 후 다시 로그인

---

## 보안 주의사항

**절대 공유하면 안 되는 파일:**
- `.google-workspace/client_secret.json` (회사 Client ID)
- `.google-workspace/token.json` (개인 로그인 토큰)

이 파일들은 `.gitignore`에 포함되어 있습니다.
