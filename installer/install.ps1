# ============================================
# AI-Driven Work Installer (ADW) - Windows
# ============================================
# Dynamic Module Loading System (Folder Scan)
#
# Usage:
#   .\install.ps1 -modules "google,atlassian"
#   .\install.ps1 -all
#   .\install.ps1 -installDocker
#   .\install.ps1 -list
#
# Remote (Step 1 - base + Docker):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/.../install.ps1))) -installDocker
#
# Remote (Step 2 - modules only):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/.../install.ps1))) -modules "google" -skipBase

param(
    [string]$modules = "",       # Comma-separated module list
    [switch]$all,                # Install all modules
    [switch]$skipBase,           # Skip base module
    [switch]$installDocker,      # Force Docker installation (for Step 1)
    [switch]$list                # List available modules
)

# ============================================
# Environment Variable Support
# ============================================
# $env:MODULES        - Module selection (e.g., "google", "google,atlassian")
# $env:SKIP_BASE      - Skip base module ("true" or "1")
# $env:INSTALL_ALL    - Install all modules ("true" or "1")
# $env:INSTALL_DOCKER - Force Docker installation ("true" or "1")
#
# Step 1: $env:INSTALL_DOCKER='true'; irm .../install.ps1 | iex
# Step 2: $env:MODULES='google'; $env:SKIP_BASE='true'; irm .../install.ps1 | iex
if (-not $modules -and $env:MODULES) {
    $modules = $env:MODULES
}
if ($env:SKIP_BASE -eq "true" -or $env:SKIP_BASE -eq "1") {
    $skipBase = $true
}
if ($env:INSTALL_ALL -eq "true" -or $env:INSTALL_ALL -eq "1") {
    $all = $true
}

# Base URL for module downloads - GitHub raw (always latest from master)
$BaseUrl = "https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer"

# For local development, use local files
# 원격 실행 시 $MyInvocation.MyCommand.Path가 null이므로 체크 필요
$ScriptPath = $MyInvocation.MyCommand.Path
if ($ScriptPath) {
    $ScriptDir = Split-Path -Parent $ScriptPath
    $UseLocal = Test-Path "$ScriptDir\modules"
} else {
    $ScriptDir = $null
    $UseLocal = $false
}

# ============================================
# 1. Scan Modules Folder (before admin check for -list)
# ============================================
function Get-AvailableModules {
    $moduleList = @()

    if ($UseLocal) {
        # Local: scan modules/ folder
        $moduleDirs = Get-ChildItem "$ScriptDir\modules" -Directory
        foreach ($dir in $moduleDirs) {
            $jsonPath = "$($dir.FullName)\module.json"
            if (Test-Path $jsonPath) {
                $moduleJson = Get-Content $jsonPath -Raw | ConvertFrom-Json
                $moduleList += $moduleJson
            }
        }
    } else {
        # Remote: fetch module list from modules.json
        try {
            $modulesIndex = irm "$BaseUrl/modules.json" -ErrorAction SilentlyContinue
            if ($modulesIndex -and $modulesIndex.modules) {
                foreach ($mod in $modulesIndex.modules) {
                    try {
                        $moduleJson = irm "$BaseUrl/modules/$($mod.name)/module.json" -ErrorAction SilentlyContinue
                        if ($moduleJson) {
                            $moduleList += $moduleJson
                        }
                    } catch {}
                }
            }
        } catch {}
    }

    # Sort by order
    return $moduleList | Sort-Object { $_.order }
}

# ============================================
# 2. List Mode (no admin required)
# ============================================
if ($list) {
    $availableModules = Get-AvailableModules
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Available Modules" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($mod in $availableModules) {
        $required = if ($mod.required) { "(required)" } else { "" }
        $complexity = "[$($mod.complexity)]"

        Write-Host "  $($mod.name)" -ForegroundColor Green -NoNewline
        Write-Host " $required" -ForegroundColor Yellow -NoNewline
        Write-Host " $complexity" -ForegroundColor DarkGray
        Write-Host "    $($mod.description)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  .\install.ps1 -modules `"google,atlassian`"" -ForegroundColor Gray
    Write-Host "  .\install.ps1 -all" -ForegroundColor Gray
    Write-Host ""
    exit
}

# ============================================
# 3. Admin Check & Elevation (only for installation)
# ============================================
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Administrator privileges required. Restarting as admin..." -ForegroundColor Yellow

    $params = @()
    if ($modules) { $params += "-modules `"$modules`"" }
    if ($all) { $params += "-all" }
    if ($skipBase) { $params += "-skipBase" }
    if ($installDocker) { $params += "-installDocker" }
    $paramString = $params -join " "

    if ($UseLocal) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptDir\install.ps1`" $paramString"
    } else {
        $scriptUrl = "$BaseUrl/install.ps1"
        Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -c `"& ([scriptblock]::Create((irm $scriptUrl))) $paramString`""
    }
    exit
}

