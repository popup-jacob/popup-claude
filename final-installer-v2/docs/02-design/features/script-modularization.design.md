# Design: Script Modularization (final-installer-v2)

> **Feature**: script-modularization
> **Created**: 2026-02-03
> **Status**: Design Phase
> **Plan Reference**: docs/01-plan/features/script-modularization.plan.md

---

## 1. Architecture Overview

### 1.1 Execution Flow

```
사용자 명령어
┌─────────────────────────────────────────────────────────────────┐
│ Windows:                                                        │
│ & ([scriptblock]::Create((irm .../install.ps1))) -google -jira │
│                                                                 │
│ Mac/Linux:                                                      │
│ curl -sSL .../install.sh | bash -s -- --google --jira          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      install.ps1 / install.sh                   │
│                         (메인 진입점)                             │
├─────────────────────────────────────────────────────────────────┤
│  1. 파라미터 파싱 (-google, -jira, -all)                         │
│  2. Admin 권한 체크 (Windows)                                    │
│  3. 설치할 모듈 수 계산 → [1/N] 형태 출력                         │
│  4. 모듈 순차 호출                                               │
└─────────────────────────────────────────────────────────────────┘
         │
         ├──────────────────────────────────────────┐
         │                                          │
         ▼                                          │
┌─────────────────────┐                             │
│   modules/base      │  ← 항상 실행 (기본)          │
│   (.ps1 / .sh)      │                             │
├─────────────────────┤                             │
│ - Node.js           │                             │
│ - Git               │                             │  같은
│ - VS Code           │                             │  터미널
│ - Docker            │                             │  창
│ - Claude CLI        │                             │
│ - bkit plugin       │                             │
└─────────────────────┘                             │
         │                                          │
         ▼ (if -google)                             │
┌─────────────────────┐                             │
│   modules/google    │                             │
│   (.ps1 / .sh)      │                             │
├─────────────────────┤                             │
│ - Docker 체크       │                             │
│ - Admin/Employee    │                             │
│ - OAuth 설정        │                             │
│ - .mcp.json 추가    │                             │
└─────────────────────┘                             │
         │                                          │
         ▼ (if -jira)                               │
┌─────────────────────┐                             │
│   modules/jira      │                             │
│   (.ps1 / .sh)      │                             │
├─────────────────────┤                             │
│ - Rovo / Docker     │                             │
│ - API Token         │                             │
│ - .mcp.json 추가    │                             │
└─────────────────────┘                             │
         │                                          │
         ▼                                          │
┌─────────────────────┐                             │
│   설치 완료!         │ ◄───────────────────────────┘
└─────────────────────┘
```

### 1.2 File Structure

```
final-installer-v2/
├── ARCHITECTURE.md
├── README.md
│
├── install.ps1              # Windows 메인 (약 80줄)
├── install.sh               # Mac/Linux 메인 (약 70줄)
│
└── modules/
    ├── base.ps1             # 기본 설치 (약 150줄)
    ├── base.sh              # Mac 기본 설치 (약 120줄)
    ├── google.ps1           # Google MCP (약 250줄)
    ├── google.sh            # Mac Google MCP (약 200줄)
    ├── jira.ps1             # Jira MCP (약 100줄)
    └── jira.sh              # Mac Jira MCP (약 80줄)
```

---

## 2. Component Design

### 2.1 install.ps1 (Windows Main Entry)

```powershell
# ============================================
# AI-Driven Work Installer v2 - Windows
# ============================================

param(
    [switch]$google,      # Google Workspace MCP
    [switch]$jira,        # Jira/Confluence MCP
    [switch]$all,         # Install all modules
    [switch]$skipBase,    # Skip base installation (for testing)
    [switch]$nonInteractive  # Non-interactive mode (future)
)

# Base URL for module downloads
$BaseUrl = "https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer-v2/modules"

# ============================================
# 1. Admin Check & Elevation
# ============================================
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Administrator privileges required. Restarting as admin..." -ForegroundColor Yellow
    # 파라미터 재구성하여 관리자로 재실행
    $params = @()
    if ($google) { $params += "-google" }
    if ($jira) { $params += "-jira" }
    if ($all) { $params += "-all" }
    $paramString = $params -join " "

    $scriptUrl = "https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer-v2/install.ps1"
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -c `"& ([scriptblock]::Create((irm $scriptUrl))) $paramString`""
    exit
}

