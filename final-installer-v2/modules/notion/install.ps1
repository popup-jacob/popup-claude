# ============================================
# Notion MCP Module (Windows)
# ============================================

Write-Host "Notion MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Read Notion pages" -ForegroundColor Gray
Write-Host "  - Search databases" -ForegroundColor Gray
Write-Host "  - Query content" -ForegroundColor Gray
Write-Host ""

# Check Node.js
Write-Host "[Check] Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "  Node.js is required. Please install base module first." -ForegroundColor Red
    throw "Node.js not found"
}
Write-Host "  OK" -ForegroundColor Green

# Guide for Integration Token
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Notion Integration Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You need a Notion Integration Token. Follow these steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Go to https://www.notion.so/my-integrations" -ForegroundColor Gray
Write-Host "  2. Click '+ New integration'" -ForegroundColor Gray
Write-Host "  3. Select 'Internal' type (not Public)" -ForegroundColor Yellow
Write-Host "  4. Give it a name, select your workspace" -ForegroundColor Gray
Write-Host "  5. Click 'Submit'" -ForegroundColor Gray
Write-Host "  6. Copy the 'Internal Integration Secret' (secret_...)" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANT: Connect pages to your integration!" -ForegroundColor Yellow
Write-Host "  After setup, for each page you want Claude to access:" -ForegroundColor Gray
Write-Host "    1. Open the Notion page" -ForegroundColor Gray
Write-Host "    2. Click '...' (top-right)" -ForegroundColor Gray
Write-Host "    3. Click 'Connections'" -ForegroundColor Gray
Write-Host "    4. Select your integration name" -ForegroundColor Gray
Write-Host ""

$openPage = Read-Host "Open Notion Integrations page in browser? (y/n)"
if ($openPage -eq 'y' -or $openPage -eq 'Y') {
    Start-Process "https://www.notion.so/my-integrations"
    Write-Host "Create your integration and copy the token." -ForegroundColor Yellow
    Read-Host "Press Enter when ready"
}

Write-Host ""
$apiToken = Read-Host "Integration Token (secret_...)"

if ([string]::IsNullOrWhiteSpace($apiToken)) {
    Write-Host "Integration Token is required." -ForegroundColor Red
    throw "Token not provided"
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

$mcpConfig.mcpServers["notion"] = @{
    command = "npx"
    args = @("-y", "@notionhq/notion-mcp-server")
    env = @{
        NOTION_TOKEN = $apiToken
    }
}

$mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Notion MCP installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Remember to share pages with your integration!" -ForegroundColor Yellow
