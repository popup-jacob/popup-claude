# AI-Driven Work - MCP Setup Script (Windows)
# Installs: Google MCP, Jira/Confluence MCP (optional)
# Prerequisites: Docker Desktop must be running
# Usage: powershell -ep bypass -File setup_mcp.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI-Driven Work - MCP Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will set up:" -ForegroundColor White
Write-Host "  - Google MCP (Gmail, Calendar, Drive)" -ForegroundColor Gray
Write-Host "  - Jira/Confluence MCP" -ForegroundColor Gray
Write-Host ""

# Check Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerRunning = $true
    }
} catch {}

if (-not $dockerRunning) {
    Write-Host ""
    Write-Host "Docker is not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "How to start Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  - Press Windows key, type 'Docker Desktop', press Enter" -ForegroundColor Cyan
    Write-Host "  - Or click the whale icon in the taskbar (bottom right)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then:" -ForegroundColor White
    Write-Host "  1. Wait for Docker to fully start (whale icon stops animating)" -ForegroundColor Gray
    Write-Host "  2. Run this script again" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Docker OK!" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to continue"

# ============================================
# PART 1: Google MCP (Optional)
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 1: Google MCP (Optional)" -ForegroundColor Cyan
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
        # Admin path - Full Google Cloud setup
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Google Cloud Admin Setup" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        # Check gcloud CLI
        Write-Host "[1/6] Checking gcloud CLI..." -ForegroundColor Yellow
        $gcloudCheck = Get-Command gcloud -ErrorAction SilentlyContinue
        if (-not $gcloudCheck) {
            Write-Host "gcloud CLI is not installed." -ForegroundColor Red
            Write-Host ""
            $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
            if ($wingetCheck) {
                Write-Host "Installing gcloud CLI via winget..." -ForegroundColor Yellow
                winget install Google.CloudSDK --accept-source-agreements --accept-package-agreements
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                $gcloudCheck = Get-Command gcloud -ErrorAction SilentlyContinue
                if (-not $gcloudCheck) {
                    Write-Host ""
                    Write-Host "gcloud installed but not in PATH yet." -ForegroundColor Yellow
                    Write-Host "Please close this window and run the script again." -ForegroundColor White
                    Read-Host "Press Enter to exit"
                    exit 1
                }
            } else {
                Write-Host "winget not available. Opening download page..." -ForegroundColor Yellow
                Start-Process "https://cloud.google.com/sdk/docs/install"
                Write-Host "Please install Google Cloud SDK manually, then run this script again." -ForegroundColor White
                Read-Host "Press Enter to exit"
                exit 1
            }
        }
        Write-Host "gcloud CLI OK!" -ForegroundColor Green

        # Check gcloud login
        Write-Host ""
        Write-Host "[2/6] Checking gcloud login..." -ForegroundColor Yellow
        $ErrorActionPreference = "Continue"
        $account = (gcloud config get-value account 2>&1) | Out-String
        $account = $account.Trim()
        $ErrorActionPreference = "Stop"

        if (-not $account -or $account -match "unset" -or $account -eq "") {
            Write-Host "Not logged in. Opening browser for login..." -ForegroundColor White
            $ErrorActionPreference = "Continue"
            gcloud auth login --launch-browser 2>&1 | Out-Null
            $ErrorActionPreference = "Stop"
            Read-Host "Press Enter after completing login in the browser"
            $ErrorActionPreference = "Continue"
            $account = (gcloud config get-value account 2>&1) | Out-String
            $account = $account.Trim()
            $ErrorActionPreference = "Stop"
            if (-not $account -or $account -match "unset" -or $account -eq "") {
                Write-Host "Login failed or cancelled. Please try again." -ForegroundColor Red
                Read-Host "Press Enter to exit"
                exit 1
            }
        }
        if ($account -match "[\w\.\-]+@[\w\.\-]+") { $account = $Matches[0] }
        Write-Host "Logged in as: $account" -ForegroundColor Green

        # Ask Internal vs External
        Write-Host ""
        Write-Host "[3/6] Setup type selection..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Do you use Google Workspace (company email like @company.com)?" -ForegroundColor White
        Write-Host ""
        Write-Host "  1. Yes - I have a company email (@company.com)" -ForegroundColor White
        Write-Host "       -> Internal app (unlimited users, no token expiry)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  2. No - I use personal Gmail (@gmail.com)" -ForegroundColor White
        Write-Host "       -> External app (100 test users, 7-day token expiry)" -ForegroundColor DarkGray
        Write-Host ""
        $appTypeChoice = Read-Host "Select (1 or 2)"
        if ($appTypeChoice -eq "1") {
            $appType = "internal"
            Write-Host "Selected: Internal (Google Workspace)" -ForegroundColor Green
        } else {
            $appType = "external"
            Write-Host "Selected: External (Personal Gmail)" -ForegroundColor Green
        }

        # Create or select project
        Write-Host ""
        Write-Host "[4/6] Setting up Google Cloud project..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor White
        Write-Host "  1. Create new project" -ForegroundColor White
        Write-Host "  2. Use existing project" -ForegroundColor White
        Write-Host ""
        $projectChoice = Read-Host "Select (1 or 2)"

        $ErrorActionPreference = "Continue"
        if ($projectChoice -eq "1") {
            $projectId = "workspace-mcp-" + (Get-Random -Minimum 100000 -Maximum 999999)
            Write-Host "Creating project: $projectId" -ForegroundColor Yellow
            gcloud projects create $projectId --name="Google Workspace MCP" 2>&1 | Out-Null
            gcloud config set project $projectId 2>&1 | Out-Null
        } else {
            Write-Host ""
            Write-Host "Available projects:" -ForegroundColor White
            gcloud projects list --format="table(projectId,name)"
            Write-Host ""
            $projectId = Read-Host "Enter project ID"
            gcloud config set project $projectId 2>&1 | Out-Null
        }
        $ErrorActionPreference = "Stop"
        Write-Host "Project set: $projectId" -ForegroundColor Green

        # Enable APIs
        Write-Host ""
        Write-Host "[5/6] Enabling APIs (this may take a minute)..." -ForegroundColor Yellow
        $apis = @(
            "gmail.googleapis.com",
            "calendar-json.googleapis.com",
            "drive.googleapis.com",
            "docs.googleapis.com",
            "sheets.googleapis.com",
            "slides.googleapis.com"
        )
        $ErrorActionPreference = "Continue"
        foreach ($api in $apis) {
            Write-Host "  Enabling $api..." -ForegroundColor DarkGray
            gcloud services enable $api 2>&1 | Out-Null
        }
        $ErrorActionPreference = "Stop"
        Write-Host "All APIs enabled!" -ForegroundColor Green

        # OAuth Consent Screen (Manual)
        Write-Host ""
        Write-Host "[6/6] OAuth Consent Screen Setup (Manual step required)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  MANUAL STEP REQUIRED" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        $consoleUrl = "https://console.cloud.google.com/apis/credentials/consent?project=$projectId"
        Write-Host "Opening browser to OAuth consent screen..." -ForegroundColor White
        Start-Process $consoleUrl
        Start-Sleep -Seconds 2

        Write-Host ""
        Write-Host "Follow these steps in the browser:" -ForegroundColor White
        Write-Host ""
        Write-Host "  ** If you see 'Configure consent screen' button, click it first **" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] App Info" -ForegroundColor Cyan
        Write-Host "      - App name: Google Workspace MCP" -ForegroundColor White
        Write-Host "      - User support email: (select your email)" -ForegroundColor White
        Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  [2] Audience" -ForegroundColor Cyan
        if ($appType -eq "internal") {
            Write-Host "      - Select 'Internal'" -ForegroundColor Yellow
        } else {
            Write-Host "      - Select 'External'" -ForegroundColor Yellow
        }
        Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  [3] Contact Info" -ForegroundColor Cyan
        Write-Host "      - Email: (enter your email)" -ForegroundColor White
        Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  [4] Finish" -ForegroundColor Cyan
        Write-Host "      - Check the agreement box" -ForegroundColor White
        Write-Host "      -> Click 'Continue'" -ForegroundColor DarkGray

        if ($appType -eq "external") {
            Write-Host ""
            Write-Host "  [5] After setup, add TEST USERS:" -ForegroundColor Yellow
            Write-Host "      - Left menu: click 'Audience'" -ForegroundColor White
            Write-Host "      - Click 'Add Users' and add your email" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Read-Host "Press Enter when you have completed the above steps"

        # Create OAuth Client
        Write-Host ""
        Write-Host "[7/7] Creating OAuth Client..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "In the left menu, click 'Clients'" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Click '+ Create Client'" -ForegroundColor Cyan
        Write-Host "  [2] Application type: 'Desktop app'" -ForegroundColor White
        Write-Host "  [3] Name: any name (e.g. MCP Client)" -ForegroundColor White
        Write-Host "  [4] Click 'Create'" -ForegroundColor White
        Write-Host ""
        Write-Host "  [5] Click the created client name" -ForegroundColor Cyan
        Write-Host "  [6] Find 'Client Secret' section" -ForegroundColor White
        Write-Host "  [7] Click download icon (arrow down) to download JSON" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Save the file as:" -ForegroundColor Yellow
        Write-Host "  $env:USERPROFILE\.google-workspace\client_secret.json" -ForegroundColor Cyan
        Write-Host ""

        # Create config folder
        $configDir = "$env:USERPROFILE\.google-workspace"
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            Write-Host "Created folder: $configDir" -ForegroundColor Green
        }
        Start-Process explorer.exe -ArgumentList $configDir

        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Read-Host "Press Enter when you have saved client_secret.json"

        # Verify file exists
        $clientSecretPath = "$configDir\client_secret.json"
        if (Test-Path $clientSecretPath) {
            Write-Host "client_secret.json found!" -ForegroundColor Green
        } else {
            Write-Host "Warning: client_secret.json not found at $clientSecretPath" -ForegroundColor Yellow
            Write-Host "Make sure to save it there before continuing." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Admin Setup Complete!" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Summary:" -ForegroundColor White
        Write-Host "  - Project: $projectId" -ForegroundColor White
        Write-Host "  - App Type: $appType" -ForegroundColor White
        Write-Host "  - APIs: 6 enabled" -ForegroundColor White
        Write-Host ""

        if ($appType -eq "external") {
            Write-Host "Note (External app):" -ForegroundColor Yellow
            Write-Host "  - Add test user emails in OAuth consent screen" -ForegroundColor White
            Write-Host "  - Tokens expire every 7 days (re-login required)" -ForegroundColor White
            Write-Host ""
        }

        Write-Host "Now continuing with Docker setup..." -ForegroundColor Yellow
        Write-Host ""
    }

    # Employee path (also runs after Admin setup)
    if ($roleChoice -eq "2" -or $roleChoice -eq "1") {
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
            # Pull Docker image from ghcr.io
            Write-Host ""
            Write-Host "Pulling Google MCP Docker image..." -ForegroundColor Yellow
            docker pull ghcr.io/popup-jacob/google-workspace-mcp:latest
            Write-Host "Image pulled!" -ForegroundColor Green

            # Check if token.json exists, if not, run OAuth
            $tokenPath = "$configDir\token.json"
            if (-not (Test-Path $tokenPath)) {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Yellow
                Write-Host "  Google Login Required" -ForegroundColor Yellow
                Write-Host "========================================" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "A browser window will open for Google login." -ForegroundColor White
                Write-Host "After login, return here." -ForegroundColor White
                Write-Host ""
                Read-Host "Press Enter to start Google login"

                # Run container with port mapping for OAuth callback
                $configDirUnix = $configDir -replace '\\', '/'
                Write-Host "Starting Google authentication..." -ForegroundColor Yellow
                docker run -i --rm -p 3000:3000 -v "${configDirUnix}:/app/.google-workspace" ghcr.io/popup-jacob/google-workspace-mcp:latest node -e "require('./dist/auth/oauth.js').getAuthenticatedClient().then(() => { console.log('Authentication complete!'); process.exit(0); }).catch(e => { console.error(e); process.exit(1); })"

                if (Test-Path $tokenPath) {
                    Write-Host "Google login successful!" -ForegroundColor Green
                } else {
                    Write-Host "Google login may have failed. You can try again later." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Google already authenticated (token.json exists)" -ForegroundColor Green
            }

            # Create .mcp.json
            $imageExists = docker images -q ghcr.io/popup-jacob/google-workspace-mcp 2>$null
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
                    args = @("run", "-i", "--rm", "-v", "${configDirUnix}:/app/.google-workspace", "ghcr.io/popup-jacob/google-workspace-mcp:latest")
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
# PART 2: Jira/Confluence MCP (Optional)
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 2: Jira/Confluence MCP (Optional)" -ForegroundColor Cyan
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
Write-Host "  MCP Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now use Claude with:" -ForegroundColor White

# Check .mcp.json
$mcpConfigPath = "$env:USERPROFILE\.mcp.json"
if (Test-Path $mcpConfigPath) {
    $mcpJson = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
    if ($mcpJson.mcpServers."google-workspace") {
        Write-Host "  [OK] Google MCP (Gmail, Calendar, Drive)" -ForegroundColor Green
    }
    if ($mcpJson.mcpServers."atlassian") {
        Write-Host "  [OK] Jira/Confluence MCP" -ForegroundColor Green
    }
}

# Check Rovo MCP
$rovoCheck = claude mcp list 2>$null | Select-String "atlassian"
if ($rovoCheck) {
    Write-Host "  [OK] Atlassian Rovo MCP" -ForegroundColor Green
}

Write-Host ""
Write-Host "Test commands in Claude:" -ForegroundColor White
Write-Host "  - 'Show my calendar' (Google)" -ForegroundColor Gray
Write-Host "  - 'List Jira projects' (Jira)" -ForegroundColor Gray
Write-Host ""
cmd /c pause
