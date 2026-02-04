# ============================================
# Slack MCP Module (Windows)
# ============================================

Write-Host "Slack MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Send messages to channels" -ForegroundColor Gray
Write-Host "  - Read channel history" -ForegroundColor Gray
Write-Host "  - Manage conversations" -ForegroundColor Gray
Write-Host ""

# Check Node.js
Write-Host "[Check] Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "  Node.js is required. Please install base module first." -ForegroundColor Red
    throw "Node.js not found"
}
Write-Host "  OK" -ForegroundColor Green

# Guide for Bot Token
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Slack Bot Token Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You need a Slack Bot Token. Follow these steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Go to https://api.slack.com/apps" -ForegroundColor Gray
Write-Host "  2. Click 'Create New App' > 'From scratch'" -ForegroundColor Gray
Write-Host "  3. Give it a name, select your workspace" -ForegroundColor Gray
Write-Host "  4. Go to 'OAuth & Permissions' (left sidebar)" -ForegroundColor Gray
Write-Host "  5. Scroll down to 'Scopes' > 'Bot Token Scopes'" -ForegroundColor Gray
Write-Host "  6. Click 'Add an OAuth Scope' and add:" -ForegroundColor Gray
Write-Host "     - channels:history, channels:read" -ForegroundColor DarkGray
Write-Host "     - chat:write, groups:history" -ForegroundColor DarkGray
Write-Host "     - im:history, mpim:history" -ForegroundColor DarkGray
Write-Host "  7. Scroll up and click 'Install to Workspace'" -ForegroundColor Yellow
Write-Host "     (Token is generated AFTER this step!)" -ForegroundColor Yellow
Write-Host "  8. Allow permissions" -ForegroundColor Gray
Write-Host "  9. Copy 'Bot User OAuth Token' (xoxb-...)" -ForegroundColor Gray
Write-Host ""

$openPage = Read-Host "Open Slack API page in browser? (y/n)"
if ($openPage -eq 'y' -or $openPage -eq 'Y') {
    Start-Process "https://api.slack.com/apps"
    Write-Host "Create your app and copy the Bot Token." -ForegroundColor Yellow
    Read-Host "Press Enter when ready"
}

Write-Host ""
$botToken = Read-Host "Bot User OAuth Token (xoxb-...)"
Write-Host ""
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  How to find Team ID" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [Slack App]" -ForegroundColor White
Write-Host "    1. Click workspace name (top-left)" -ForegroundColor Gray
Write-Host "    2. Select 'Tools & settings'" -ForegroundColor Gray
Write-Host "    3. Select 'Manage apps'" -ForegroundColor Gray
Write-Host "    4. Browser opens - Team ID is in URL:" -ForegroundColor Gray
Write-Host ""
Write-Host "       https://app.slack.com/client/T07XXXXXX/..." -ForegroundColor DarkGray
Write-Host "                                    ^^^^^^^^^^" -ForegroundColor Yellow
Write-Host ""
$teamId = Read-Host "Team ID (starts with T)"

if ([string]::IsNullOrWhiteSpace($teamId)) {
    Write-Host "Team ID is required." -ForegroundColor Red
    throw "Team ID not provided"
}

if ([string]::IsNullOrWhiteSpace($botToken)) {
    Write-Host "Bot Token is required." -ForegroundColor Red
    throw "Bot Token not provided"
}

# Update .mcp.json
Write-Host ""
Write-Host "[Config] Updating .mcp.json..." -ForegroundColor Yellow
$mcpConfigPath = "$env:USERPROFILE\.mcp.json"

$mcpConfig = @{ mcpServers = @{} }
if (Test-Path $mcpConfigPath) {
    $existingJson = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
    if ($existingJson.mcpServers) {
        $existingJson.mcpServers.PSObject.Properties | ForEach-Object {
            $mcpConfig.mcpServers[$_.Name] = @{
                command = $_.Value.command
                args = @($_.Value.args)
                env = $_.Value.env
            }
        }
    }
}

$slackEnv = @{
    SLACK_BOT_TOKEN = $botToken
}
if (-not [string]::IsNullOrWhiteSpace($teamId)) {
    $slackEnv.SLACK_TEAM_ID = $teamId
}

$mcpConfig.mcpServers["slack"] = @{
    command = "npx"
    args = @("-y", "@modelcontextprotocol/server-slack")
    env = $slackEnv
}

$mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Slack MCP installation complete!" -ForegroundColor Green
