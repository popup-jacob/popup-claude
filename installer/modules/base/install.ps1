# ============================================
# Base Module - Claude + bkit Installation
# ============================================
# This module installs: Node.js, Git, VS Code, Docker, Claude CLI, bkit Plugin
# Called by install.ps1, can also run standalone

# ============================================
# Helper Functions
# ============================================
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# ============================================
# 1. Check winget
# ============================================
Write-Host "[1/8] Checking winget..." -ForegroundColor Yellow
if (-not (Test-CommandExists "winget")) {
    Write-Host ""
    Write-Host "winget not found!" -ForegroundColor Red
    Write-Host "Please update Windows or install App Installer from Microsoft Store:" -ForegroundColor White
    Write-Host "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1" -ForegroundColor Cyan
    throw "winget is required"
}
Write-Host "  OK" -ForegroundColor Green

# ============================================
# 2. Node.js
# ============================================
Write-Host ""
Write-Host "[2/8] Checking Node.js..." -ForegroundColor Yellow
if (-not (Test-CommandExists "node")) {
    Write-Host "  Installing Node.js LTS..." -ForegroundColor Gray
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -h
    Refresh-Path
}
if (Test-CommandExists "node") {
    $nodeVersion = node --version
    Write-Host "  OK - $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  Installed (restart terminal to use)" -ForegroundColor Yellow
}

# ============================================
# 3. Git
# ============================================
Write-Host ""
Write-Host "[3/8] Checking Git..." -ForegroundColor Yellow
if (-not (Test-CommandExists "git")) {
    Write-Host "  Installing Git..." -ForegroundColor Gray
    winget install Git.Git --accept-source-agreements --accept-package-agreements -h
    Refresh-Path
}
if (Test-CommandExists "git") {
    $gitVersion = git --version
    Write-Host "  OK - $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  Installed (restart terminal to use)" -ForegroundColor Yellow
}

# ============================================
# 4. VS Code
# ============================================
Write-Host ""
Write-Host "[4/8] Checking VS Code..." -ForegroundColor Yellow
$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe"
)
$vscodeInstalled = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) { $vscodeInstalled = $true; break }
}
if (-not $vscodeInstalled) {
    Write-Host "  Installing VS Code..." -ForegroundColor Gray
    winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements -h
}
Write-Host "  OK" -ForegroundColor Green

# Install Claude extension for VS Code
if (Test-CommandExists "code") {
    Write-Host "  Installing Claude extension..." -ForegroundColor Gray
    code --install-extension anthropic.claude-code 2>$null
    Write-Host "  Claude extension installed" -ForegroundColor Green
}

# ============================================
# 5. WSL (Windows Subsystem for Linux)
# ============================================
Write-Host ""
Write-Host "[5/8] Checking WSL..." -ForegroundColor Yellow
$script:WslNeedsRestart = $false
if ($script:needsDocker) {
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $wslInstalled = $false
    $wslOutput = wsl --version 2>&1 | Out-String -Width 10000
    if ($LASTEXITCODE -eq 0 -and $wslOutput -match "WSL") {
        $wslInstalled = $true
    }

    if ($wslInstalled) {
        Write-Host "  Updating WSL..." -ForegroundColor Gray
        wsl --update 2>&1 | Out-Null
        Write-Host "  OK (up to date)" -ForegroundColor Green
    } else {
        Write-Host "  Installing WSL..." -ForegroundColor Gray
        wsl --install --no-distribution 2>&1 | Out-Null
        $script:WslNeedsRestart = $true
        Write-Host "  Installed (system restart required)" -ForegroundColor Yellow
    }

    $ErrorActionPreference = $prevErrorAction
} else {
    Write-Host "  Skipped (not required by selected modules)" -ForegroundColor Gray
}

# ============================================
# 6. Docker Desktop (only if needed)
# ============================================
Write-Host ""
Write-Host "[6/8] Checking Docker Desktop..." -ForegroundColor Yellow
$script:DockerNeedsRestart = $false
if ($script:needsDocker) {
    if (-not (Test-CommandExists "docker")) {
        Write-Host "  Installing Docker Desktop (this may take a few minutes)..." -ForegroundColor Gray
        winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
        $script:DockerNeedsRestart = $true
        Write-Host "  Installed (system restart required)" -ForegroundColor Yellow
    } else {
        Write-Host "  OK" -ForegroundColor Green
    }
} else {
    Write-Host "  Skipped (not required by selected modules)" -ForegroundColor Gray
}

# ============================================
# 7. Claude Code CLI
# ============================================
Write-Host ""
Write-Host "[7/8] Checking Claude Code CLI..." -ForegroundColor Yellow
Refresh-Path
if (-not (Test-CommandExists "claude")) {
    Write-Host "  Installing Claude Code CLI (native)..." -ForegroundColor Gray
    irm https://claude.ai/install.ps1 | iex
    Refresh-Path
    # Native install puts claude in ~/.local/bin (not in registry PATH yet)
    $claudePath = "$env:USERPROFILE\.local\bin"
    if ((Test-Path $claudePath) -and ($env:PATH -notlike "*$claudePath*")) {
        $env:PATH = "$claudePath;$env:PATH"
    }
}
if (Test-CommandExists "claude") {
    $claudeVersion = claude --version 2>$null
    Write-Host "  OK - $claudeVersion" -ForegroundColor Green
} else {
    Write-Host "  Installed (restart terminal to use)" -ForegroundColor Yellow
}

# ============================================
# 8. bkit Plugin
# ============================================
Write-Host ""
Write-Host "[8/8] Installing bkit Plugin..." -ForegroundColor Yellow
$ErrorActionPreference = "SilentlyContinue"
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>$null
claude plugin install bkit@bkit-marketplace 2>$null
$ErrorActionPreference = "Stop"

$bkitCheck = claude plugin list 2>$null | Select-String "bkit"
if ($bkitCheck) {
    Write-Host "  OK" -ForegroundColor Green
} else {
    Write-Host "  Installed (verify with 'claude plugin list')" -ForegroundColor Yellow
}

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Base installation complete!" -ForegroundColor Green

if ($script:WslNeedsRestart -or $script:DockerNeedsRestart) {
    Write-Host ""
    if ($script:WslNeedsRestart) {
        Write-Host "IMPORTANT: WSL was installed." -ForegroundColor Yellow
    }
    if ($script:DockerNeedsRestart) {
        Write-Host "IMPORTANT: Docker Desktop was installed." -ForegroundColor Yellow
    }
    Write-Host "  1. Restart your computer" -ForegroundColor White
    Write-Host "  2. Start Docker Desktop" -ForegroundColor White
    Write-Host "  3. Run installer again with -skipBase flag:" -ForegroundColor White
    Write-Host "     .\install.ps1 -modules `"google,atlassian`" -skipBase" -ForegroundColor Cyan
}
