# Gemini CLI Support — Design Document

> **Feature**: gemini-cli-support
> **Plan**: `docs/01-plan/features/gemini-cli-support.plan.md` (v2)
> **Date**: 2026-02-22
> **Status**: Draft

---

## 1. 핵심 설계 원칙

**하나의 변수 `$CLI_TYPE`으로 모든 분기를 제어한다.**

- `CLI_TYPE=claude` (기본값) → 기존 동작 100% 유지
- `CLI_TYPE=gemini` → Gemini 플랫폼에 맞게 전환
- 메인 인스톨러가 `CLI_TYPE`을 export → 모든 하위 모듈이 이 변수를 참조

---

## 2. CLI_TYPE별 값 매핑 테이블

모든 분기에서 참조할 중앙 매핑:

| 키 | `claude` | `gemini` |
|----|----------|----------|
| CLI 명령어 | `claude` | `gemini` |
| CLI 설치 (Mac/Linux) | `curl -fsSL https://claude.ai/install.sh \| bash` | `npm install -g @google/gemini-cli` |
| CLI 설치 (Windows) | `irm https://claude.ai/install.ps1 \| iex` | `npm install -g @google/gemini-cli` |
| IDE 설치 (Windows) | `winget install Microsoft.VisualStudioCode` | `winget install Microsoft.VisualStudioCode` |
| IDE 설치 (Mac) | `brew install --cask visual-studio-code` | `brew install --cask visual-studio-code` |
| IDE 설치 (Linux apt) | `sudo snap install code --classic` | `sudo snap install code --classic` |
| VS Code 확장 | `code --install-extension anthropic.claude-code` | `code --install-extension Google.gemini-cli-vscode-ide-companion` |
| 플러그인 설치 | `claude plugin marketplace add popup-studio-ai/bkit-claude-code && claude plugin install bkit@bkit-marketplace` | `gemini extensions install https://github.com/popup-studio-ai/bkit-gemini.git` |
| MCP 설정 파일 | `~/.claude/mcp.json` | `~/.gemini/settings.json` |
| MCP 추가 (http) | `claude mcp add --transport http {name} {url}` | `gemini mcp add --transport http {name} {url}` |
| MCP 추가 (sse) | `claude mcp add --transport sse {name} {url}` | `gemini mcp add --transport sse {name} {url}` |
| MCP 목록 | `claude mcp list` | `gemini mcp list` |

---

## 3. 파일별 상세 변경 설계

### 3.1 installer/install.sh (Mac/Linux 메인)

**FR-01, FR-02, FR-03**

```bash
# 추가할 파라미터 파싱 (기존 while 루프에 추가)
--cli)
    CLI_TYPE="$2"
    shift 2
    ;;

# 환경변수 읽기 (파라미터 파싱 후)
CLI_TYPE="${CLI_TYPE:-claude}"

# 유효성 검사
if [[ "$CLI_TYPE" != "claude" && "$CLI_TYPE" != "gemini" ]]; then
    echo -e "${RED}Invalid --cli value: $CLI_TYPE (use 'claude' or 'gemini')${NC}"
    exit 1
fi

# export (모든 하위 모듈에 전달)
export CLI_TYPE
```

### 3.2 installer/install.ps1 (Windows 메인)

**FR-01, FR-02, FR-03**

```powershell
# param 블록에 추가
param(
    [string]$cli = "",          # CLI type: claude or gemini
    # ... 기존 파라미터 ...
)

# 환경변수 지원
if (-not $cli -and $env:CLI_TYPE) {
    $cli = $env:CLI_TYPE
}
if (-not $cli) { $cli = "claude" }

# 유효성 검사
if ($cli -ne "claude" -and $cli -ne "gemini") {
    Write-Host "Invalid -cli value: $cli (use 'claude' or 'gemini')" -ForegroundColor Red
    exit 1
}

# 하위 모듈에 전달
$env:CLI_TYPE = $cli
```

### 3.3 modules/base/install.sh (Mac/Linux base)

**FR-04, FR-05, FR-06, FR-07**

