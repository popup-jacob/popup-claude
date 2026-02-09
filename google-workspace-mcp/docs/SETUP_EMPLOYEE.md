# Google Workspace MCP - 직원용 설정 가이드

> 관리자가 이미 설정을 완료한 상태에서, 직원들이 사용하기 위한 간단한 가이드입니다.

---

## 필요한 것

관리자에게 받을 파일:
- [ ] `client_secret.json` 파일
- [ ] `.mcp.json` 설정 파일 (또는 설정 내용)

설치할 프로그램:
- [ ] Docker Desktop

---

## 설정 방법 (5분)

### 1단계: Docker Desktop 설치

이미 설치되어 있으면 건너뛰세요.

**Windows:**
1. https://www.docker.com/products/docker-desktop/ 접속
2. **Download for Windows** 클릭
3. 설치 후 **컴퓨터 재시작**
4. Docker Desktop 실행

**Mac:**
1. https://www.docker.com/products/docker-desktop/ 접속
2. **Download for Mac** 클릭
3. 설치 후 Docker Desktop 실행

---

### 2단계: 폴더 생성 및 파일 배치

#### Windows

1. 파일 탐색기 열기
2. `C:\Users\{내이름}` 폴더로 이동
3. `.google-workspace` 폴더 생성
4. 관리자에게 받은 `client_secret.json` 파일을 그 폴더에 넣기

```
C:\Users\{내이름}\
└── .google-workspace\
    └── client_secret.json    ← 여기에 넣기
```

#### Mac

터미널에서:
```bash
mkdir -p ~/.google-workspace
```

관리자에게 받은 `client_secret.json` 파일을 `~/.google-workspace/` 폴더에 넣기

---

### 3단계: Docker 이미지 받기

관리자에게 Docker 이미지 받는 방법 확인하세요.

**방법 A: 회사 레지스트리에서 받기**
```bash
docker pull {회사레지스트리}/google-workspace-mcp
```

**방법 B: 파일로 받기**
```bash
docker load -i google-workspace-mcp.tar
```

**방법 C: 직접 빌드**
```bash
cd google-workspace-mcp
docker build -t google-workspace-mcp .
```

---

### 4단계: Claude 설정

#### VS Code 사용하는 경우

프로젝트 폴더에 `.mcp.json` 파일 생성 (관리자가 내용 공유):

**Windows:**
```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "C:/Users/{내이름}/.google-workspace:/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
```

**Mac:**
```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/Users/{내이름}/.google-workspace:/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
```

> **{내이름}** 부분을 본인 컴퓨터 사용자 이름으로 변경하세요.

#### Claude Desktop 사용하는 경우

설정 파일 위치:
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`

위와 같은 내용으로 파일 생성/수정

---

### 5단계: 최초 로그인

1. VS Code 또는 Claude Desktop 재시작
2. Claude에게 아무 Google 관련 명령 입력:
   ```
   내 캘린더 일정 보여줘
   ```
3. 브라우저가 열리면 **본인 회사 계정**으로 로그인
4. 권한 허용
5. 끝!

---

## 사용 예시

```
"내 캘린더 일정 보여줘"
"test@회사.com한테 메일 보내줘"
"드라이브에서 기획서 찾아줘"
"새 문서 만들어줘"
"이번 주 빈 시간 찾아줘"
```

---

## 문제 해결

### "Docker를 찾을 수 없습니다" 오류

→ Docker Desktop이 실행 중인지 확인
→ Docker Desktop 실행 후 다시 시도

### "client_secret.json 파일이 없습니다" 오류

→ 파일 경로 확인
→ `.google-workspace` 폴더에 파일이 있는지 확인
→ `.mcp.json`의 경로가 맞는지 확인

### 로그인 화면이 안 뜸

→ Docker Desktop이 실행 중인지 확인
→ VS Code / Claude Desktop 재시작

### "이 앱은 내부 사용자만 액세스할 수 있습니다" 오류

→ 회사 계정(@회사도메인.com)으로 로그인해야 함
→ 개인 Gmail 계정으로는 로그인 불가

---

## 도움이 필요하면

설정 중 문제가 있으면 관리자에게 문의하세요.

**전달할 정보:**
- 어떤 단계에서 문제가 생겼는지
- 에러 메시지 (있으면 화면 캡처)
- Windows인지 Mac인지
