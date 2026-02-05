# ============================================
# GitHub CLI Module (Windows)
# ============================================

Write-Host "GitHub CLI (gh) lets Claude access:" -ForegroundColor White
Write-Host "  - View/create issues and PRs" -ForegroundColor Gray
Write-Host "  - Manage repositories" -ForegroundColor Gray
Write-Host "  - Run GitHub Actions" -ForegroundColor Gray
Write-Host ""

# Check/Install gh CLI
Write-Host "[Check] GitHub CLI (gh)..." -ForegroundColor Yellow
$ghCheck = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghCheck) {
    Write-Host "  gh CLI not found. Installing..." -ForegroundColor Yellow

    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCheck) {
        winget install GitHub.cli --accept-source-agreements --accept-package-agreements

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
        if (-not $ghCheck) {
            Write-Host ""
            Write-Host "gh CLI installed but not in PATH yet." -ForegroundColor Yellow
            Write-Host "Please close this window and run the script again." -ForegroundColor White
            throw "Restart required after gh installation"
        }
    } else {
        Write-Host "  winget not available." -ForegroundColor Red
        Write-Host "  Please install gh CLI manually: https://cli.github.com/" -ForegroundColor White
        Start-Process "https://cli.github.com/"
        throw "gh CLI installation required"
    }
}
Write-Host "  OK ($(gh --version | Select-Object -First 1))" -ForegroundColor Green

# Check auth status
Write-Host ""
Write-Host "[Check] GitHub authentication..." -ForegroundColor Yellow
$authStatus = gh auth status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Not logged in. Starting authentication..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A browser will open for GitHub login." -ForegroundColor White
    Write-Host ""

    gh auth login --hostname github.com --git-protocol https --web

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Authentication failed or cancelled." -ForegroundColor Red
        throw "GitHub authentication failed"
    }
    Write-Host "  Logged in successfully!" -ForegroundColor Green
} else {
    Write-Host "  Already logged in." -ForegroundColor Green
}

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "GitHub CLI installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: gh CLI is used directly by Claude via Bash tool." -ForegroundColor Gray
Write-Host "No MCP configuration needed." -ForegroundColor Gray
