# AI-Driven Work (ADW)

Claude Code + bkit 플러그인 + MCP 도구를 한 번에 설치하는 올인원 설치 프로그램입니다.

---

## 원클릭 설치 (권장)

### Windows

**1단계:** `Win + R` 키를 누르고, 아래 명령어를 붙여넣고 실행:
```
powershell -ep bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1))) -installDocker"
```

**2단계:** 컴퓨터를 재시작한 후, 다시 `Win + R` 키를 누르고 실행:
```
powershell -ep bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1))) -modules 'google' -skipBase"
```

### Mac/Linux

터미널을 열고 아래 명령어 실행:
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | MODULES="google" bash
```

---

## 설치되는 항목

### 기본 설치 (Base)

| 프로그램 | 설명 |
|---------|------|
| Node.js | JavaScript 실행 환경 |
| Git | 버전 관리 도구 |
| VS Code | 코드 편집기 |
| Docker Desktop | 컨테이너 플랫폼 (선택) |
| Claude Code CLI | AI 코딩 어시스턴트 |
| bkit 플러그인 | 개발 워크플로우 플러그인 |

### MCP 모듈 (선택)

| 모듈 | 설명 |
|------|------|
| Google | Gmail, Calendar, Drive 연동 (Docker 필요) |
| Atlassian | Jira, Confluence 연동 (Docker 필요) |
| Notion | Notion 연동 |
| GitHub | GitHub 연동 |
| Figma | Figma 연동 |

---

## 폴더 구조

```
popup-claude/
├── installer/           # 모듈식 자동 설치 프로그램
├── landing-page/        # 랜딩 페이지
├── docs/                # 설정 가이드 문서
├── google-workspace-mcp/ # Google MCP 소스 코드
└── README.md
```

---

## 문서

- [Google MCP 관리자 설정 (Internal)](docs/SETUP_GOOGLE_INTERNAL_ADMIN.md)
- [Google MCP 관리자 설정 (External)](docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md)

---

## 도움이 필요하면

문제가 발생하면 [Issues](https://github.com/popup-jacob/popup-claude/issues)에 문의하세요.
