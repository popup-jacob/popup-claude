# Google Workspace MCP - Admin Setup Script (Windows)
# Usage: powershell -ExecutionPolicy Bypass -File setup_admin.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Google Workspace MCP - Admin Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Step 1: Check and Install gcloud CLI
# ============================================
Write-Host "[1/6] Checking gcloud CLI..." -ForegroundColor Yellow

$gcloudCheck = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloudCheck) {
    Write-Host "gcloud CLI is not installed." -ForegroundColor Red
    Write-Host ""

    # Check if winget is available
    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCheck) {
        Write-Host "Installing gcloud CLI via winget..." -ForegroundColor Yellow
        Write-Host "(This may take a few minutes)" -ForegroundColor DarkGray
        Write-Host ""

        winget install Google.CloudSDK --accept-source-agreements --accept-package-agreements

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # Check again
        $gcloudCheck = Get-Command gcloud -ErrorAction SilentlyContinue
        if (-not $gcloudCheck) {
            Write-Host ""
            Write-Host "gcloud installed but not in PATH yet." -ForegroundColor Yellow
            Write-Host "Please close this window and run the script again." -ForegroundColor White
            Write-Host ""
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Host "winget not available. Opening download page..." -ForegroundColor Yellow
        Write-Host ""
        Start-Process "https://cloud.google.com/sdk/docs/install"
        Write-Host "Please install Google Cloud SDK manually, then run this script again." -ForegroundColor White
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Write-Host "gcloud CLI OK!" -ForegroundColor Green

# ============================================
# Step 2: Check gcloud login
# ============================================
Write-Host ""
Write-Host "[2/6] Checking gcloud login..." -ForegroundColor Yellow

# Temporarily allow errors for gcloud commands
$ErrorActionPreference = "Continue"
$account = (gcloud config get-value account 2>&1) | Out-String
$account = $account.Trim()
$ErrorActionPreference = "Stop"

# Check if not logged in (account contains "unset" or is empty)
if (-not $account -or $account -match "unset" -or $account -eq "") {
    Write-Host "Not logged in. Opening browser for login..." -ForegroundColor White
    Write-Host ""
    Write-Host "A browser window will open. Please log in with your Google account." -ForegroundColor Yellow
    Write-Host ""

    # Force browser launch for login
    $ErrorActionPreference = "Continue"
    gcloud auth login --launch-browser 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"

    Write-Host ""
    Read-Host "Press Enter after completing login in the browser"

    # Check again after login
    $ErrorActionPreference = "Continue"
    $account = (gcloud config get-value account 2>&1) | Out-String
    $account = $account.Trim()
    $ErrorActionPreference = "Stop"

    # If still not logged in, exit
    if (-not $account -or $account -match "unset" -or $account -eq "") {
        Write-Host ""
        Write-Host "Login failed or cancelled. Please try again." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Extract just the email from account (remove any error messages)
if ($account -match "[\w\.\-]+@[\w\.\-]+") {
    $account = $Matches[0]
}
Write-Host "Logged in as: $account" -ForegroundColor Green

# ============================================
# Step 3: Ask Internal vs External
# ============================================
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

$choice = Read-Host "Select (1 or 2)"

if ($choice -eq "1") {
    $appType = "internal"
    Write-Host "Selected: Internal (Google Workspace)" -ForegroundColor Green
} else {
    $appType = "external"
    Write-Host "Selected: External (Personal Gmail)" -ForegroundColor Green
}

# ============================================
# Step 4: Create or select project
# ============================================
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

# ============================================
# Step 5: Enable APIs
# ============================================
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

# ============================================
# Step 6: OAuth Consent Screen (Manual)
# ============================================
Write-Host ""
Write-Host "[6/6] OAuth Consent Screen Setup (Manual step required)" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MANUAL STEP REQUIRED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$consoleUrl = "https://console.cloud.google.com/apis/credentials/consent?project=$projectId"

Write-Host "Opening browser to OAuth consent screen..." -ForegroundColor White
Write-Host ""
Start-Process $consoleUrl
Start-Sleep -Seconds 2

Write-Host "Follow these steps in the browser:" -ForegroundColor White
Write-Host ""
Write-Host "  ** If you see 'Configure consent screen' button, click it first **" -ForegroundColor Yellow
Write-Host ""

if ($appType -eq "internal") {
    Write-Host "  [1] App Info" -ForegroundColor Cyan
    Write-Host "      - App name: Google Workspace MCP" -ForegroundColor White
    Write-Host "      - User support email: (select your email)" -ForegroundColor White
    Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Audience" -ForegroundColor Cyan
    Write-Host "      - Select 'Internal'" -ForegroundColor Yellow
    Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Contact Info" -ForegroundColor Cyan
    Write-Host "      - Email: (enter your email)" -ForegroundColor White
    Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Finish" -ForegroundColor Cyan
    Write-Host "      - Check the agreement box" -ForegroundColor White
    Write-Host "      -> Click 'Continue'" -ForegroundColor DarkGray
} else {
    Write-Host "  [1] App Info" -ForegroundColor Cyan
    Write-Host "      - App name: Google Workspace MCP" -ForegroundColor White
    Write-Host "      - User support email: (select your email)" -ForegroundColor White
    Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Audience" -ForegroundColor Cyan
    Write-Host "      - Select 'External'" -ForegroundColor Yellow
    Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Contact Info" -ForegroundColor Cyan
    Write-Host "      - Email: (enter your email)" -ForegroundColor White
    Write-Host "      -> Click 'Next'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Finish" -ForegroundColor Cyan
    Write-Host "      - Check the agreement box" -ForegroundColor White
    Write-Host "      -> Click 'Continue'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [5] After setup, add TEST USERS:" -ForegroundColor Yellow
    Write-Host "      - Left menu: click 'Audience'" -ForegroundColor White
    Write-Host "      - Click 'Add Users' and add your email" -ForegroundColor White
}

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Read-Host "Press Enter when you have completed the above steps"

# ============================================
# Step 7: Create OAuth Client
# ============================================
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

# Create folder if not exists
$configDir = "$env:USERPROFILE\.google-workspace"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Created folder: $configDir" -ForegroundColor Green
}

# Open folder
Start-Process explorer.exe -ArgumentList $configDir

Write-Host "----------------------------------------" -ForegroundColor DarkGray
Read-Host "Press Enter when you have saved client_secret.json"

# Verify file exists
$clientSecretPath = "$configDir\client_secret.json"
if (Test-Path $clientSecretPath) {
    Write-Host "client_secret.json found!" -ForegroundColor Green
} else {
    Write-Host "Warning: client_secret.json not found at $clientSecretPath" -ForegroundColor Yellow
    Write-Host "Make sure to save it there before running employee setup." -ForegroundColor Yellow
}

# ============================================
# Done
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Admin Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  - Project: $projectId" -ForegroundColor White
Write-Host "  - App Type: $appType" -ForegroundColor White
Write-Host "  - APIs: 6 enabled" -ForegroundColor White
Write-Host "  - OAuth: Configured" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run setup_mcp.ps1 (for yourself)" -ForegroundColor White
Write-Host "  2. Share client_secret.json with team members" -ForegroundColor White
Write-Host "  3. Team members run setup_mcp.ps1" -ForegroundColor White
Write-Host ""

if ($appType -eq "external") {
    Write-Host "Note (External app):" -ForegroundColor Yellow
    Write-Host "  - Add test user emails in OAuth consent screen" -ForegroundColor White
    Write-Host "  - Tokens expire every 7 days (re-login required)" -ForegroundColor White
    Write-Host ""
}
