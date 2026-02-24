# AI-Driven Work (ADW)

Claude Code 또는 Gemini CLI + 개발 도구 + MCP 모듈을 한 번에 설치하는 올인원 설치 프로그램입니다.

---

## 원클릭 설치 (권장)

랜딩페이지에서 원하는 모듈을 선택하면 설치 명령어가 자동으로 생성됩니다:
https://ai-driven-work.vercel.app

### Windows (Claude)

`Win + R` 키를 누르고, 아래 명령어를 붙여넣고 실행:
```
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1 | iex"
```

모듈 포함 설치:
```
powershell -ep bypass -c "$env:MODULES='google,notion'; irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1 | iex"
```

### Windows (Gemini)

```
powershell -ep bypass -c "$env:CLI_TYPE='gemini'; irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1 | iex"
```

> **Windows**: Docker가 필요한 모듈(google, atlassian) 선택 시 2단계 설치가 필요합니다. 랜딩페이지에서 자동으로 안내됩니다.

### Mac/Linux (Claude)

터미널을 열고 아래 명령어 실행:
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | bash
```

모듈 포함 설치:
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | MODULES="google,notion" bash
```

### Mac/Linux (Gemini)

```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | CLI_TYPE=gemini bash
```

---

## 설치되는 항목

### 기본 설치 (Base)

| 프로그램 | Claude | Gemini |
|---------|--------|--------|
| Node.js | O | O |
| Git | O | O |
| IDE | VS Code | Antigravity |
| Docker Desktop | 선택 | 선택 |
| AI CLI | Claude Code CLI | Gemini CLI |
| 플러그인 | bkit (Claude plugin) | bkit-gemini (Gemini extension) |

### MCP 모듈 (선택)

| 모듈 | 설명 | Docker |
|------|------|--------|
| Google | Gmail, Calendar, Drive, Docs, Sheets, Slides 연동 | 필요 |
| Atlassian | Jira, Confluence 연동 | 필요 |
| Notion | Notion 페이지/DB 연동 | 불필요 |
| GitHub | GitHub CLI 연동 | 불필요 |
| Figma | Figma 디자인 파일 연동 | 불필요 |
| Pencil | IDE 내 AI 디자인 캔버스 | 불필요 |

---

## 설치가 안 되시나요?

설치 중 문제가 발생하면 진단 도구를 실행하세요.

**Windows:**
```
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/diagnose.ps1 | iex"
```

**Mac/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/diagnose.sh | bash
```

설치 환경(Node.js, Docker, 권한 등)을 자동으로 점검하고 문제 원인을 알려줍니다.

---

## 폴더 구조

```
popup-claude/
├── installer/              # 모듈식 자동 설치 프로그램
│   ├── install.ps1         # Windows 메인 진입점
│   ├── install.sh          # Mac/Linux 메인 진입점
│   ├── diagnose.ps1        # Windows 설치 진단 도구
│   ├── diagnose.sh         # Mac/Linux 설치 진단 도구
│   ├── modules.json        # 모듈 목록
│   ├── claude-desktop/     # Claude Desktop 설치 스크립트
│   └── modules/            # 개별 모듈 (base, google, atlassian, notion, github, figma, pencil)
├── docs/                   # 설정 가이드 문서
├── google-workspace-mcp/   # Google MCP 소스 코드
├── .github/workflows/      # CI 테스트
└── README.md
```

> 랜딩페이지는 별도 레포지토리: https://github.com/popup-studio-ai/ai-driven-work-landing

---

## 문서

- [설치 시스템 아키텍처](installer/ARCHITECTURE.md)
- [Google MCP 관리자 설정 (Internal)](docs/SETUP_GOOGLE_INTERNAL_ADMIN.md)
- [Google MCP 관리자 설정 (External)](docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md)
- [Google MCP 개발자 가이드](google-workspace-mcp/SETUP.md)

---

## 도움이 필요하면

문제가 발생하면 [Issues](https://github.com/popup-jacob/popup-claude/issues)에 문의하세요.
