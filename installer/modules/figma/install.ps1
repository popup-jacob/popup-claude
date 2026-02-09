# ============================================
# Figma Module — Remote MCP Server + Auto OAuth
# ============================================

Write-Host ""
Write-Host "Figma MCP Server Setup" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "Figma MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Read Figma file contents" -ForegroundColor Gray
Write-Host "  - Inspect design components" -ForegroundColor Gray
Write-Host "  - Extract design tokens and styles" -ForegroundColor Gray
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
Write-Host "[Config] Registering Figma Remote MCP server..." -ForegroundColor Yellow
claude mcp add --transport http figma https://mcp.figma.com/mcp
Write-Host "  OK" -ForegroundColor Green

# Auto OAuth authentication
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Figma OAuth Login" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting automatic OAuth authentication..." -ForegroundColor White
Write-Host ""

# Load OAuth helper
. "$PSScriptRoot\..\shared\oauth-helper.ps1"

$oauthResult = Invoke-McpOAuth -ServerName "figma" -ServerUrl "https://mcp.figma.com/mcp"

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
if ($oauthResult) {
    Write-Host "Figma MCP setup complete! Ready to use." -ForegroundColor Green
} else {
    Write-Host "Figma MCP registered but OAuth login failed." -ForegroundColor Yellow
    Write-Host "You can retry by running this installer again," -ForegroundColor Yellow
    Write-Host "or manually authenticate via /mcp in Claude Code." -ForegroundColor Yellow
}
Write-Host ""
