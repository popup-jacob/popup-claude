# AI-Driven Work - Basic Setup Script (Windows)
# Installs: Node.js, Git, VS Code, Docker, Claude CLI, bkit Plugin
# Usage: powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_basic.ps1 | iex"

$ScriptUrl = "https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_basic.ps1"

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Administrator privileges required. Restarting as admin..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -c `"irm $ScriptUrl | iex`""
    exit
}

# Running as admin - show welcome message
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI-Driven Work - Basic Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will install:" -ForegroundColor White
Write-Host "  - Node.js, Git, VS Code" -ForegroundColor Gray
Write-Host "  - Docker Desktop" -ForegroundColor Gray
Write-Host "  - Claude Code CLI" -ForegroundColor Gray
Write-Host "  - bkit Plugin" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to start"

# ============================================
# PART 1: Basic Tools Installation (winget)
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 1: Installing Basic Tools" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check winget
Write-Host ""
Write-Host "[0/5] Checking winget..." -ForegroundColor Yellow
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Please update Windows or install App Installer from Microsoft Store." -ForegroundColor Red
    Write-Host "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "winget OK!" -ForegroundColor Green

# Install Node.js
Write-Host ""
Write-Host "[1/5] Checking Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -h
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
Write-Host "Node.js OK!" -ForegroundColor Green

# Install Git
Write-Host ""
Write-Host "[2/5] Checking Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..." -ForegroundColor Yellow
    winget install Git.Git --accept-source-agreements --accept-package-agreements -h
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
Write-Host "Git OK!" -ForegroundColor Green

# Install VS Code
Write-Host ""
Write-Host "[3/5] Checking VS Code..." -ForegroundColor Yellow
$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe"
)
$vscodeInstalled = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) { $vscodeInstalled = $true; break }
}
if (-not $vscodeInstalled) {
    Write-Host "Installing VS Code..." -ForegroundColor Yellow
    winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements -h
}
Write-Host "VS Code OK!" -ForegroundColor Green

# Install Docker Desktop
Write-Host ""
Write-Host "[4/5] Checking Docker..." -ForegroundColor Yellow
$dockerInstalled = $false
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerInstalled = $true
}
if (-not $dockerInstalled) {
    Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements -h
    $needsRestart = $true
}
Write-Host "Docker OK!" -ForegroundColor Green

# Install Claude Code CLI
Write-Host ""
Write-Host "[5/5] Checking Claude Code CLI..." -ForegroundColor Yellow
# Refresh PATH again for npm
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Claude Code CLI..." -ForegroundColor Yellow
    npm install -g @anthropic-ai/claude-code
}
Write-Host "Claude Code CLI OK!" -ForegroundColor Green

# ============================================
# PART 2: bkit Plugin Installation
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 2: Installing bkit Plugin" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Adding bkit marketplace..." -ForegroundColor Yellow
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>$null

Write-Host "Installing bkit plugin..." -ForegroundColor Yellow
claude plugin install bkit@bkit-marketplace 2>$null
Write-Host "bkit OK!" -ForegroundColor Green

# ============================================
# COMPLETE
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Basic Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Status:" -ForegroundColor White

# Check Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Node.js" -ForegroundColor Green
} else {
    Write-Host "  [X] Node.js - not found" -ForegroundColor Red
}

# Check Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Git" -ForegroundColor Green
} else {
    Write-Host "  [X] Git - not found" -ForegroundColor Red
}

# Check VS Code
$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe"
)
$vscodeFound = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) { $vscodeFound = $true; break }
}
if ($vscodeFound) {
    Write-Host "  [OK] VS Code" -ForegroundColor Green
} else {
    Write-Host "  [X] VS Code - not found" -ForegroundColor Red
}

# Check Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Docker" -ForegroundColor Green
} else {
    Write-Host "  [!] Docker - installed (restart required)" -ForegroundColor Yellow
}

# Check Claude CLI
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Claude Code CLI" -ForegroundColor Green
} else {
    Write-Host "  [X] Claude Code CLI - not found" -ForegroundColor Red
}

# Check bkit plugin
$bkitCheck = claude plugin list 2>$null | Select-String "bkit"
if ($bkitCheck) {
    Write-Host "  [OK] bkit Plugin" -ForegroundColor Green
} else {
    Write-Host "  [X] bkit Plugin - not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  IMPORTANT: Restart Required!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. RESTART your computer" -ForegroundColor Yellow
Write-Host "  2. Start Docker Desktop" -ForegroundColor Gray
Write-Host "  3. Run setup_mcp.ps1 to set up Google/Jira MCP" -ForegroundColor Gray
Write-Host ""
cmd /c pause
