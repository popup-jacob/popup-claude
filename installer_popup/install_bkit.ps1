# bkit Plugin Installation Script (Windows)
# Usage: powershell -ep bypass -File install_bkit.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  bkit Plugin Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Claude Code is installed
Write-Host "[1/3] Checking Claude Code..." -ForegroundColor Yellow
$claudeCheck = claude --version 2>$null
if (-not $claudeCheck) {
    Write-Host "Claude Code is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run install.ps1 first." -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host "Claude Code OK!" -ForegroundColor Green

# Add bkit marketplace
Write-Host ""
Write-Host "[2/3] Adding bkit marketplace..." -ForegroundColor Yellow
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>$null
Write-Host "Marketplace added!" -ForegroundColor Green

# Install bkit plugin
Write-Host ""
Write-Host "[3/3] Installing bkit plugin..." -ForegroundColor Yellow
claude plugin install bkit@bkit-marketplace
Write-Host "bkit installed!" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart VS Code to use bkit." -ForegroundColor White
Write-Host ""
