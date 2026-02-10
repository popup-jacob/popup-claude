# AI-Driven Work Installer v2 - Architecture

## Overview

모듈화된 설치 시스템으로, 사용자가 랜딩페이지에서 원하는 기능을 선택하면
자동으로 명령어가 생성되고, 하나의 터미널 창에서 모든 설치가 순차적으로 진행됩니다.

---

## User Flow

```
┌─────────────────────────────────────────────────────┐
│  1. 랜딩페이지 방문                                   │
│     https://ai-driven-work.vercel.app               │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  2. 원하는 기능 선택                                  │
│                                                     │
│     ✅ Claude Code + bkit (기본 - 항상 포함)          │
│     ☑️ Google Workspace (Docker 필요)               │
│     ☑️ Atlassian (Jira + Confluence, Docker 필요)   │
│     ☐ Notion                                        │
│     ☐ GitHub                                        │
│     ☐ Figma                                         │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  3. 명령어 자동 생성                                  │
│                                                     │
│  Windows:                                           │
│  ┌────────────────────────────────────────────────┐ │
│  │ powershell -ep bypass -c "irm .../install.ps1  │ │
│  │ | iex"  (모듈 선택 시 환경변수로 전달)            │ │
│  └────────────────────────────────────────────────┘ │
│                                                     │
│  Mac/Linux:                                         │
│  ┌────────────────────────────────────────────────┐ │
│  │ curl -fsSL .../install.sh | MODULES="..." bash │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  4. 터미널에서 실행 (하나의 창에서 전부 진행)           │
│                                                     │
│  PS> [명령어 붙여넣기]                               │
│                                                     │
│  ========================================           │
│    AI-Driven Work Installer v2                      │
│  ========================================           │
│                                                     │
│  [1/3] Installing base (Claude + bkit)...           │
│    ✓ Node.js installed                              │
│    ✓ Claude CLI installed (native)                  │
│    ✓ bkit plugin installed                          │
│                                                     │
│  [2/3] Installing Google Workspace...               │
│    ...                                              │
│                                                     │
│  [3/3] Installing Notion...                         │
│    ...                                              │
│                                                     │
│  ========================================           │
│    Installation Complete!                           │
│  ========================================           │
└─────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
adw/installer/
├── ARCHITECTURE.md          # 이 문서
├── install.ps1              # Windows 메인 진입점
├── install.sh               # Mac/Linux 메인 진입점
├── modules.json             # 모듈 목록 (원격 실행 시 사용)
│
├── modules/
│   ├── base/                # 기본 설치 (Claude + bkit)
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   ├── google/              # Google Workspace (Docker 필요)
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   ├── atlassian/           # Atlassian - Jira + Confluence (Docker 필요)
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   ├── notion/              # Notion 연동
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   ├── github/              # GitHub 연동
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   └── figma/               # Figma 연동
│       ├── module.json
│       ├── install.ps1
│       └── install.sh
│
└── (landing-page는 별도 repo)
    # https://github.com/popup-studio-ai/ai-driven-work-landing
```

---

## How It Works

### 1. 명령어 실행 방식

**Windows (PowerShell):**
```powershell
# 방법 1: 환경변수로 모듈 전달 (Win+R에서 사용)
powershell -ep bypass -c "$env:MODULES='google,notion'; irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1 | iex"

# 방법 2: 파라미터로 전달 (PowerShell 에서 사용)
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1))) -modules 'google,notion'
```

**Mac/Linux (Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh | MODULES="google,notion" bash
```

### 2. 메인 스크립트 동작

메인 스크립트 (`install.ps1` / `install.sh`)는:
1. `modules/` 폴더를 스캔하여 사용 가능한 모듈 목록 로드
2. 선택된 모듈 유효성 검증
3. Docker 필요 여부 확인 (google, atlassian 모듈)
4. 관리자 권한 요청 (Windows) / sudo 확인 (Mac)
5. base 모듈 → 선택된 모듈 순서대로 실행

### 3. 모듈 실행 원리

```
irm "$BaseUrl/modules/$ModuleName/install.ps1" | iex
```

이 명령어는:
1. `irm` (Invoke-RestMethod) - install.ps1 **내용을 텍스트로 다운로드**
2. `|` (파이프) - 다운로드한 내용을 다음 명령어로 전달
3. `iex` (Invoke-Expression) - **현재 세션에서 코드 실행**

**새 창이 열리지 않음** - 모든 코드가 같은 PowerShell 세션에서 실행됩니다.

### 4. Claude Code 설치 방식

Claude Code는 **Native 방식**으로 설치됩니다. (npm은 deprecated)

| 플랫폼 | 명령어 |
|--------|--------|
| **Mac/Linux** | `curl -fsSL https://claude.ai/install.sh \| bash` |
| **Windows** | `irm https://claude.ai/install.ps1 \| iex` |

Windows에서는 native install 후 `~/.local/bin`이 PATH에 추가됩니다.

---

## Landing Page

랜딩페이지는 **별도 레포지토리**로 관리됩니다:
- Repo: https://github.com/popup-studio-ai/ai-driven-work-landing
- 배포: Vercel
- 기술: Next.js + TypeScript + Tailwind CSS

사용자가 모듈을 선택하면 React 컴포넌트에서 설치 명령어를 동적으로 생성합니다.
Docker가 필요한 모듈 선택 시 2단계 설치 명령어가 표시됩니다.

---

## Module Types

### 1. Docker 기반 MCP 모듈
- Google Workspace, Atlassian
- Docker Desktop 필요 (설치 시 자동 감지)
- Docker 컨테이너로 MCP 서버 실행

### 2. Remote MCP / CLI 모듈
- Notion, GitHub, Figma
- Docker 불필요
- `claude mcp add` 또는 CLI 도구 설치

---

## Hosting

| 항목 | 호스팅 | URL |
|------|--------|-----|
| **설치 스크립트** | GitHub Raw | `https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/...` |
| **랜딩페이지** | Vercel | `https://ai-driven-work.vercel.app` |

---

## Execution Flow Diagram

```
사용자 명령어 실행
        │
        ▼
┌───────────────────┐
│   install.ps1     │  ← GitHub Raw에서 다운로드 & 실행
│   (메인 스크립트)   │
└───────────────────┘
        │
        ├── modules/base/ 실행 ─────────────┐
        │   (Node.js, Git, VS Code,         │
        │    Claude CLI, bkit 설치)          │
        │                                   │
        ├── modules/google/ (선택 시) ───────┤  같은 터미널 창
        │   (Docker + Google MCP 설정)       │
        │                                   │
        ├── modules/notion/ (선택 시) ───────┤
        │   (Notion MCP 설정)               │
        │                                   │
        ├── modules/github/ (선택 시) ───────┤
        │   (GitHub CLI 설치)               │
        │                                   │
        ├── modules/figma/ (선택 시) ────────┤
        │   (Figma MCP 설정)                │
        │                                   │
        ▼                                   │
   설치 완료! ◄──────────────────────────────┘
```

---

## CI/CD

GitHub Actions로 Windows/macOS에서 설치 스크립트를 테스트합니다.

- Workflow: `.github/workflows/test-installer.yml`
- 트리거: `workflow_dispatch` (수동)
- 테스트 OS: Windows, macOS
