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
    Write-Host "Please:" -ForegroundColor White
    Write-Host "  1. Make sure you restarted your computer after setup_basic.ps1" -ForegroundColor Gray
    Write-Host "  2. Start Docker Desktop" -ForegroundColor Gray
    Write-Host "  3. Wait for Docker to fully start (whale icon stops animating)" -ForegroundColor Gray
    Write-Host "  4. Run this script again" -ForegroundColor Gray
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
                docker run -it --rm -p 3000:3000 -v "${configDirUnix}:/app/.google-workspace" ghcr.io/popup-jacob/google-workspace-mcp:latest node -e "require('./dist/auth/oauth.js').getAuthenticatedClient().then(() => console.log('Authentication complete!')).catch(e => console.error(e))"

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
