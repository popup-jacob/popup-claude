# ============================================
# ADW - Claude Desktop Installer (Windows)
# ============================================
# Usage: irm <raw-url>/install.ps1 | iex
#   or:  .\install.ps1
#
# Environment variables:
#   MODULES  — comma-separated MCP modules (github,figma,notion)

param(
    [switch]$help
)

$ErrorActionPreference = "Stop"


# ============================================
# Find Claude Desktop
# ============================================
function Find-ClaudeDesktop {
    # 1. Check MSIX/AppX package (WindowsApps) - winget installs here
    $appx = Get-AppxPackage -Name "*Claude*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($appx) {
        $exe = Join-Path $appx.InstallLocation "app\Claude.exe"
        if (Test-Path $exe) { return $exe }
    }

    # 2. Check running process
    $proc = Get-Process -Name "claude" -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "*Claude*" -and $_.Path -notlike "*.vscode*" -and $_.Path -notlike "*.local*" } |
        Select-Object -First 1
    if ($proc -and $proc.Path) { return $proc.Path }

    # 3. Check common paths
    $searchPaths = @(
        "$env:LOCALAPPDATA\AnthropicClaude\claude.exe",
        "$env:LOCALAPPDATA\Programs\Claude\Claude.exe",
        "$env:LOCALAPPDATA\Claude\Claude.exe"
    )
    foreach ($p in $searchPaths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# ============================================
# Parse MODULES env var
# ============================================
$requestedModules = @()
if ($env:MODULES) {
    $requestedModules = ($env:MODULES -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
}
$hasModules = $requestedModules.Count -gt 0
$totalSteps = if ($hasModules) { 4 } else { 3 }

# ============================================
# Header
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ADW - Claude Desktop Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "AI-Driven Work environment installer" -ForegroundColor Gray
if ($hasModules) {
    Write-Host "Modules: $($requestedModules -join ', ')" -ForegroundColor Gray
}
Write-Host ""

if ($help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\install.ps1          Install Claude Desktop"
    Write-Host ""
    Write-Host "Environment variables:" -ForegroundColor Yellow
    Write-Host "  MODULES  — comma-separated MCP modules (github,figma,notion)"
    Write-Host ""
    return
}

# ============================================
# 1. Check / Install Claude Desktop
# ============================================
Write-Host ""
Write-Host "[1/$totalSteps] Checking Claude Desktop..." -ForegroundColor Yellow

$claudeDesktopPath = Find-ClaudeDesktop

if ($claudeDesktopPath) {
    Write-Host "  Claude Desktop is already installed." -ForegroundColor Green
} else {
    Write-Host "  Claude Desktop not found. Installing..." -ForegroundColor Yellow
    Write-Host ""

    # Download latest installer directly from Anthropic
    $downloadUrl = "https://downloads.claude.ai/releases/win32/ClaudeSetup.exe"
    $installerPath = "$env:TEMP\ClaudeSetup.exe"

    Write-Host "  Downloading latest Claude Desktop..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "  Download complete." -ForegroundColor Green

        Write-Host "  Running installer..." -ForegroundColor Yellow
        Start-Process -FilePath $installerPath

        # Wait for installer to complete (Squirrel extracts in background)
        Write-Host "  Waiting for installation to complete..." -ForegroundColor Gray
        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Seconds 1
            $claudeDesktopPath = Find-ClaudeDesktop
            if ($claudeDesktopPath) {
                Write-Host "  Claude Desktop installed successfully!" -ForegroundColor Green
                break
            }
            if ($i % 5 -eq 4) { Write-Host "." -NoNewline -ForegroundColor Gray }
        }
        if ($i % 5 -ne 0) { Write-Host "" }

        # Cleanup
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  Download failed: $_" -ForegroundColor Red
    }

    # Fallback: open download page
    if (-not $claudeDesktopPath) {
        Write-Host ""
        Write-Host "  Please download Claude Desktop manually:" -ForegroundColor White
        Write-Host "  https://claude.com/download" -ForegroundColor Cyan
        Write-Host ""
        Start-Process "https://claude.com/download"
        Write-Host "  Browser opened." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Press Enter after installing Claude Desktop"

        $claudeDesktopPath = Find-ClaudeDesktop
        if (-not $claudeDesktopPath) {
            Write-Host "  Claude Desktop still not detected." -ForegroundColor Red
            Write-Host "  Please install it and run this script again." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "  Press Enter to exit"
            return
        }
        Write-Host "  Claude Desktop detected!" -ForegroundColor Green
    }
}

# ============================================
# 2. Ensure config directory & file exist
# ============================================
Write-Host ""
Write-Host "[2/$totalSteps] Setting up configuration..." -ForegroundColor Yellow