# ============================================
# 2. Parse Options
# ============================================
if ($all) {
    $google = $true
    $jira = $true
}

# Calculate total steps
$totalSteps = 1  # base is always included
if ($google) { $totalSteps++ }
if ($jira) { $totalSteps++ }

# ============================================
# 3. Welcome Banner
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI-Driven Work Installer v2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Selected modules:" -ForegroundColor White
Write-Host "  [*] Base (Claude + bkit)" -ForegroundColor Green
if ($google) { Write-Host "  [*] Google Workspace MCP" -ForegroundColor Green }
if ($jira) { Write-Host "  [*] Jira/Confluence MCP" -ForegroundColor Green }
Write-Host ""

# ============================================
# 4. Execute Modules
# ============================================
$currentStep = 0

# Step: Base Installation
if (-not $skipBase) {
    $currentStep++
    Write-Host ""
    Write-Host "[$currentStep/$totalSteps] Installing Base (Claude + bkit)..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray
    try {
        irm "$BaseUrl/base.ps1" | iex
    } catch {
        Write-Host "Error in base installation: $_" -ForegroundColor Red
        exit 1
    }
}

# Step: Google MCP
if ($google) {
    $currentStep++
    Write-Host ""
    Write-Host "[$currentStep/$totalSteps] Installing Google Workspace MCP..." -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray
    try {
        irm "$BaseUrl/google.ps1" | iex
    } catch {
        Write-Host "Error in Google MCP installation: $_" -ForegroundColor Red
        exit 1
    }
}

# Step: Jira MCP
if ($jira) {
    $currentStep++
    Write-Host ""
    Write-Host "[$currentStep/$totalSteps] Installing Jira/Confluence MCP..." -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray
    try {
        irm "$BaseUrl/jira.ps1" | iex
    } catch {
        Write-Host "Error in Jira MCP installation: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================
# 5. Completion
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
# ... status summary ...
```

### 2.2 install.sh (Mac/Linux Main Entry)

```bash
#!/bin/bash
# ============================================
# AI-Driven Work Installer v2 - Mac/Linux
# ============================================

set -e

# Base URL for module downloads
BASE_URL="https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer-v2/modules"

# Default options
INSTALL_GOOGLE=false
INSTALL_JIRA=false
SKIP_BASE=false

# ============================================
# 1. Parse Arguments
# ============================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --google) INSTALL_GOOGLE=true; shift ;;
        --jira) INSTALL_JIRA=true; shift ;;
        --all) INSTALL_GOOGLE=true; INSTALL_JIRA=true; shift ;;
        --skip-base) SKIP_BASE=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ============================================
# 2. Calculate Steps
# ============================================
TOTAL_STEPS=1
if [ "$INSTALL_GOOGLE" = true ]; then ((TOTAL_STEPS++)); fi
if [ "$INSTALL_JIRA" = true ]; then ((TOTAL_STEPS++)); fi

# ============================================
# 3. Welcome Banner
# ============================================
echo ""
echo "========================================"
echo "  AI-Driven Work Installer v2"
echo "========================================"
echo ""
echo "Selected modules:"
echo "  [*] Base (Claude + bkit)"
if [ "$INSTALL_GOOGLE" = true ]; then echo "  [*] Google Workspace MCP"; fi
if [ "$INSTALL_JIRA" = true ]; then echo "  [*] Jira/Confluence MCP"; fi
echo ""

# ============================================
# 4. Execute Modules
# ============================================
CURRENT_STEP=0