# Load modules for installation
$availableModules = Get-AvailableModules

# ============================================
# 4. Parse Module Selection
# ============================================
$selectedModules = @()

if ($all) {
    # All non-required modules
    $selectedModules = $availableModules | Where-Object { -not $_.required } | Select-Object -ExpandProperty name
} elseif ($modules) {
    $selectedModules = $modules -split "," | ForEach-Object { $_.Trim() }
}

# Validate modules
$validNames = $availableModules | Select-Object -ExpandProperty name
foreach ($mod in $selectedModules) {
    if ($mod -notin $validNames) {
        Write-Host "Unknown module: $mod" -ForegroundColor Red
        Write-Host "Use -list to see available modules." -ForegroundColor Gray
        exit 1
    }
}

# ============================================
# 5. Smart Status Check
# ============================================
function Get-InstallStatus {
    $status = @{
        NodeJS = [bool](Get-Command node -ErrorAction SilentlyContinue)
        Git = [bool](Get-Command git -ErrorAction SilentlyContinue)
        VSCode = (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -or (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe")
        Docker = [bool](Get-Command docker -ErrorAction SilentlyContinue)
        DockerRunning = $false
        Claude = [bool](Get-Command claude -ErrorAction SilentlyContinue)
        Bkit = $false
    }

    if ($status.Docker) {
        $null = docker info 2>&1
        $status.DockerRunning = ($LASTEXITCODE -eq 0)
    }

    if ($status.Claude) {
        $bkitCheck = claude plugin list 2>$null | Select-String "bkit"
        $status.Bkit = [bool]$bkitCheck
    }

    return $status
}

Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI-Driven Work Installer v2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$status = Get-InstallStatus

# Check Docker requirement for selected modules (before status display)
$script:needsDocker = $false
# Parameter or environment variable to force Docker installation (for Step 1)
if ($installDocker -or $env:INSTALL_DOCKER -eq "true" -or $env:INSTALL_DOCKER -eq "1") {
    $script:needsDocker = $true
}
foreach ($modName in $selectedModules) {
    $mod = $availableModules | Where-Object { $_.name -eq $modName }
    if ($mod.requirements.docker) {
        $script:needsDocker = $true
        break
    }
}

Write-Host "Current Status:" -ForegroundColor White
Write-Host "  Node.js:  $(if($status.NodeJS){'[OK]'}else{'[  ]'})" -ForegroundColor $(if($status.NodeJS){'Green'}else{'DarkGray'})
Write-Host "  Git:      $(if($status.Git){'[OK]'}else{'[  ]'})" -ForegroundColor $(if($status.Git){'Green'}else{'DarkGray'})
Write-Host "  VS Code:  $(if($status.VSCode){'[OK]'}else{'[  ]'})" -ForegroundColor $(if($status.VSCode){'Green'}else{'DarkGray'})
if ($script:needsDocker) {
    Write-Host "  Docker:   $(if($status.Docker){'[OK]'}else{'[  ]'}) $(if($status.Docker -and $status.DockerRunning){'(Running)'}elseif($status.Docker){'(Not Running)'}else{''})" -ForegroundColor $(if($status.DockerRunning){'Green'}elseif($status.Docker){'Yellow'}else{'DarkGray'})
}
Write-Host "  Claude:   $(if($status.Claude){'[OK]'}else{'[  ]'})" -ForegroundColor $(if($status.Claude){'Green'}else{'DarkGray'})
Write-Host "  bkit:     $(if($status.Bkit){'[OK]'}else{'[  ]'})" -ForegroundColor $(if($status.Bkit){'Green'}else{'DarkGray'})
Write-Host ""

if ($script:needsDocker -and $status.Docker -and -not $status.DockerRunning) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Docker Desktop is not running!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Selected modules require Docker to be running." -ForegroundColor White
    Write-Host ""
    Write-Host "How to start:" -ForegroundColor Gray
    Write-Host "  - Press Windows key, type 'Docker Desktop', Enter" -ForegroundColor Gray
    Write-Host ""
    $dockerWait = Read-Host "Press Enter after starting Docker (or 'q' to quit)"
    if ($dockerWait -eq 'q') { exit 0 }

    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker still not running. Please start it and try again." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "Docker is now running!" -ForegroundColor Green
    Write-Host ""
}

# Auto-skip base if all required tools installed
$baseInstalled = $status.NodeJS -and $status.Git -and $status.Claude -and $status.Bkit
if ($script:needsDocker) {
    $baseInstalled = $baseInstalled -and $status.Docker
}
if ($baseInstalled -and -not $skipBase -and $selectedModules.Count -gt 0) {
    Write-Host "All base tools are already installed. Skipping base." -ForegroundColor Green
    $skipBase = $true
    Write-Host ""
}

# ============================================
# 6. Calculate Steps & Show Selection
# ============================================
$totalSteps = 0
if (-not $skipBase) { $totalSteps++ }
$totalSteps += $selectedModules.Count

if ($totalSteps -eq 0) {
    $totalSteps = 1
    $skipBase = $false
}

Write-Host "Selected modules:" -ForegroundColor White
if (-not $skipBase) {
    Write-Host "  [*] Base (Claude + bkit)" -ForegroundColor Green
} else {
    Write-Host "  [ ] Base (skipped)" -ForegroundColor DarkGray
}
foreach ($modName in $selectedModules) {
    $mod = $availableModules | Where-Object { $_.name -eq $modName }
    Write-Host "  [*] $($mod.displayName)" -ForegroundColor Green
}
Write-Host ""
Read-Host "Press Enter to start installation"

# ============================================
# 7. Module Execution Function
# ============================================
function Invoke-Module {
    param(
        [string]$ModuleName,
        [int]$Step,
        [int]$Total
    )

    $mod = $availableModules | Where-Object { $_.name -eq $ModuleName }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  [$Step/$Total] $($mod.displayName)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $($mod.description)" -ForegroundColor Gray
    Write-Host ""

    try {
        if ($UseLocal) {
            . "$ScriptDir\modules\$ModuleName\install.ps1"
        } else {
            irm "$BaseUrl/modules/$ModuleName/install.ps1" | iex
        }
    } catch {
        Write-Host ""
        Write-Host "Error in $($mod.displayName): $_" -ForegroundColor Red
        Write-Host "Installation aborted." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ============================================
# 8. Execute Modules
# ============================================
$currentStep = 0

# Base module
if (-not $skipBase) {
    $currentStep++
    Invoke-Module -ModuleName "base" -Step $currentStep -Total $totalSteps
}

# Selected modules (sorted by order)
$sortedModules = $selectedModules | Sort-Object { ($availableModules | Where-Object { $_.name -eq $_ }).order }
foreach ($modName in $sortedModules) {
    $currentStep++
    Invoke-Module -ModuleName $modName -Step $currentStep -Total $totalSteps
}

# ============================================
# 9. Completion Summary
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed:" -ForegroundColor White

if (-not $skipBase) {
    if (Get-Command node -ErrorAction SilentlyContinue) { Write-Host "  [OK] Node.js" -ForegroundColor Green }
    if (Get-Command git -ErrorAction SilentlyContinue) { Write-Host "  [OK] Git" -ForegroundColor Green }
    if ($script:needsDocker) {
        if (Get-Command docker -ErrorAction SilentlyContinue) { Write-Host "  [OK] Docker" -ForegroundColor Green }
    }
    if (Get-Command claude -ErrorAction SilentlyContinue) { Write-Host "  [OK] Claude Code CLI" -ForegroundColor Green }
    $bkitCheck = claude plugin list 2>$null | Select-String "bkit"
    if ($bkitCheck) { Write-Host "  [OK] bkit Plugin" -ForegroundColor Green }
}

# Check MCP config
$mcpConfigPath = "$env:USERPROFILE\.mcp.json"
if (Test-Path $mcpConfigPath) {
    $mcpJson = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
    foreach ($modName in $sortedModules) {
        $mod = $availableModules | Where-Object { $_.name -eq $modName }

        if ($mod.type -eq "remote-mcp") {
            # Remote MCP servers are registered via 'claude mcp add', not in .mcp.json
            Write-Host "  [OK] $($mod.displayName) (Remote MCP)" -ForegroundColor Green
        } elseif ($mod.mcpConfig -and $mod.mcpConfig.serverName) {
            if ($mcpJson.mcpServers.$($mod.mcpConfig.serverName)) {
                Write-Host "  [OK] $($mod.displayName)" -ForegroundColor Green
            }
        } elseif ($mod.type -eq "cli") {
            Write-Host "  [OK] $($mod.displayName)" -ForegroundColor Green
        }
    }
}

Write-Host ""
cmd /c pause
