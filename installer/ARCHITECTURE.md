# AI-Driven Work Installer v2 - Architecture

## Overview

모듈화된 설치 시스템으로, 사용자가 랜딩페이지에서 원하는 기능을 선택하면
자동으로 명령어가 생성되고, 하나의 터미널 창에서 모든 설치가 순차적으로 진행됩니다.

---

## User Flow

```
┌─────────────────────────────────────────────────────┐
│  1. 랜딩페이지 방문                                   │
│     https://your-domain.github.io/ai-driven-work     │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  2. 원하는 기능 선택                                  │
│                                                     │
│     ✅ Claude Code + bkit (기본 - 항상 포함)          │
│     ☑️ Google Workspace                             │
│     ☑️ Atlassian (Jira + Confluence)                │
│     ☐ Slack                                         │
│     ☐ GitHub                                        │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  3. 명령어 자동 생성                                  │
│                                                     │
│  Windows:                                           │
│  ┌────────────────────────────────────────────────┐ │
│  │ & ([scriptblock]::Create((irm https://raw...   │ │
│  │ install.ps1))) -modules "google,atlassian"     │ │
│  └────────────────────────────────────────────────┘ │
│                                                     │
│  Mac/Linux:                                         │
│  ┌────────────────────────────────────────────────┐ │
│  │ curl -sSL https://raw.../install.sh | bash     │ │
│  │ -s -- --modules "google,atlassian"             │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  4. 터미널에서 실행 (하나의 창에서 전부 진행)           │
│                                                     │
│  PS> [명령어 붙여넣기]                               │
│                                                     │
│  ========================================           │
│    AI-Driven Work Installer                         │
│  ========================================           │
│                                                     │
│  [1/3] Installing base (Claude + bkit)...           │
│    ✓ Node.js installed                              │
│    ✓ Claude CLI installed                           │
│    ✓ bkit plugin installed                          │
│                                                     │
│  [2/3] Installing Google Workspace...               │
│    ...                                              │
│                                                     │
│  [3/3] Installing Atlassian...                      │
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
├── README.md                # 사용자 가이드
│
├── install.ps1              # Windows 메인 진입점
├── install.sh               # Mac/Linux 메인 진입점
│
├── modules/
│   ├── base.ps1             # 기본 설치 (Claude + bkit) - Windows
│   ├── base.sh              # 기본 설치 - Mac/Linux
│   │
│   ├── google.ps1           # Google Workspace 모듈 - Windows
│   ├── google.sh            # Google Workspace 모듈 - Mac/Linux
│   │
│   ├── atlassian/           # Atlassian (Jira+Confluence) 모듈
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│
└── web/
    └── index.html           # 랜딩페이지 (GitHub Pages용)
```

---

## How It Works

### 1. 명령어 실행 방식

**Windows (PowerShell):**
```powershell
# 스크립트 다운로드 + 실행 + 파라미터 전달
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/your-repo/main/install.ps1))) -modules "google,atlassian"
```

**Mac/Linux (Bash):**
```bash
# 스크립트 다운로드 + 실행 + 파라미터 전달
curl -sSL https://raw.githubusercontent.com/your-repo/main/install.sh | bash -s -- --modules "google,atlassian"
```

### 2. 메인 스크립트 (install.ps1) 동작

```powershell
param(
    [string]$modules = "",    # "google,atlassian,slack"
    [switch]$all
)

$baseUrl = "https://raw.githubusercontent.com/your-repo/main/modules"

# Step 1: 항상 기본 설치 실행
Write-Host "[1/N] Installing base (Claude + bkit)..." -ForegroundColor Cyan
irm "$baseUrl/base.ps1" | iex

# Step 2: 선택된 모듈만 순차 실행
if ($google) {
    Write-Host "[2/N] Installing Google Workspace..." -ForegroundColor Yellow
    irm "$baseUrl/google.ps1" | iex
}

if ($modules -match "atlassian") {
    Write-Host "[3/N] Installing Atlassian..." -ForegroundColor Yellow
    . "$baseUrl/modules/atlassian/install.ps1"
}

# ... 추가 모듈들

Write-Host "Installation Complete!" -ForegroundColor Green
```

### 3. 모듈 실행 원리

```
irm "$baseUrl/google.ps1" | iex
```