# Step: Base Installation
if [ "$SKIP_BASE" = false ]; then
    ((CURRENT_STEP++))
    echo ""
    echo "[$CURRENT_STEP/$TOTAL_STEPS] Installing Base (Claude + bkit)..."
    echo "────────────────────────────────────────"
    curl -sSL "$BASE_URL/base.sh" | bash
fi

# Step: Google MCP
if [ "$INSTALL_GOOGLE" = true ]; then
    ((CURRENT_STEP++))
    echo ""
    echo "[$CURRENT_STEP/$TOTAL_STEPS] Installing Google Workspace MCP..."
    echo "────────────────────────────────────────"
    curl -sSL "$BASE_URL/google.sh" | bash
fi

# Step: Jira MCP
if [ "$INSTALL_JIRA" = true ]; then
    ((CURRENT_STEP++))
    echo ""
    echo "[$CURRENT_STEP/$TOTAL_STEPS] Installing Jira/Confluence MCP..."
    echo "────────────────────────────────────────"
    curl -sSL "$BASE_URL/jira.sh" | bash
fi

# ============================================
# 5. Completion
# ============================================
echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
```

---

## 3. Module Design

### 3.1 modules/base.ps1

**Source**: v1 `setup_basic.ps1` 마이그레이션

```powershell
# ============================================
# Base Module - Claude + bkit Installation
# ============================================
# This module is called by install.ps1
# Can also be run standalone for testing

# ============================================
# Helper Functions
# ============================================
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Test-CommandExists($command) {
    return [bool](Get-Command $command -ErrorAction SilentlyContinue)
}

# ============================================
# 1. Check winget
# ============================================
Write-Host "[Check] winget..." -ForegroundColor Yellow
if (-not (Test-CommandExists "winget")) {
    Write-Host "winget not found!" -ForegroundColor Red
    Write-Host "Please update Windows or install App Installer from Microsoft Store." -ForegroundColor White
    Write-Host "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1" -ForegroundColor Cyan
    throw "winget is required"
}
Write-Host "  OK" -ForegroundColor Green

# ============================================
# 2. Node.js
# ============================================
Write-Host "[Install] Node.js..." -ForegroundColor Yellow
if (-not (Test-CommandExists "node")) {
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -h
    Refresh-Path
}
Write-Host "  OK - $(node --version)" -ForegroundColor Green

# ============================================
# 3. Git
# ============================================
Write-Host "[Install] Git..." -ForegroundColor Yellow
if (-not (Test-CommandExists "git")) {
    winget install Git.Git --accept-source-agreements --accept-package-agreements -h
    Refresh-Path
}
Write-Host "  OK - $(git --version)" -ForegroundColor Green

# ============================================
# 4. VS Code
# ============================================
Write-Host "[Install] VS Code..." -ForegroundColor Yellow
$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe"
)
$vscodeInstalled = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) { $vscodeInstalled = $true; break }
}
if (-not $vscodeInstalled) {
    winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements -h
}
Write-Host "  OK" -ForegroundColor Green

# ============================================
# 5. Docker Desktop
# ============================================
Write-Host "[Install] Docker Desktop..." -ForegroundColor Yellow
$script:NeedsRestart = $false
if (-not (Test-CommandExists "docker")) {
    winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements -h
    $script:NeedsRestart = $true
    Write-Host "  Installed (restart required)" -ForegroundColor Yellow
} else {
    Write-Host "  OK" -ForegroundColor Green
}

# ============================================
# 6. Claude CLI
# ============================================
Write-Host "[Install] Claude Code CLI..." -ForegroundColor Yellow
Refresh-Path
if (-not (Test-CommandExists "claude")) {
    npm install -g @anthropic-ai/claude-code
    Refresh-Path
}
Write-Host "  OK" -ForegroundColor Green

