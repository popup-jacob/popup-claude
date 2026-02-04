# Design: Dynamic Module System

> **Feature**: dynamic-module-system
> **Created**: 2026-02-03
> **Status**: Design
> **Plan Reference**: `docs/01-plan/features/dynamic-module-system.plan.md`

---

## 1. 아키텍처 개요 (Architecture Overview)

```
┌─────────────────────────────────────────────────────────────────┐
│                        Landing Page                              │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  registry.json 로드 → 체크박스 동적 생성 → 명령어 생성    │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    install.ps1 / install.sh                      │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  -modules "google,atlassian" 파싱                             │   │
│   │       ↓                                                  │   │
│   │  registry.json에서 모듈 목록 확인                         │   │
│   │       ↓                                                  │   │
│   │  각 모듈 폴더의 install.ps1/install.sh 실행              │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        modules/                                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│   │  base/   │  │  google/ │  │atlassian/│  │  slack/  │  ...  │
│   │          │  │          │  │          │  │          │       │
│   │ module.  │  │ module.  │  │ module.  │  │ module.  │       │
│   │ json     │  │ json     │  │ json     │  │ json     │       │
│   │          │  │          │  │          │  │          │       │
│   │ install. │  │ install. │  │ install. │  │ install. │       │
│   │ ps1/sh   │  │ ps1/sh   │  │ ps1/sh   │  │ ps1/sh   │       │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 파일 구조 (File Structure)

```
final-installer-v2/
├── install.ps1                    # Windows 메인 (동적 로딩)
├── install.sh                     # Mac/Linux 메인 (동적 로딩)
├── registry.json                  # 모듈 레지스트리
│
├── modules/
│   ├── base/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   ├── google/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── atlassian/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── slack/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── notion/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   ├── install.sh
│   │   └── README.md
│   │
│   └── github/
│       ├── module.json
│       ├── install.ps1
│       ├── install.sh
│       └── README.md
│
├── web/
│   └── index.html                 # 랜딩페이지
│
├── docs/
│   └── CONTRIBUTING.md            # 기여 가이드
│
└── ARCHITECTURE.md
```

---

## 3. registry.json 스펙

```json
{
  "version": "1.0.0",
  "baseUrl": "https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer-v2",
  "modules": {
    "base": {
      "required": true,
      "order": 0
    },
    "google": {
      "required": false,
      "order": 1
    },
    "atlassian": {
      "required": false,
      "order": 2
    },
    "slack": {
      "required": false,
      "order": 3
    },
    "notion": {
      "required": false,
      "order": 4
    },
    "github": {
      "required": false,
      "order": 5
    }
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | 레지스트리 버전 |
| `baseUrl` | string | 원격 실행 시 기본 URL |
| `modules` | object | 모듈 목록 |
| `modules.{name}.required` | boolean | 필수 모듈 여부 (base는 true) |
| `modules.{name}.order` | number | 설치 순서 |

---

## 4. module.json 스펙

```json
{
  "name": "google",
  "displayName": "Google Workspace",
  "description": "Gmail, Calendar, Drive, Docs, Sheets, Slides access for Claude",
  "version": "1.0.0",
  "author": "popup-jacob",
  "icon": "google.svg",

  "type": "mcp",
  "complexity": "complex",

  "requirements": {
    "docker": true,
    "node": false,
    "adminSetup": true
  },

  "mcpConfig": {
    "serverName": "google-workspace",
    "command": "docker",
    "args": [
      "run", "-i", "--rm",
      "-v", "{configDir}:/app/.google-workspace",
      "ghcr.io/popup-jacob/google-workspace-mcp:latest"
    ]
  },

  "links": {
    "docs": "https://github.com/popup-jacob/google-workspace-mcp",
    "setup": "https://..."
  }
}
```

### 필드 설명

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | 모듈 ID (폴더명과 동일) |
| `displayName` | string | ✅ | 랜딩페이지 표시명 |
| `description` | string | ✅ | 모듈 설명 |
| `version` | string | ✅ | 모듈 버전 |
| `author` | string | ✅ | 작성자 |
| `icon` | string | ❌ | 아이콘 파일명 |
| `type` | string | ✅ | "mcp" \| "cli" \| "config" |
| `complexity` | string | ✅ | "simple" \| "moderate" \| "complex" |
| `requirements.docker` | boolean | ✅ | Docker 필요 여부 |
| `requirements.node` | boolean | ✅ | Node.js 필요 여부 |
| `requirements.adminSetup` | boolean | ✅ | 관리자 설정 필요 여부 |
| `mcpConfig.serverName` | string | ✅ | .mcp.json의 서버 이름 |
| `mcpConfig.command` | string | ✅ | 실행 명령어 |
| `mcpConfig.args` | array | ✅ | 명령어 인자 |
| `links.docs` | string | ❌ | 문서 URL |
| `links.setup` | string | ❌ | 설정 가이드 URL |

### complexity 레벨

| Level | Description | Example |
|-------|-------------|---------|
| `simple` | API 키만 입력 | Notion, Slack |
| `moderate` | CLI 설치 + 로그인 | GitHub (gh CLI) |
| `complex` | OAuth + 프로젝트 설정 | Google Workspace |

### mcpConfig.args 변수

| Variable | Replaced With |
|----------|---------------|
| `{configDir}` | 사용자 설정 디렉토리 (~/.{module-name}) |
| `{homeDir}` | 사용자 홈 디렉토리 |

---

## 5. install.ps1 (메인) 상세 설계

### 5.1 파라미터

```powershell
param(
    [string]$modules = "",       # 콤마로 구분된 모듈 목록
    [switch]$all,                # 모든 모듈 설치
    [switch]$skipBase,           # base 모듈 스킵
    [switch]$list                # 사용 가능한 모듈 목록 표시
)
```

### 5.2 실행 흐름

```
1. 파라미터 파싱
   └─ -modules "google,atlassian" → ["google", "jira"]
   └─ -all → registry.json의 모든 모듈
   └─ -list → 모듈 목록 출력 후 종료

2. registry.json 로드
   └─ 로컬: $ScriptDir/registry.json
   └─ 원격: $BaseUrl/registry.json

3. Smart Status Check (기존 유지)
   └─ 설치 상태 표시
   └─ Docker 실행 확인
   └─ skipBase 자동 제안

4. 모듈 순서 정렬
   └─ registry.modules.{name}.order 기준

5. 각 모듈 실행
   └─ base (skipBase 아니면)
   └─ 선택된 모듈들 순차 실행

6. 완료 요약
```

### 5.3 모듈 실행 함수

```powershell
function Invoke-Module {
    param(
        [string]$ModuleName,
        [int]$Step,
        [int]$Total
    )

    # 1. module.json 로드
    if ($UseLocal) {
        $moduleJson = Get-Content "$ScriptDir/modules/$ModuleName/module.json" | ConvertFrom-Json
    } else {
        $moduleJson = irm "$BaseUrl/modules/$ModuleName/module.json"
    }

    # 2. 헤더 출력
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  [$Step/$Total] $($moduleJson.displayName)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $($moduleJson.description)" -ForegroundColor Gray
    Write-Host ""

    # 3. 요구사항 체크
    if ($moduleJson.requirements.docker -and -not $DockerRunning) {
        throw "Docker is required for $ModuleName"
    }

    # 4. install.ps1 실행
    if ($UseLocal) {
        . "$ScriptDir/modules/$ModuleName/install.ps1"
    } else {
        irm "$BaseUrl/modules/$ModuleName/install.ps1" | iex
    }
}
```

---

## 6. install.sh (메인) 상세 설계

### 6.1 파라미터

```bash
# Usage: ./install.sh --modules "google,atlassian"
#        ./install.sh --all
#        ./install.sh --list

MODULES=""
INSTALL_ALL=false
SKIP_BASE=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --modules) MODULES="$2"; shift 2 ;;
        --all) INSTALL_ALL=true; shift ;;
        --skip-base) SKIP_BASE=true; shift ;;
        --list) LIST_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done
```

### 6.2 모듈 실행 함수

```bash
run_module() {
    local module_name=$1
    local step=$2
    local total=$3

    # 1. module.json 로드 (Node.js 사용)
    if [ "$USE_LOCAL" = true ]; then
        local module_json=$(cat "$SCRIPT_DIR/modules/$module_name/module.json")
    else
        local module_json=$(curl -sSL "$BASE_URL/modules/$module_name/module.json")
    fi

    local display_name=$(echo "$module_json" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).displayName)")
    local description=$(echo "$module_json" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).description)")

    # 2. 헤더 출력
    echo ""
    echo "========================================"
    echo -e "${CYAN}  [$step/$total] $display_name${NC}"
    echo "========================================"
    echo -e "  ${GRAY}$description${NC}"
    echo ""

    # 3. install.sh 실행
    if [ "$USE_LOCAL" = true ]; then
        source "$SCRIPT_DIR/modules/$module_name/install.sh"
    else
        curl -sSL "$BASE_URL/modules/$module_name/install.sh" | bash
    fi
}
```

---

## 7. 모듈별 상세 설계

### 7.1 base 모듈

| File | Description |
|------|-------------|
| `module.json` | Node.js, Git, VS Code, Docker, Claude CLI, bkit |
| `install.ps1` | 기존 base.ps1 내용 |
| `install.sh` | 기존 base.sh 내용 |

### 7.2 google 모듈

| File | Description |
|------|-------------|
| `module.json` | Google Workspace MCP 설정 |
| `install.ps1` | 기존 google.ps1 내용 |
| `install.sh` | 기존 google.sh 내용 |
| `README.md` | Admin/Employee 설정 가이드 |

### 7.3 atlassian 모듈

| File | Description |
|------|-------------|
| `module.json` | Atlassian (Jira+Confluence) MCP 설정 |
| `install.ps1` | Atlassian 설치 스크립트 |
| `install.sh` | Mac/Linux 버전 |
| `README.md` | Rovo vs Docker 옵션 설명 |

### 7.4 slack 모듈 (⚠️ 테스트 필요)

```json
{
  "name": "slack",
  "displayName": "Slack",
  "description": "Send messages, read channels, manage conversations",
  "version": "1.0.0",
  "type": "mcp",
  "complexity": "simple",
  "requirements": {
    "docker": false,
    "node": true,
    "adminSetup": false
  },
  "mcpConfig": {
    "serverName": "slack",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-slack"],
    "env": {
      "SLACK_BOT_TOKEN": "{botToken}",
      "SLACK_TEAM_ID": "{teamId}"
    }
  }
}
```

**설치 흐름:**
1. Slack Bot Token 안내 (https://api.slack.com/apps)
2. Bot Token 입력 받기 (xoxb-...)
3. Team ID 입력 받기 (T로 시작)
4. 환경변수로 .mcp.json 설정

**구현 파일:**
- `modules/slack/module.json` ✅
- `modules/slack/install.ps1` ✅
- `modules/slack/install.sh` ✅

### 7.5 notion 모듈 (⚠️ 테스트 필요)

```json
{
  "name": "notion",
  "displayName": "Notion",
  "description": "Read and search Notion pages and databases",
  "version": "1.0.0",
  "type": "mcp",
  "complexity": "simple",
  "requirements": {
    "docker": false,
    "node": true,
    "adminSetup": false
  },
  "mcpConfig": {
    "serverName": "notion",
    "command": "npx",
    "args": ["-y", "@notionhq/notion-mcp-server"],
    "env": {
      "NOTION_TOKEN": "{apiToken}"
    }
  }
}
```

**설치 흐름:**
1. Notion Integration Token 안내 (https://www.notion.so/my-integrations)
2. Internal Integration 생성 안내
3. Token 입력 받기 (secret_...)
4. 페이지에 Integration 연결 안내
5. 환경변수로 .mcp.json 설정

**구현 파일:**
- `modules/notion/module.json` ✅
- `modules/notion/install.ps1` ✅
- `modules/notion/install.sh` ✅

### 7.6 github 모듈 (⚠️ 테스트 필요)

```json
{
  "name": "github",
  "displayName": "GitHub CLI",
  "description": "Install and configure GitHub CLI (gh) for repository access",
  "version": "1.0.0",
  "type": "cli",
  "complexity": "moderate",
  "requirements": {
    "docker": false,
    "node": false,
    "adminSetup": false
  },
  "mcpConfig": null
}
```

**설치 흐름:**
1. gh CLI 설치 확인/설치 (winget/brew)
2. `gh auth login --web` 실행
3. 브라우저에서 GitHub 인증
4. .mcp.json 설정 불필요 (Claude가 Bash에서 gh CLI 직접 사용)

**구현 파일:**
- `modules/github/module.json` ✅
- `modules/github/install.ps1` ✅
- `modules/github/install.sh` ✅

### 7.7 figma 모듈 (⚠️ 테스트 필요)

```json
{
  "name": "figma",
  "displayName": "Figma",
  "description": "Read Figma files, inspect designs, extract design tokens",
  "version": "1.0.0",
  "type": "mcp",
  "complexity": "simple",
  "requirements": {
    "docker": false,
    "node": true,
    "adminSetup": false
  },
  "mcpConfig": {
    "serverName": "figma",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-figma"],
    "env": {
      "FIGMA_PERSONAL_ACCESS_TOKEN": "{accessToken}"
    }
  }
}
```

**설치 흐름:**
1. Figma Personal Access Token 안내 (https://www.figma.com/developers/api#access-tokens)
2. Token 입력 받기
3. 환경변수로 .mcp.json 설정

**구현 파일:**
- `modules/figma/module.json` ✅
- `modules/figma/install.ps1` ✅
- `modules/figma/install.sh` ✅

---

## 8. 랜딩페이지 (web/index.html) 설계

### 8.1 동적 모듈 로딩

```javascript
async function loadModules() {
    // registry.json 로드
    const registry = await fetch('registry.json').then(r => r.json());

    // 각 모듈의 module.json 로드
    const modules = [];
    for (const [name, config] of Object.entries(registry.modules)) {
        if (name === 'base') continue; // base는 항상 포함

        const moduleJson = await fetch(`modules/${name}/module.json`).then(r => r.json());
        modules.push({ ...moduleJson, ...config });
    }

    // order 순으로 정렬
    modules.sort((a, b) => a.order - b.order);

    return modules;
}
```

### 8.2 체크박스 동적 생성

```javascript
function renderModules(modules) {
    const container = document.getElementById('module-list');

    modules.forEach(module => {
        const html = `
            <label class="module-item">
                <input type="checkbox"
                       name="module"
                       value="${module.name}"
                       data-complexity="${module.complexity}">
                <div class="module-info">
                    <span class="module-name">${module.displayName}</span>
                    <span class="module-badge ${module.complexity}">${module.complexity}</span>
                    <p class="module-desc">${module.description}</p>
                </div>
            </label>
        `;
        container.innerHTML += html;
    });
}
```

### 8.3 명령어 생성

```javascript
function generateCommand() {
    const selected = [...document.querySelectorAll('input[name="module"]:checked')]
        .map(cb => cb.value);

    if (selected.length === 0) {
        // base만 설치
        return {
            windows: `& ([scriptblock]::Create((irm ${BASE_URL}/install.ps1)))`,
            mac: `curl -sSL ${BASE_URL}/install.sh | bash`
        };
    }

    const moduleList = selected.join(',');

    return {
        windows: `& ([scriptblock]::Create((irm ${BASE_URL}/install.ps1))) -modules "${moduleList}"`,
        mac: `curl -sSL ${BASE_URL}/install.sh | bash -s -- --modules "${moduleList}"`
    };
}
```

---

## 9. 커뮤니티 기여 가이드 (CONTRIBUTING.md)

### 새 모듈 기여 방법

```markdown
# 모듈 기여 가이드

## 1. 폴더 생성

modules/{your-module-name}/
├── module.json      # 필수
├── install.ps1      # 필수 (Windows)
├── install.sh       # 필수 (Mac/Linux)
└── README.md        # 권장


## 2. module.json 작성

module.json 스펙을 참고하여 작성합니다.
- name: 폴더명과 동일해야 함
- complexity: simple/moderate/complex 중 선택


## 3. 설치 스크립트 작성

### 필수 규칙
- 에러 발생 시 적절한 메시지 출력
- 사용자 입력은 항상 < /dev/tty (Bash)
- 기존 .mcp.json 내용 보존 (병합)


## 4. PR 제출

- 로컬 테스트 완료 후 PR 제출
- PR 템플릿 작성
- 메인테이너 리뷰 후 병합


## 5. 검증 체크리스트

- [ ] module.json 스펙 준수
- [ ] install.ps1 / install.sh 둘 다 존재
- [ ] Windows에서 테스트 통과
- [ ] Mac/Linux에서 테스트 통과
- [ ] README.md 존재
- [ ] 민감 정보 하드코딩 없음
```

---

## 10. 구현 순서

| Step | Task | Files |
|------|------|-------|
| 1 | registry.json 생성 | `registry.json` |
| 2 | 기존 모듈 폴더로 이동 | `modules/base/`, `modules/google/`, `modules/atlassian/` | ✅ 완료 |
| 3 | 각 모듈에 module.json 추가 | `modules/*/module.json` | ✅ 완료 (7개) |
| 4 | install.ps1 동적 로딩 구현 | `install.ps1` | ✅ 완료 |
| 5 | install.sh 동적 로딩 구현 | `install.sh` | ✅ 완료 |
| 6 | slack 모듈 추가 | `modules/slack/*` | ⚠️ 테스트 필요 |
| 7 | notion 모듈 추가 | `modules/notion/*` | ⚠️ 테스트 필요 |
| 8 | github 모듈 추가 | `modules/github/*` | ⚠️ 테스트 필요 |
| 9 | figma 모듈 추가 | `modules/figma/*` | ⚠️ 테스트 필요 |
| 10 | registry.json 생성 | `registry.json` | ❌ 미완료 |
| 11 | 랜딩페이지 구현 | `web/index.html` | ❌ 미완료 (adw-landing-page 연동 예정) |
| 12 | CONTRIBUTING.md 작성 | `docs/CONTRIBUTING.md` | ❌ 미완료 |
| 13 | 각 모듈 README.md 작성 | `modules/*/README.md` | ❌ 미완료 (7개)

---

## 11. 테스트 계획

### 11.1 로컬 테스트

```powershell
# Windows
.\install.ps1 -list
.\install.ps1 -modules "google"
.\install.ps1 -modules "google,atlassian"
.\install.ps1 -all
.\install.ps1 -modules "slack" -skipBase
```

```bash
# Mac/Linux
./install.sh --list
./install.sh --modules "google"
./install.sh --modules "google,atlassian"
./install.sh --all
./install.sh --modules "slack" --skip-base
```

### 11.2 원격 테스트

```powershell
# Windows
& ([scriptblock]::Create((irm $BASE_URL/install.ps1))) -modules "google,atlassian"
```

```bash
# Mac/Linux
curl -sSL $BASE_URL/install.sh | bash -s -- --modules "google,atlassian"
```
