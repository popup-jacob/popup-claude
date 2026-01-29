# Claude Code 원클릭 설치

Claude Code + bkit 플러그인 + MCP 도구를 한 번에 설치하는 올인원 설치 프로그램입니다.

---

## 원클릭 설치 (권장)

### Windows

**1단계:** `Win + R` 키를 누르고, 아래 명령어를 붙여넣고 실행:
```
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_basic.ps1|iex"
```

**2단계:** 컴퓨터를 재시작한 후, 다시 `Win + R` 키를 누르고 실행:
```
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_mcp.ps1|iex"
```

### Mac/Linux

터미널을 열고 아래 명령어 실행:
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_all.sh | bash
```

---

## 설치되는 항목

### 기본 설치 (setup_basic.ps1 / setup_all.sh 파트 1)

| 프로그램 | 설명 |
|---------|------|
| Node.js | JavaScript 실행 환경 |
| Git | 버전 관리 도구 |
| VS Code | 코드 편집기 |
| Docker Desktop | 컨테이너 플랫폼 |
| Claude Code CLI | AI 코딩 어시스턴트 |
| bkit 플러그인 | 개발 워크플로우 플러그인 |

### MCP 설치 (setup_mcp.ps1 / setup_all.sh 파트 2)

| 프로그램 | 설명 |
|---------|------|
| Google MCP | Gmail, Calendar, Drive 연동 (선택) |
| Jira MCP | Jira, Confluence 연동 (선택) |

---

## Windows 스크립트 설명

| 스크립트 | 기능 |
|---------|------|
| `setup_basic.ps1` | Node.js, Git, VS Code, Docker, Claude CLI, bkit 설치 |
| `setup_mcp.ps1` | Google MCP, Jira/Confluence MCP 설정 (Docker 필요) |

**왜 2개의 스크립트인가요?** Windows는 Docker 설치 후 재시작이 필요합니다 (WSL2/Hyper-V 활성화).

---

## 문제 해결

### Windows: "winget not found" 에러

이 에러가 발생하면 `install_dev.ps1`을 먼저 실행하세요:

```powershell
# 1단계: 기본 도구 설치 (Node.js, Git, VS Code, Docker, Claude CLI)
powershell -ep bypass -File installer_popup\install_dev.ps1

# 2단계: 컴퓨터 재시작

# 3단계: setup_basic.ps1 실행 (bkit 설정)
powershell -ep bypass -File final-installer\setup_basic.ps1
```

`install_dev.ps1`은 winget 대신 직접 다운로드를 사용하므로 모든 Windows 버전에서 작동합니다.

---

## 참고 사항

### Claude 로그인 (bkit 플러그인용)

bkit 플러그인 설치는 Claude 로그인 없이도 작동할 수 있습니다 (GitHub에서 다운로드).
설치가 실패하면 먼저 로그인을 시도해보세요:
```
claude login
```

---

## Google MCP 관리자 설정

팀을 위해 Google MCP를 설정하는 **관리자**라면:

1. Google Cloud Console 설정 (프로젝트 생성, API 활성화, OAuth 설정)
2. 관리자 가이드 참고: [docs/SETUP_GOOGLE_INTERNAL_ADMIN.md](docs/SETUP_GOOGLE_INTERNAL_ADMIN.md)
3. 직원들에게 `client_secret.json` 공유

외부 (Google Workspace 외) 설정: [docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md](docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md)

---

## 폴더 구조

```
popup-claude/
├── final-installer/     # 원클릭 설치 스크립트 (권장)
├── installer_popup/     # 기존 설치 스크립트
├── google-workspace-mcp/ # Google MCP 소스 코드
└── docs/                # 설정 가이드 문서
```

---

## 도움이 필요하면

문제가 발생하면 [Issues](https://github.com/popup-jacob/popup-claude/issues)에 문의하세요.