# ============================================
# 7. bkit Plugin
# ============================================
Write-Host "[Install] bkit Plugin..." -ForegroundColor Yellow
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>$null
claude plugin install bkit@bkit-marketplace 2>$null
Write-Host "  OK" -ForegroundColor Green

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "Base installation complete!" -ForegroundColor Green
if ($script:NeedsRestart) {
    Write-Host ""
    Write-Host "NOTE: Docker Desktop was installed." -ForegroundColor Yellow
    Write-Host "      A system restart may be required before using Docker." -ForegroundColor Yellow
}
```

### 3.2 modules/google.ps1

**Source**: v1 `setup_mcp.ps1` Google 섹션 추출

```powershell
# ============================================
# Google Workspace MCP Module
# ============================================
# Prerequisites: Docker must be running
# Called by install.ps1 when -google flag is used

# ============================================
# 1. Docker Check
# ============================================
Write-Host "[Check] Docker..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {}

if (-not $dockerRunning) {
    Write-Host ""
    Write-Host "Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor White
    throw "Docker is required for Google MCP"
}
Write-Host "  OK" -ForegroundColor Green

# ============================================
# 2. Role Selection (Admin / Employee)
# ============================================
Write-Host ""
Write-Host "What is your role?" -ForegroundColor White
Write-Host "  1. Admin (first-time setup, create OAuth credentials)" -ForegroundColor White
Write-Host "  2. Employee (received client_secret.json from admin)" -ForegroundColor White
Write-Host ""
$roleChoice = Read-Host "Select (1/2)"

if ($roleChoice -eq "1") {
    # ========================================
    # ADMIN PATH
    # ========================================
    Write-Host ""
    Write-Host "=== Google Cloud Admin Setup ===" -ForegroundColor Cyan

    # Check/Install gcloud CLI
    # ... (v1 로직 그대로 사용)

    # Login to gcloud
    # ... (v1 로직 그대로 사용)

    # Internal/External selection
    # ... (v1 로직 그대로 사용)

    # Create/Select project
    # ... (v1 로직 그대로 사용)

    # Enable APIs
    # ... (v1 로직 그대로 사용)

    # OAuth Consent Screen (Manual)
    # ... (v1 로직 그대로 사용)

    # Create OAuth Client
    # ... (v1 로직 그대로 사용)
}

# ========================================
# EMPLOYEE PATH (runs for both Admin and Employee)
# ========================================
Write-Host ""
Write-Host "Setting up Google MCP..." -ForegroundColor Yellow

$configDir = "$env:USERPROFILE\.google-workspace"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Check client_secret.json
$clientSecretPath = "$configDir\client_secret.json"
if (-not (Test-Path $clientSecretPath)) {
    Write-Host ""
    Write-Host "client_secret.json required." -ForegroundColor White
    Write-Host "Copy from admin to: $clientSecretPath" -ForegroundColor Cyan
    Start-Process explorer.exe -ArgumentList $configDir
    Read-Host "Press Enter when file is ready"

    if (-not (Test-Path $clientSecretPath)) {
        throw "client_secret.json not found"
    }
}

# Pull Docker image
Write-Host "[Pull] Google MCP Docker image..." -ForegroundColor Yellow
docker pull ghcr.io/popup-jacob/google-workspace-mcp:latest
Write-Host "  OK" -ForegroundColor Green

# OAuth authentication (if no token)
$tokenPath = "$configDir\token.json"
if (-not (Test-Path $tokenPath)) {
    Write-Host ""
    Write-Host "Google login required..." -ForegroundColor Yellow
    $configDirUnix = $configDir -replace '\\', '/'
    docker run -i --rm -p 3000:3000 -v "${configDirUnix}:/app/.google-workspace" `
        ghcr.io/popup-jacob/google-workspace-mcp:latest `
        node -e "require('./dist/auth/oauth.js').getAuthenticatedClient().then(() => process.exit(0)).catch(() => process.exit(1))"
}

# Update .mcp.json
Write-Host "[Config] Updating .mcp.json..." -ForegroundColor Yellow
$mcpConfigPath = "$env:USERPROFILE\.mcp.json"
$configDirUnix = $configDir -replace '\\', '/'

