# AI-Driven Work - Complete Setup Script (Windows)
# Usage: powershell -ep bypass -File setup_all.ps1

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as Administrator" -ForegroundColor Yellow
    cmd /c pause
    exit
}

# Running as admin - show welcome message
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI-Driven Work - Complete Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will install:" -ForegroundColor White
Write-Host "  - Node.js, Git, VS Code" -ForegroundColor Gray
Write-Host "  - Docker Desktop" -ForegroundColor Gray
Write-Host "  - Claude Code CLI" -ForegroundColor Gray
Write-Host "  - bkit Plugin" -ForegroundColor Gray
Write-Host "  - Google MCP (optional)" -ForegroundColor Gray
Write-Host "  - Jira/Confluence MCP (optional)" -ForegroundColor Gray
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
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements -h
    Write-Host ""
    Write-Host "Docker installed. Please RESTART your computer after setup." -ForegroundColor Yellow
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
# PART 3: Google MCP (Optional)
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 3: Google MCP (Optional)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Google MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Gmail (read, send emails)" -ForegroundColor Gray
Write-Host "  - Calendar (view, create events)" -ForegroundColor Gray
Write-Host "  - Drive (search, download files)" -ForegroundColor Gray
Write-Host "  - Docs, Sheets, Slides" -ForegroundColor Gray
Write-Host ""

$googleChoice = Read-Host "Set up Google MCP? (y/n)"