$configDir = "$env:APPDATA\Claude"
$configPath = "$configDir\claude_desktop_config.json"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "  Created config directory: $configDir" -ForegroundColor Gray
}

if (-not (Test-Path $configPath)) {
    [System.IO.File]::WriteAllText($configPath, '{ "mcpServers": {} }', [System.Text.UTF8Encoding]::new($false))
    Write-Host "  Created default config: $configPath" -ForegroundColor Gray
} else {
    Write-Host "  Config file already exists." -ForegroundColor Gray
}

Write-Host "  OK" -ForegroundColor Green

# ============================================
# 3. Configure MCP modules (if requested)
# ============================================
if ($hasModules) {
    Write-Host ""
    Write-Host "[3/$totalSteps] Configuring MCP modules..." -ForegroundColor Yellow

    # Read existing config
    $configJson = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $configJson.mcpServers) {
        $configJson | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    foreach ($mod in $requestedModules) {
        switch ($mod) {
            "github" {
                Write-Host ""
                Write-Host "  [GitHub] Configuring MCP server..." -ForegroundColor Yellow

                # Check Node.js (required for npx)
                $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
                if (-not $nodeCheck) {
                    Write-Host "  Node.js not found. Installing via winget..." -ForegroundColor Yellow
                    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
                    if ($wingetCheck) {
                        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
                        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    } else {
                        Write-Host "  Please install Node.js manually: https://nodejs.org/" -ForegroundColor Red
                    }
                }

                # Also install gh CLI for better integration
                $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
                if (-not $ghCheck) {
                    Write-Host "  Installing GitHub CLI (gh)..." -ForegroundColor Yellow
                    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
                    if ($wingetCheck) {
                        winget install GitHub.cli --accept-source-agreements --accept-package-agreements
                        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    }
                }

                # Add GitHub MCP to config
                $configJson.mcpServers | Add-Member -NotePropertyName "github" -NotePropertyValue ([PSCustomObject]@{
                    command = "npx"
                    args = @("-y", "@modelcontextprotocol/server-github")
                    env = [PSCustomObject]@{
                        GITHUB_PERSONAL_ACCESS_TOKEN = ""
                    }
                }) -Force

                Write-Host "  GitHub MCP added to config." -ForegroundColor Green
                Write-Host "  Note: Set your GitHub token in config after setup." -ForegroundColor Gray
                Write-Host "  Config: $configPath" -ForegroundColor Gray
            }
            "figma" {
                Write-Host ""
                Write-Host "  [Figma] Configuring Remote MCP server..." -ForegroundColor Yellow

                $configJson.mcpServers | Add-Member -NotePropertyName "figma" -NotePropertyValue ([PSCustomObject]@{
                    url = "https://mcp.figma.com/mcp"
                }) -Force

                Write-Host "  Figma MCP added (OAuth in Claude Desktop)." -ForegroundColor Green
            }
            "notion" {
                Write-Host ""
                Write-Host "  [Notion] Configuring Remote MCP server..." -ForegroundColor Yellow

                $configJson.mcpServers | Add-Member -NotePropertyName "notion" -NotePropertyValue ([PSCustomObject]@{
                    url = "https://mcp.notion.com/mcp"
                }) -Force

                Write-Host "  Notion MCP added (OAuth in Claude Desktop)." -ForegroundColor Green
            }
            default {
                Write-Host "  Unknown module: $mod (skipped)" -ForegroundColor Yellow
            }
        }
    }

    # Write updated config (UTF-8 without BOM)
    $updatedJson = $configJson | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($configPath, $updatedJson, [System.Text.UTF8Encoding]::new($false))
    Write-Host ""
    Write-Host "  MCP config updated." -ForegroundColor Green
}

# ============================================
# Summary
# ============================================
$lastStep = $totalSteps
Write-Host ""
Write-Host "[$lastStep/$totalSteps] Done!" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Claude Desktop Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  App:    $claudeDesktopPath" -ForegroundColor Gray
Write-Host "  Config: $configPath" -ForegroundColor Gray
if ($hasModules) {
    Write-Host "  MCP:    $($requestedModules -join ', ')" -ForegroundColor Gray
}
Write-Host ""
if ($requestedModules -contains "github") {
    Write-Host "  [Action Required] GitHub MCP needs a personal access token." -ForegroundColor Yellow
    Write-Host "  1. Go to https://github.com/settings/tokens" -ForegroundColor White
    Write-Host "  2. Create a token with repo scope" -ForegroundColor White
    Write-Host "  3. Edit $configPath" -ForegroundColor White
    Write-Host "     Set GITHUB_PERSONAL_ACCESS_TOKEN to your token" -ForegroundColor White
    Write-Host ""
}
Write-Host "  Launch Claude Desktop and sign in to get started." -ForegroundColor White
Write-Host ""
Read-Host "  Press Enter to exit"