$mcpConfig = @{ mcpServers = @{} }
if (Test-Path $mcpConfigPath) {
    $existing = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
    if ($existing.mcpServers) {
        $existing.mcpServers.PSObject.Properties | ForEach-Object {
            $mcpConfig.mcpServers[$_.Name] = @{
                command = $_.Value.command
                args = @($_.Value.args)
            }
        }
    }
}

$mcpConfig.mcpServers["google-workspace"] = @{
    command = "docker"
    args = @("run", "-i", "--rm", "-v", "${configDirUnix}:/app/.google-workspace",
             "ghcr.io/popup-jacob/google-workspace-mcp:latest")
}

$mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "Google MCP installation complete!" -ForegroundColor Green
```

### 3.3 modules/jira.ps1

**Source**: v1 `setup_mcp.ps1` Jira 섹션 추출

```powershell
# ============================================
# Jira/Confluence MCP Module
# ============================================
# Called by install.ps1 when -jira flag is used

Write-Host ""
Write-Host "Select installation type:" -ForegroundColor White
Write-Host "  1. Rovo MCP (non-developer, just login)" -ForegroundColor White
Write-Host "  2. mcp-atlassian (developer, API token)" -ForegroundColor White
Write-Host ""
$jiraChoice = Read-Host "Select (1/2)"

