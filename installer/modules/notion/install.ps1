# ============================================
# Notion MCP Module (Windows) — Remote MCP + Auto OAuth
# ============================================

Write-Host "Notion MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Read Notion pages" -ForegroundColor Gray
Write-Host "  - Search databases" -ForegroundColor Gray
Write-Host "  - Query content" -ForegroundColor Gray
Write-Host ""

# Check Claude CLI
Write-Host "[Check] Claude CLI..." -ForegroundColor Yellow
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  Claude CLI is required. Please install base module first." -ForegroundColor Red
    throw "Claude CLI not found"
}
Write-Host "  OK" -ForegroundColor Green

# Register Remote MCP server
Write-Host ""
Write-Host "[Config] Registering Notion Remote MCP server..." -ForegroundColor Yellow
claude mcp add --transport http notion https://mcp.notion.com/mcp
Write-Host "  OK" -ForegroundColor Green

# Auto OAuth authentication
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Notion OAuth Login" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting automatic OAuth authentication..." -ForegroundColor White
Write-Host ""

# Load OAuth helper
. "$PSScriptRoot\..\shared\oauth-helper.ps1"

$oauthResult = Invoke-McpOAuth -ServerName "notion" -ServerUrl "https://mcp.notion.com/mcp"

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
if ($oauthResult) {
    Write-Host "Notion MCP setup complete! Ready to use." -ForegroundColor Green
} else {
    Write-Host "Notion MCP registered but OAuth login failed." -ForegroundColor Yellow
    Write-Host "You can retry by running this installer again," -ForegroundColor Yellow
    Write-Host "or manually authenticate via /mcp in Claude Code." -ForegroundColor Yellow
}
Write-Host ""
