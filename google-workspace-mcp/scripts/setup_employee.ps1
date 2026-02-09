# Google Workspace MCP - Employee Setup Script (Windows)
# Usage: powershell -ep bypass -File setup_employee.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Google Workspace MCP Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Docker check
Write-Host "[1/5] Checking Docker..." -ForegroundColor Yellow
$dockerCheck = docker --version 2>$null
if (-not $dockerCheck) {
    Write-Host "Docker is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop first:" -ForegroundColor White
    Write-Host "https://www.docker.com/products/docker-desktop/" -ForegroundColor Blue
    Write-Host ""
    Read-Host "Press Enter after installation"
}

# Docker Desktop running check
$dockerRunning = docker info 2>$null
if (-not $dockerRunning) {
    Write-Host "Docker Desktop is not running." -ForegroundColor Red
    Write-Host "Please start Docker Desktop." -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter after starting Docker"
}
Write-Host "Docker OK!" -ForegroundColor Green

# 2. Create folder
Write-Host ""
Write-Host "[2/5] Creating config folder..." -ForegroundColor Yellow
$configDir = "$env:USERPROFILE\.google-workspace"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Folder created: $configDir" -ForegroundColor Green
} else {
    Write-Host "Folder exists: $configDir" -ForegroundColor Green
}

# 3. client_secret.json check
Write-Host ""
Write-Host "[3/5] Checking client_secret.json..." -ForegroundColor Yellow
$clientSecretPath = "$configDir\client_secret.json"

if (-not (Test-Path $clientSecretPath)) {
    Write-Host ""
    Write-Host "client_secret.json file is required." -ForegroundColor White
    Write-Host "Copy the file from admin to this folder:" -ForegroundColor White
    Write-Host ""
    Write-Host "  $clientSecretPath" -ForegroundColor Cyan
    Write-Host ""

    # Open file explorer
    Start-Process explorer.exe -ArgumentList $configDir

    Write-Host "File explorer opened. Copy the file and press Enter."
    Read-Host

    if (-not (Test-Path $clientSecretPath)) {
        Write-Host "client_secret.json not found. Please try again." -ForegroundColor Red
        exit 1
    }
}
Write-Host "client_secret.json OK!" -ForegroundColor Green

# 4. Docker image check
Write-Host ""
Write-Host "[4/5] Checking Docker image..." -ForegroundColor Yellow
$imageExists = docker images -q google-workspace-mcp 2>$null

if (-not $imageExists) {
    Write-Host "Docker image not found." -ForegroundColor White
    Write-Host ""
    Write-Host "Select option:" -ForegroundColor White
    Write-Host "  1. Load from file (google-workspace-mcp.tar)" -ForegroundColor White
    Write-Host "  2. Build from source" -ForegroundColor White
    Write-Host "  3. Skip (setup later)" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "Select (1/2/3)"

    switch ($choice) {
        "1" {
            $tarFile = Read-Host "Enter tar file path (drag and drop)"
            $tarFile = $tarFile.Trim('"')
            if (Test-Path $tarFile) {
                Write-Host "Loading image..." -ForegroundColor Yellow
                docker load -i $tarFile
                Write-Host "Image loaded!" -ForegroundColor Green
            } else {
                Write-Host "File not found: $tarFile" -ForegroundColor Red
            }
        }
        "2" {
            $sourceDir = Read-Host "Enter source folder path"
            if (Test-Path "$sourceDir\Dockerfile") {
                Write-Host "Building image... (may take a few minutes)" -ForegroundColor Yellow
                Push-Location $sourceDir
                docker build -t google-workspace-mcp .
                Pop-Location
                Write-Host "Image built!" -ForegroundColor Green
            } else {
                Write-Host "Dockerfile not found: $sourceDir" -ForegroundColor Red
            }
        }
        "3" {
            Write-Host "Skipped. Please setup Docker image later." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Docker image OK!" -ForegroundColor Green
}

# 5. Create .mcp.json
Write-Host ""
Write-Host "[5/5] Creating Claude config..." -ForegroundColor Yellow

$mcpConfig = @"
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "$($configDir -replace '\\', '/'):/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
"@

# Global config (home folder)
$globalMcpPath = "$env:USERPROFILE\.mcp.json"
$mcpConfig | Out-File -FilePath $globalMcpPath -Encoding utf8
Write-Host "Config saved: $globalMcpPath" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Restart VS Code" -ForegroundColor White
Write-Host "  2. Ask Claude: 'Show my calendar'" -ForegroundColor White
Write-Host "  3. Login with your company account" -ForegroundColor White
Write-Host ""
Write-Host "Contact IT team if you have problems." -ForegroundColor Yellow
Write-Host ""