if ($jiraChoice -eq "1") {
    # ========================================
    # ROVO MCP (Official Atlassian SSE)
    # ========================================
    Write-Host ""
    Write-Host "Setting up Atlassian Rovo MCP..." -ForegroundColor Yellow
    claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse
    Write-Host "  OK" -ForegroundColor Green

} else {
    # ========================================
    # MCP-ATLASSIAN (Docker)
    # ========================================
    Write-Host ""
    Write-Host "Setting up mcp-atlassian..." -ForegroundColor Yellow

    # Get credentials
    Write-Host "Get API token from: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Cyan
    $openToken = Read-Host "Open in browser? (y/n)"
    if ($openToken -eq "y") {
        Start-Process "https://id.atlassian.com/manage-profile/security/api-tokens"
        Read-Host "Press Enter when ready"
    }

    $confluenceUrl = Read-Host "Confluence URL (e.g. https://company.atlassian.net/wiki)"
    $jiraUrl = Read-Host "Jira URL (e.g. https://company.atlassian.net)"
    $email = Read-Host "Your email"
    $apiToken = Read-Host "API token"

    # Pull Docker image
    Write-Host "[Pull] mcp-atlassian Docker image..." -ForegroundColor Yellow
    docker pull ghcr.io/sooperset/mcp-atlassian:latest
    Write-Host "  OK" -ForegroundColor Green

    # Update .mcp.json
    Write-Host "[Config] Updating .mcp.json..." -ForegroundColor Yellow
    $mcpConfigPath = "$env:USERPROFILE\.mcp.json"

    $mcpConfig = @{ mcpServers = @{} }
    if (Test-Path $mcpConfigPath) {
        $existing = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
        if ($existing.mcpServers) {
            $existing.mcpServers.PSObject.Properties | ForEach-Object {
                $mcpConfig.mcpServers[$_.Name] = @{
                    command = $_.Value.command
                    args = @($_.Value.args)
                }
            }
        }
    }

    $mcpConfig.mcpServers["atlassian"] = @{
        command = "docker"
        args = @(
            "run", "-i", "--rm",
            "-e", "CONFLUENCE_URL=$confluenceUrl",
            "-e", "CONFLUENCE_USERNAME=$email",
            "-e", "CONFLUENCE_API_TOKEN=$apiToken",
            "-e", "JIRA_URL=$jiraUrl",
            "-e", "JIRA_USERNAME=$email",
            "-e", "JIRA_API_TOKEN=$apiToken",
            "ghcr.io/sooperset/mcp-atlassian:latest"
        )
    }

    $mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding utf8
    Write-Host "  OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "Jira/Confluence MCP installation complete!" -ForegroundColor Green
```

---

## 4. Interface Contracts

### 4.1 Module Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (with message) |

### 4.2 Module Responsibilities

| Module | Input | Output | Side Effects |
|--------|-------|--------|--------------|
| base.ps1 | None | Exit code | Installs tools, modifies PATH |
| google.ps1 | User input (interactive) | Exit code | Creates ~/.google-workspace/, updates .mcp.json |
| jira.ps1 | User input (interactive) | Exit code | Updates .mcp.json |

### 4.3 .mcp.json Merge Strategy

**PowerShell & Bash 모두 자동 병합 지원**

```bash
# Bash: Node.js를 사용하여 .mcp.json 병합 (base 모듈에서 Node.js 이미 설치됨)
node -e "
const fs = require('fs');
const configPath = process.env.HOME + '/.mcp.json';
let config = { mcpServers: {} };

// 기존 설정 로드
if (fs.existsSync(configPath)) {
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  if (!config.mcpServers) config.mcpServers = {};
}

// 새 서버 추가 (기존 설정 유지)
config.mcpServers['google-workspace'] = {
  command: 'docker',
  args: ['run', '-i', '--rm', '-v', '\$CONFIG_DIR:/app/.google-workspace', 'ghcr.io/popup-jacob/google-workspace-mcp:latest']
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
```

이 방식의 장점:
- 기존 MCP 설정 유지
- jq 등 추가 도구 설치 불필요
- Node.js는 base 모듈에서 이미 설치됨

### 4.3 Shared Variables (PowerShell)

모듈 간 공유 변수는 사용하지 않음. 각 모듈은 독립적으로 실행.

---

## 5. Error Handling

### 5.1 Error Strategy

```powershell
# install.ps1 에서 try-catch로 모듈 실행
try {
    irm "$BaseUrl/base.ps1" | iex
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Installation aborted." -ForegroundColor Red
    exit 1
}
```

### 5.2 Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "winget not found" | Windows 10 old version | Prompt to install App Installer |
| "Docker not running" | Docker Desktop not started | Prompt to start Docker |
| "client_secret.json not found" | Admin hasn't shared file | Clear instruction |

---

## 6. Testing Checklist

### 6.1 Unit Tests (Manual)

- [ ] install.ps1 파라미터 파싱 (-google, -jira, -all)
- [ ] install.ps1 Admin 권한 상승
- [ ] base.ps1 독립 실행
- [ ] google.ps1 Admin 경로
- [ ] google.ps1 Employee 경로
- [ ] jira.ps1 Rovo MCP
- [ ] jira.ps1 mcp-atlassian

### 6.2 Integration Tests (Manual)

- [ ] 전체 플로우: `install.ps1 -all`
- [ ] 기본만: `install.ps1`
- [ ] Google만: `install.ps1 -google`
- [ ] Jira만: `install.ps1 -jira`

---

## 7. Implementation Order

```
1. install.ps1      ← 먼저 (스켈레톤)
2. modules/base.ps1 ← v1에서 마이그레이션
3. modules/google.ps1 ← v1에서 추출
4. modules/jira.ps1  ← v1에서 추출
5. install.sh       ← Windows 완료 후
6. modules/*.sh     ← Bash 버전
```

---

## 8. GitHub URLs

```
Base URL: https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer-v2/

install.ps1:     {Base URL}/install.ps1
install.sh:      {Base URL}/install.sh
modules/base.ps1:   {Base URL}/modules/base.ps1
modules/google.ps1: {Base URL}/modules/google.ps1
modules/jira.ps1:   {Base URL}/modules/jira.ps1
```

---

## Next Steps

1. ✅ Design 문서 작성 완료
2. ⏳ `/pdca do script-modularization` 실행하여 구현 시작
3. 구현 순서: install.ps1 → base.ps1 → google.ps1 → jira.ps1 → sh 버전들
