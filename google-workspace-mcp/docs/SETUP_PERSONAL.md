# Google Workspace MCP - 개인용 설정 가이드

> 개인 Google 계정(gmail.com 등)으로 사용하거나, Google Workspace가 없는 환경에서 설정하는 방법입니다.

## 특징

| 항목 | 내용 |
|------|------|
| 사용자 한도 | 테스트 사용자 100명 |
| 토큰 만료 | 7일마다 재로그인 필요 |
| 경고 화면 | "확인되지 않은 앱" 경고 표시 |
| 사용 가능 계정 | 등록된 테스트 사용자만 |

---

## 사전 요구사항

- [ ] Google 계정 (gmail.com 또는 다른 Google 계정)
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
| 대상 | **외부 (External)** |
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

### 2-5. 테스트 사용자 등록 (중요!)

1. 왼쪽 메뉴 **대상** 클릭
2. **테스트 사용자** 섹션에서 **+ ADD USERS** 클릭
3. 본인 Google 계정 이메일 입력 (예: `myemail@gmail.com`)
4. **추가** 클릭
5. **저장** 클릭

> **주의:** 테스트 사용자로 등록하지 않으면 로그인할 수 없습니다!

### 2-6. OAuth 클라이언트 ID 생성

1. 왼쪽 메뉴 **클라이언트** 클릭
2. **+ OAuth 클라이언트 만들기** 클릭
3. 설정:

| 항목 | 선택/입력 값 |
|------|-------------|
| 애플리케이션 유형 | **데스크톱 앱** |
| 이름 | `MCP Client` (원하는 이름) |

4. **만들기** 클릭

### 2-7. JSON 다운로드

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

브라우저가 열리면:

1. 테스트 사용자로 등록한 계정으로 로그인
2. **"이 앱은 Google의 확인을 받지 않았습니다"** 경고가 표시됨
3. **고급** 클릭
4. **[앱 이름](으)로 이동 (안전하지 않음)** 클릭
5. **계속** 클릭하여 권한 허용

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

## 사용 예시

Claude에서:

```
"내 캘린더 일정 보여줘"
"친구한테 메일 보내줘"
"드라이브에서 파일 찾아줘"
"새 문서 만들어줘"
```

---

## 7일마다 재로그인

테스트 모드에서는 토큰이 7일 후 만료됩니다.

**재로그인 방법:**

1. `.google-workspace/token.json` 삭제
2. 다시 로그인 테스트 명령어 실행:
   ```bash
   node -e "import('./dist/auth/oauth.js').then(m => m.getGoogleServices())"
   ```
3. 브라우저에서 다시 로그인

---

## 다른 사람 추가하기

본인 외에 다른 사람도 사용하게 하려면:

1. Google Cloud Console → **대상** → **테스트 사용자**
2. **+ ADD USERS** 클릭
3. 추가할 사람의 Google 이메일 입력
4. **저장**

> **한도:** 최대 100명까지 테스트 사용자 등록 가능

---

## 문제 해결

### "Access blocked: This app's request is invalid" 오류

→ 테스트 사용자로 등록되지 않은 계정으로 로그인 시도함
→ Google Cloud Console에서 테스트 사용자에 본인 이메일 추가

### "이 앱은 Google의 확인을 받지 않았습니다" 화면

→ 정상입니다! 테스트 모드에서는 항상 표시됨
→ **고급** → **[앱 이름](으)로 이동** 클릭

### Docker 이미지를 찾을 수 없음

→ Docker Desktop이 실행 중인지 확인
→ `docker build -t google-workspace-mcp .` 다시 실행

### 토큰 만료 오류

→ `.google-workspace/token.json` 삭제
→ 다시 로그인

---

## 보안 주의사항

**절대 공유하면 안 되는 파일:**
- `.google-workspace/client_secret.json` (내 Client ID)
- `.google-workspace/token.json` (내 로그인 토큰)

이 파일들은 `.gitignore`에 포함되어 있습니다.

---

## 프로덕션 모드로 전환하려면

테스트 모드의 제한(100명, 7일 만료)을 없애려면 Google 검토를 받아야 합니다.

필요한 것:
- 개인정보처리방침 페이지 (공개 URL)
- 앱 설명 및 권한 사용 목적
- 데모 영상 (YouTube)

검토 기간: 2~6주 (권한에 따라 다름)

자세한 내용은 [Google OAuth 검토 가이드](https://support.google.com/cloud/answer/9110914)를 참고하세요.