#### IDE 설치 (공통 VS Code)

```bash
# ============================================
# 4. VS Code
# ============================================
echo ""
echo -e "${YELLOW}[4/7] Checking VS Code...${NC}"
# ... VS Code 설치 로직 (Claude/Gemini 공통) ...

# Install IDE extension based on CLI type
if command -v code > /dev/null 2>&1; then
    if [ "$CLI_TYPE" = "gemini" ]; then
        code --install-extension Google.gemini-cli-vscode-ide-companion --force
    else
        code --install-extension anthropic.claude-code --force
    fi
fi
```

#### CLI 설치 분기 (기존 "6. Claude Code CLI" 섹션 교체)

```bash
# ============================================
# 6. AI CLI
# ============================================
echo ""
if [ "$CLI_TYPE" = "gemini" ]; then
    echo -e "${YELLOW}[6/7] Checking Gemini CLI...${NC}"
    if ! command -v gemini > /dev/null 2>&1; then
        echo -e "  ${GRAY}Installing Gemini CLI...${NC}"
        npm install -g @google/gemini-cli
    fi
    if command -v gemini > /dev/null 2>&1; then
        GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}OK - $GEMINI_VERSION${NC}"
    else
        echo -e "  ${YELLOW}Installed (restart terminal to use)${NC}"
    fi
else
    echo -e "${YELLOW}[6/7] Checking Claude Code CLI...${NC}"
    # ... 기존 Claude CLI 설치 로직 유지 ...
fi
```

#### 플러그인 분기 (기존 "7. bkit Plugin" 섹션 교체)

```bash
# ============================================
# 7. bkit Plugin
# ============================================
echo ""
if [ "$CLI_TYPE" = "gemini" ]; then
    echo -e "${YELLOW}[7/7] Installing bkit Plugin (Gemini)...${NC}"
    gemini extensions install https://github.com/popup-studio-ai/bkit-gemini.git 2>/dev/null || true
    echo -e "  ${GREEN}OK${NC}"
else
    echo -e "${YELLOW}[7/7] Installing bkit Plugin...${NC}"
    claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>/dev/null || true
    claude plugin install bkit@bkit-marketplace 2>/dev/null || true
    # ... 기존 검증 로직 ...
fi
```

### 3.4 modules/base/install.ps1 (Windows base)

**FR-04, FR-05, FR-06, FR-07** — install.sh와 동일한 패턴을 PowerShell로 구현

#### IDE 설치 (공통 VS Code)

```powershell
# 4. VS Code (Claude/Gemini 공통)
Write-Host "[4/8] Checking VS Code..." -ForegroundColor Yellow
# ... VS Code 설치 로직 ...

# Install IDE extension based on CLI type
if ($env:CLI_TYPE -eq "gemini") {
    Install-VSCodeExtension -ExtensionId "Google.gemini-cli-vscode-ide-companion" -DisplayName "Gemini CLI Companion" -Command $codeCmd
} else {
    Install-VSCodeExtension -ExtensionId "anthropic.claude-code" -DisplayName "Claude Code" -Command $codeCmd
}
```

#### CLI 설치 분기

```powershell
if ($env:CLI_TYPE -eq "gemini") {
    Write-Host "[7/8] Checking Gemini CLI..." -ForegroundColor Yellow
    Refresh-Path
    if (-not (Test-CommandExists "gemini")) {
        Write-Host "  Installing Gemini CLI..." -ForegroundColor Gray
        npm install -g @google/gemini-cli
        Refresh-Path
    }
    if (Test-CommandExists "gemini") {
        $geminiVersion = gemini --version 2>$null
        Write-Host "  OK - $geminiVersion" -ForegroundColor Green
    } else {
        Write-Host "  Installed (restart terminal to use)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[7/8] Checking Claude Code CLI..." -ForegroundColor Yellow
    # ... 기존 Claude CLI 설치 로직 유지 ...
}
```

#### 플러그인 분기