if ($googleChoice -eq "y" -or $googleChoice -eq "Y") {
    Write-Host ""
    Write-Host "What is your role?" -ForegroundColor White
    Write-Host "  1. Admin (setting up for the first time)" -ForegroundColor White
    Write-Host "  2. Employee (received files from admin)" -ForegroundColor White
    Write-Host ""
    $roleChoice = Read-Host "Select (1/2)"

    if ($roleChoice -eq "1") {
        # Admin path
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "  Admin Setup Required" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You need to set up Google Cloud Console first." -ForegroundColor White
        Write-Host ""
        Write-Host "Required steps:" -ForegroundColor White
        Write-Host "  1. Create Google Cloud project" -ForegroundColor Gray
        Write-Host "  2. Enable APIs (Gmail, Calendar, Drive, etc.)" -ForegroundColor Gray
        Write-Host "  3. Set up OAuth consent screen" -ForegroundColor Gray
        Write-Host "  4. Create OAuth Client ID" -ForegroundColor Gray
        Write-Host "  5. Download client_secret.json" -ForegroundColor Gray
        Write-Host ""

        $openGuide = Read-Host "Open setup guide in browser? (y/n)"
        if ($openGuide -eq "y" -or $openGuide -eq "Y") {
            Start-Process "https://console.cloud.google.com"
            Write-Host ""
            Write-Host "After completing the setup:" -ForegroundColor White
            Write-Host "  1. Run this script again" -ForegroundColor Gray
            Write-Host "  2. Select 'Employee' option" -ForegroundColor Gray
            Write-Host "  3. Provide client_secret.json" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Google MCP admin setup skipped for now." -ForegroundColor Yellow

    } else {
        # Employee path
        Write-Host ""
        Write-Host "Setting up Google MCP..." -ForegroundColor Yellow

        # Create config folder
        $configDir = "$env:USERPROFILE\.google-workspace"
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        # Check for client_secret.json
        $clientSecretPath = "$configDir\client_secret.json"
        if (-not (Test-Path $clientSecretPath)) {
            Write-Host ""
            Write-Host "client_secret.json file is required." -ForegroundColor White
            Write-Host "Copy the file from admin to this folder:" -ForegroundColor White
            Write-Host "  $clientSecretPath" -ForegroundColor Cyan
            Write-Host ""
            Start-Process explorer.exe -ArgumentList $configDir
            Write-Host "File explorer opened. Copy the file and press Enter."
            Read-Host

            if (-not (Test-Path $clientSecretPath)) {
                Write-Host "client_secret.json not found. Skipping Google MCP." -ForegroundColor Red
            }
        }

        if (Test-Path $clientSecretPath) {
            # Check Docker image
            $imageExists = docker images -q google-workspace-mcp 2>$null
            if (-not $imageExists) {
                Write-Host ""
                Write-Host "Docker image not found." -ForegroundColor White
                Write-Host "Do you have google-workspace-mcp.tar file?" -ForegroundColor White
                Write-Host ""
                $hasTar = Read-Host "(y/n)"

                if ($hasTar -eq "y" -or $hasTar -eq "Y") {
                    $tarFile = Read-Host "Enter tar file path (drag and drop)"
                    $tarFile = $tarFile.Trim('"')
                    if (Test-Path $tarFile) {
                        Write-Host "Loading image..." -ForegroundColor Yellow
                        docker load -i $tarFile
                        Write-Host "Image loaded!" -ForegroundColor Green
                    }
                } else {
                    Write-Host "Please get the tar file from admin. Skipping Google MCP." -ForegroundColor Yellow
                }
            }

            # Create .mcp.json if image exists
            $imageExists = docker images -q google-workspace-mcp 2>$null
            if ($imageExists) {
                $mcpConfigPath = "$env:USERPROFILE\.mcp.json"
                $configDirUnix = $configDir -replace '\\', '/'

                # Read existing config or create new
                $mcpConfig = @{ mcpServers = @{} }
                if (Test-Path $mcpConfigPath) {
                    $existingJson = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
                    if ($existingJson.mcpServers) {
                        $existingJson.mcpServers.PSObject.Properties | ForEach-Object {
                            $mcpConfig.mcpServers[$_.Name] = @{
                                command = $_.Value.command
                                args = @($_.Value.args)
                            }
                        }
                    }
                }

                # Add google-workspace
                $mcpConfig.mcpServers["google-workspace"] = @{
                    command = "docker"
                    args = @("run", "-i", "--rm", "-v", "${configDirUnix}:/app/.google-workspace", "google-workspace-mcp")
                }

                $mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding utf8
                Write-Host "Google MCP configured!" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "Google MCP skipped." -ForegroundColor Gray
}

# ============================================
# PART 4: Jira/Confluence MCP (Optional)
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 4: Jira/Confluence MCP (Optional)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Jira/Confluence MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Jira (view issues, create tasks)" -ForegroundColor Gray
Write-Host "  - Confluence (search, read pages)" -ForegroundColor Gray
Write-Host ""
Write-Host "Requirements:" -ForegroundColor White
Write-Host "  - Atlassian account" -ForegroundColor Gray
Write-Host "  - API token from: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Gray
Write-Host ""

$jiraChoice = Read-Host "Set up Jira/Confluence MCP? (y/n)"

if ($jiraChoice -eq "y" -or $jiraChoice -eq "Y") {
    Write-Host ""
    Write-Host "What is your role?" -ForegroundColor White
    Write-Host "  1. Non-developer (Rovo MCP - just login)" -ForegroundColor White
    Write-Host "  2. Developer (mcp-atlassian - Docker)" -ForegroundColor White
    Write-Host ""
    $jiraRoleChoice = Read-Host "Select (1/2)"

    if ($jiraRoleChoice -eq "1") {
        # Rovo MCP (Official Atlassian) - Non-developer
        Write-Host ""
        Write-Host "Setting up Atlassian Rovo MCP..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This will open Atlassian login in your browser." -ForegroundColor White
        Write-Host "Login with your Atlassian account to authorize." -ForegroundColor White
        Write-Host ""

        claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse

        Write-Host ""
        Write-Host "Rovo MCP configured!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Guide: https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/" -ForegroundColor Gray

    } else {
        # mcp-atlassian - Developer
        Write-Host ""
        Write-Host "Setting up mcp-atlassian..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You need an API token. Get one from:" -ForegroundColor White
        Write-Host "  https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Cyan
        Write-Host ""

        $openToken = Read-Host "Open API token page in browser? (y/n)"
        if ($openToken -eq "y" -or $openToken -eq "Y") {
            Start-Process "https://id.atlassian.com/manage-profile/security/api-tokens"
            Write-Host "Create a token and copy it."
            Read-Host "Press Enter when ready"
        }

        Write-Host ""
        $confluenceUrl = Read-Host "Confluence URL (e.g. https://company.atlassian.net/wiki)"
        $jiraUrl = Read-Host "Jira URL (e.g. https://company.atlassian.net)"
        $email = Read-Host "Your email"
        $apiToken = Read-Host "API token"

        # Pull mcp-atlassian image
        Write-Host ""
        Write-Host "Pulling mcp-atlassian Docker image..." -ForegroundColor Yellow
        docker pull ghcr.io/sooperset/mcp-atlassian:latest 2>$null

        # Add to .mcp.json
        $mcpConfigPath = "$env:USERPROFILE\.mcp.json"

        # Read existing config or create new
        $mcpConfig = @{ mcpServers = @{} }
        if (Test-Path $mcpConfigPath) {
            $existingJson = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
            if ($existingJson.mcpServers) {
                $existingJson.mcpServers.PSObject.Properties | ForEach-Object {
                    $mcpConfig.mcpServers[$_.Name] = @{
                        command = $_.Value.command
                        args = @($_.Value.args)
                    }
                }
            }
        }

        # Add atlassian
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
        Write-Host "Jira/Confluence MCP configured!" -ForegroundColor Green
    }
} else {
    Write-Host "Jira/Confluence MCP skipped." -ForegroundColor Gray
}

# ============================================
# COMPLETE
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
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
    Write-Host "  [!] Docker - not found (restart may be required)" -ForegroundColor Yellow
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
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. RESTART your computer (required for Docker)" -ForegroundColor Yellow
Write-Host "  2. Start Docker Desktop" -ForegroundColor Gray
Write-Host "  3. Open VS Code and test Claude" -ForegroundColor Gray
Write-Host ""
Write-Host "Test commands in Claude:" -ForegroundColor White
Write-Host "  - 'Show my calendar' (Google)" -ForegroundColor Gray
Write-Host "  - 'List Jira projects' (Jira)" -ForegroundColor Gray
Write-Host ""
cmd /c pause