이 명령어는:
1. `irm` (Invoke-RestMethod) - google.ps1 **내용을 텍스트로 다운로드**
2. `|` (파이프) - 다운로드한 내용을 다음 명령어로 전달
3. `iex` (Invoke-Expression) - **현재 세션에서 코드 실행**

**새 창이 열리지 않음** - 모든 코드가 같은 PowerShell 세션에서 실행됩니다.

---

## Landing Page (JavaScript)

```javascript
function generateCommand() {
  const options = [];

  // 체크박스 상태 확인
  if (document.getElementById('google').checked) options.push('google');
  if (document.getElementById('atlassian').checked) options.push('atlassian');
  if (document.getElementById('slack').checked) options.push('slack');

  const moduleList = options.join(',');
  const baseUrl = 'https://raw.githubusercontent.com/your-repo/main';

  // Windows 명령어 생성
  const winCmd = `& ([scriptblock]::Create((irm ${baseUrl}/install.ps1))) -modules "${moduleList}"`;

  // Mac/Linux 명령어 생성
  const macCmd = `curl -sSL ${baseUrl}/install.sh | bash -s -- --modules "${moduleList}"`;

  // UI 업데이트
  document.getElementById('win-command').textContent = winCmd;
  document.getElementById('mac-command').textContent = macCmd;
}

// 체크박스 변경 시 실시간 업데이트
document.querySelectorAll('input[type="checkbox"]').forEach(cb => {
  cb.addEventListener('change', generateCommand);
});
```

---

## Module Types

### 1. Simple Modules (API Key만 필요)
- Slack, GitHub, Notion
- Claude Desktop Extensions에서 직접 설치 권장
- 우리 스크립트에서는 안내만 제공

### 2. Complex Modules (OAuth/복잡한 설정 필요)
- Google Workspace: gcloud CLI, 프로젝트 생성, API 활성화, OAuth 설정
- Atlassian: Jira/Confluence 계정 연동, API 토큰

우리 설치 스크립트는 **Complex Modules**에 집중합니다.

---

## Hosting Options

| 방법 | 스크립트 URL | 랜딩페이지 URL |
|------|-------------|---------------|
| **GitHub Raw + Pages** | `https://raw.githubusercontent.com/.../install.ps1` | `https://username.github.io/repo/` |
| **Vercel** | 별도 API 필요 | `https://your-app.vercel.app/` |
| **자체 서버** | `https://install.company.com/install.ps1` | `https://install.company.com/` |

**권장: GitHub Raw + GitHub Pages** (무료, 간단)

---

## Execution Flow Diagram

```
사용자 명령어 실행
        │
        ▼
┌───────────────────┐
│   install.ps1     │  ← GitHub에서 다운로드 & 실행
│   (메인 스크립트)   │
└───────────────────┘
        │
        ├── base.ps1 실행 ──────────────────┐
        │   (Claude + bkit 설치)            │
        │                                   │
        ├── google.ps1 실행 (선택 시) ───────┤  같은 터미널 창
        │   (Google Workspace 설정)         │
        │                                   │
        ├── atlassian 실행 (선택 시) ────────┤
        │   (Jira+Confluence 설정)          │
        │                                   │
        ▼                                   │
   설치 완료! ◄──────────────────────────────┘
```

---

## Known Issues & Version Pinning

### Claude Code 설치 방식 (2026-02-10)

현재 installer-v2는 Claude Code를 **Native 방식**으로 설치합니다. (npm은 deprecated)

| 항목 | 내용 |
|------|------|
| **Mac/Linux** | `curl -fsSL https://claude.ai/install.sh \| bash` |
| **Windows** | `irm https://claude.ai/install.ps1 \| iex` |
| **장점** | 자동 업데이트, Node.js 불필요 |

**Stable 버전 설치 (선택적):**

```bash
# Mac/Linux
curl -fsSL https://claude.ai/install.sh | bash -s stable

# Windows
& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable
```

---

## Next Steps

1. [ ] `install.ps1` 메인 스크립트 작성
2. [ ] `install.sh` 메인 스크립트 작성
3. [ ] `modules/base.ps1` 기본 설치 모듈 작성
4. [ ] `modules/google.ps1` Google 모듈 작성 (기존 코드 마이그레이션)
5. [x] `modules/atlassian/` Atlassian 모듈 작성
6. [ ] `web/index.html` 랜딩페이지 작성
7. [ ] GitHub Repository 생성 및 배포
