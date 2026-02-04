# ============================================
# Figma Module - MCP Server Installation
# ============================================

Write-Host ""
Write-Host "Figma MCP Server Setup" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. Get Figma Personal Access Token
# ============================================
Write-Host "Figma Personal Access Token is required." -ForegroundColor Yellow
Write-Host ""
Write-Host "How to get your token:" -ForegroundColor White
Write-Host "  1. Go to https://www.figma.com/developers/api#access-tokens" -ForegroundColor Gray
Write-Host "  2. Click 'Get personal access token'" -ForegroundColor Gray
Write-Host "  3. Copy the generated token" -ForegroundColor Gray
Write-Host ""

$accessToken = Read-Host "Enter your Figma Personal Access Token"

if ([string]::IsNullOrWhiteSpace($accessToken)) {
    Write-Host "No token provided. Skipping Figma setup." -ForegroundColor Yellow
    return
}

# ============================================
# 2. Update .mcp.json
# ============================================
Write-Host ""
Write-Host "Configuring MCP..." -ForegroundColor Yellow

$mcpConfigPath = "$env:USERPROFILE\.mcp.json"

# Load existing config or create new
if (Test-Path $mcpConfigPath) {
    $mcpConfig = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
} else {
    $mcpConfig = @{ mcpServers = @{} }
}

# Ensure mcpServers exists
if (-not $mcpConfig.mcpServers) {
    $mcpConfig | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{} -Force
}

# Add Figma server config
$mcpConfig.mcpServers | Add-Member -NotePropertyName "figma" -NotePropertyValue @{
    command = "npx"
    args = @("-y", "@anthropic/mcp-figma")
    env = @{
        FIGMA_PERSONAL_ACCESS_TOKEN = $accessToken
    }
} -Force

# Save config
$mcpConfig | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigPath -Encoding UTF8

Write-Host "  OK - Figma MCP configured" -ForegroundColor Green
Write-Host ""
Write-Host "You can now use Claude to:" -ForegroundColor White
Write-Host "  - Read Figma file contents" -ForegroundColor Gray
Write-Host "  - Inspect design components" -ForegroundColor Gray
Write-Host "  - Extract design tokens and styles" -ForegroundColor Gray
Write-Host ""