```powershell
if ($env:CLI_TYPE -eq "gemini") {
    Write-Host "[8/8] Installing bkit Plugin (Gemini)..." -ForegroundColor Yellow
    gemini extensions install https://github.com/popup-studio-ai/bkit-gemini.git 2>$null
    Write-Host "  OK" -ForegroundColor Green
} else {
    Write-Host "[8/8] Installing bkit Plugin..." -ForegroundColor Yellow
    # ... 기존 bkit 설치 로직 유지 ...
}
```

### 3.5 modules/shared/mcp-config.sh

**FR-12** — MCP 설정 파일 경로 분기

```bash
# mcp_get_config_path() 함수 수정
mcp_get_config_path() {
    if [ "$CLI_TYPE" = "gemini" ]; then
        local config_path="$HOME/.gemini/settings.json"
    else
        local config_path="$HOME/.claude/mcp.json"
    fi
    local legacy_path="$HOME/.mcp.json"

    # Migrate legacy config if needed (claude만)
    if [ "$CLI_TYPE" != "gemini" ] && [ -f "$legacy_path" ] && [ ! -f "$config_path" ]; then
        mkdir -p "$(dirname "$config_path")"
        cp "$legacy_path" "$config_path"
        echo -e "  ${YELLOW}Migrated MCP config from $legacy_path to $config_path${NC}"
    fi

    echo "$config_path"
}
```

**참고**: `mcp_add_docker_server()`와 `mcp_add_stdio_server()`는 JSON 구조(`mcpServers`)가 동일하므로 수정 불필요. 경로만 `mcp_get_config_path()`에서 분기되면 자동으로 올바른 파일에 기록됨.

### 3.6 modules/shared/oauth-helper.sh

**FR-13**

```bash
# 기존: claude mcp list > /dev/null 2>&1
# 변경:
if [ "$CLI_TYPE" = "gemini" ]; then
    gemini mcp list > /dev/null 2>&1
else
    claude mcp list > /dev/null 2>&1
fi

# 기존: "Make sure 'claude mcp add' was run first."
# 변경:
echo -e "  ${YELLOW}Make sure '${CLI_TYPE:-claude} mcp add' was run first.${NC}"
```

### 3.7 modules/shared/oauth-helper.ps1

**FR-13**

```powershell
# 기존: claude mcp list 2>&1 | Out-Null
# 변경:
if ($env:CLI_TYPE -eq "gemini") {
    gemini mcp list 2>&1 | Out-Null
} else {
    claude mcp list 2>&1 | Out-Null
}
```

### 3.8 modules/notion/install.sh

**FR-08**

```bash
# CLI 체크 (기존 claude → 분기)
CLI_CMD="${CLI_TYPE:-claude}"
echo -e "${YELLOW}[Check] $CLI_CMD CLI...${NC}"
if ! command -v "$CLI_CMD" > /dev/null 2>&1; then
    echo -e "  ${RED}$CLI_CMD CLI is required. Please install base module first.${NC}"
    exit 1
fi
echo -e "  ${GREEN}OK${NC}"

# MCP 등록 (기존 claude mcp add → 분기)
echo -e "${YELLOW}[Config] Registering Notion Remote MCP server...${NC}"
$CLI_CMD mcp add --transport http notion https://mcp.notion.com/mcp
```

### 3.9 modules/notion/install.ps1

**FR-08**

```powershell
$cliCmd = if ($env:CLI_TYPE -eq "gemini") { "gemini" } else { "claude" }

Write-Host "[Check] $cliCmd CLI..." -ForegroundColor Yellow
if (-not (Test-CommandExists $cliCmd)) {
    Write-Host "  $cliCmd CLI is required. Please install base module first." -ForegroundColor Red
    throw "$cliCmd CLI not found"
}

# MCP 등록
& $cliCmd mcp add --transport http notion https://mcp.notion.com/mcp
```

### 3.10 modules/figma/install.sh

**FR-09** — Notion과 동일한 패턴

