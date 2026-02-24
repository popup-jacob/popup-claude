# ============================================
# Pencil Module — AI Design Canvas for IDE
# ============================================

Write-Host ""
Write-Host "Pencil Setup" -ForegroundColor Cyan
Write-Host "------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pencil is an AI design canvas inside your IDE:" -ForegroundColor White
Write-Host "  - Design directly in VS Code / Cursor" -ForegroundColor Gray
Write-Host "  - Generate production-ready code from designs" -ForegroundColor Gray
Write-Host "  - Version control designs with Git (.pen files)" -ForegroundColor Gray
Write-Host "  - MCP auto-connects when Pencil is running" -ForegroundColor Gray
Write-Host ""

# Check VS Code or Cursor
Write-Host "[Check] IDE..." -ForegroundColor Yellow
$hasCode = [bool](Get-Command code -ErrorAction SilentlyContinue)
$hasCursor = [bool](Get-Command cursor -ErrorAction SilentlyContinue)

if (-not $hasCode -and -not $hasCursor) {
    Write-Host "  VS Code or Cursor is required. Please install base module first." -ForegroundColor Red
    throw "No supported IDE found"
}

if ($hasCode) { Write-Host "  VS Code found" -ForegroundColor Green }
if ($hasCursor) { Write-Host "  Cursor found" -ForegroundColor Green }

# Install Pencil extension
Write-Host ""
Write-Host "[Install] Pencil extension..." -ForegroundColor Yellow

if ($hasCode) {
    Write-Host "  Installing for VS Code..." -ForegroundColor Gray
    code --install-extension highagency.pencildev 2>$null
    Write-Host "  VS Code - OK" -ForegroundColor Green
}

if ($hasCursor) {
    Write-Host "  Installing for Cursor..." -ForegroundColor Gray
    cursor --install-extension highagency.pencildev 2>$null
    Write-Host "  Cursor - OK" -ForegroundColor Green
}

# Activation guide
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pencil Activation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To activate Pencil:" -ForegroundColor White
Write-Host "  1. Open VS Code / Cursor" -ForegroundColor White
Write-Host "  2. Create a new .pen file (e.g. design.pen)" -ForegroundColor White
Write-Host "  3. Enter your email to activate" -ForegroundColor White
Write-Host ""
Write-Host "MCP server starts automatically when Pencil is running." -ForegroundColor Gray
Write-Host "No additional MCP configuration needed." -ForegroundColor Gray

# Summary
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Pencil setup complete!" -ForegroundColor Green
Write-Host ""