```bash
CLI_CMD="${CLI_TYPE:-claude}"

# CLI 체크
if ! command -v "$CLI_CMD" > /dev/null 2>&1; then
    echo -e "  ${RED}$CLI_CMD CLI is required. Please install base module first.${NC}"
    exit 1
fi

# MCP 등록
$CLI_CMD mcp add --transport http figma https://mcp.figma.com/mcp
```

### 3.11 modules/figma/install.ps1

**FR-09** — Notion ps1과 동일한 패턴

### 3.12 modules/atlassian/install.sh

**FR-10**

```bash
# Rovo 모드 MCP 등록 (기존 claude mcp add → 분기)
CLI_CMD="${CLI_TYPE:-claude}"
$CLI_CMD mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse
```

Docker 모드는 `mcp_add_docker_server()` 사용 → `mcp-config.sh`의 경로 분기로 자동 처리됨.

### 3.13 modules/atlassian/install.ps1

**FR-10** — 동일 패턴

```powershell
$cliCmd = if ($env:CLI_TYPE -eq "gemini") { "gemini" } else { "claude" }
& $cliCmd mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse
```

### 3.14 modules/google/install.sh, install.ps1

**FR-11** — `mcp_add_docker_server()` 사용하므로 직접 수정 불필요.
`mcp-config.sh`의 경로 분기가 적용되어 자동으로 올바른 설정 파일에 기록됨.

### 3.15 modules/pencil/install.sh, install.ps1

**Gemini 선택 시에도 Pencil 정상 지원**

Gemini도 VS Code를 사용하므로 스킵 처리 없이 Claude와 동일하게 Pencil을 설치한다.
(`highagency.pencildev` 확장을 `code --install-extension`으로 설치)

### 3.16 README.md

```markdown
### Windows (Gemini)
powershell -ep bypass -c "$env:CLI_TYPE='gemini'; irm .../install.ps1 | iex"

### Mac/Linux (Gemini)
curl -fsSL .../install.sh | CLI_TYPE=gemini bash
```

---

## 4. 구현 순서

| 순서 | 파일 | 의존성 |
|:----:|------|--------|
| 1 | `install.sh` — `--cli` 파라미터 + export | 없음 |
| 2 | `install.ps1` — `-cli` 파라미터 + export | 없음 |
| 3 | `shared/mcp-config.sh` — 경로 분기 | 없음 |
| 4 | `shared/oauth-helper.sh` — 명령어 분기 | 없음 |
| 5 | `shared/oauth-helper.ps1` — 명령어 분기 | 없음 |
| 6 | `base/install.sh` — IDE + CLI + 플러그인 분기 | 1번 완료 후 |
| 7 | `base/install.ps1` — IDE + CLI + 플러그인 분기 | 2번 완료 후 |
| 8 | `notion/install.sh` + `install.ps1` | 3번 완료 후 |
| 9 | `figma/install.sh` + `install.ps1` | 3번 완료 후 |
| 10 | `atlassian/install.sh` + `install.ps1` | 3번 완료 후 |
| 11 | `pencil/install.sh` + `install.ps1` | 없음 |
| 12 | `README.md` | 전체 완료 후 |

---

## 5. 테스트 시나리오

| # | 시나리오 | 기대 결과 |
|---|---------|----------|
| T-01 | `./install.sh` (파라미터 없음) | Claude 설치 (하위호환) |
| T-02 | `./install.sh --cli claude` | Claude 설치 |
| T-03 | `./install.sh --cli gemini` | Antigravity + Gemini CLI + bkit-gemini |
| T-04 | `./install.sh --cli invalid` | 에러 메시지 + 종료 |
| T-05 | `CLI_TYPE=gemini ./install.sh` | Gemini 설치 (환경변수) |
| T-06 | `--cli gemini --modules notion` | Gemini + Notion MCP (gemini mcp add) |
| T-07 | `--cli gemini --modules google` | Gemini + Google MCP (settings.json에 기록) |
| T-08 | `--cli gemini --modules pencil` | Pencil 스킵 + 안내 메시지 |
| T-09 | 기존 테스트 전부 | 통과 (회귀 없음) |
