# ============================================
# Atlassian (Jira + Confluence) MCP Module
# ============================================
# Auto-detects Docker and recommends best option

Write-Host "Atlassian MCP lets Claude access:" -ForegroundColor White
Write-Host "  - Jira (view issues, create tasks)" -ForegroundColor Gray
Write-Host "  - Confluence (search, read pages)" -ForegroundColor Gray
Write-Host ""

# ============================================
# Auto-detect Docker
# ============================================
$hasDocker = [bool](Get-Command docker -ErrorAction SilentlyContinue)
$dockerRunning = $false
if ($hasDocker) {
    $null = docker info 2>&1
    $dockerRunning = ($LASTEXITCODE -eq 0)
}

# ============================================
# Show options based on Docker status
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
if ($hasDocker) {
    Write-Host "  Docker가 설치되어 있습니다!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "설치 방식을 선택하세요:" -ForegroundColor White
    Write-Host "  1. 로컬 설치 (권장) - Docker 사용, 내 컴퓨터에서 실행" -ForegroundColor Green
    Write-Host "  2. 간편 설치 - 브라우저 로그인만" -ForegroundColor White
} else {
    Write-Host "  Docker가 설치되어 있지 않습니다." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "설치 방식을 선택하세요:" -ForegroundColor White
    Write-Host "  1. 간편 설치 (권장) - 브라우저 로그인만, 추가 설치 없음" -ForegroundColor Green
    Write-Host "  2. 로컬 설치 - Docker 설치 필요" -ForegroundColor White
}
Write-Host ""
$choice = Read-Host "선택 (1/2)"

# Determine which mode based on Docker status and choice
$useDocker = $false
if ($hasDocker) {
    # Docker 있음: 1=Docker, 2=Rovo
    if ($choice -ne "2") { $useDocker = $true }
} else {
    # Docker 없음: 1=Rovo, 2=Docker
    if ($choice -eq "2") { $useDocker = $true }
}

# ============================================
# Execute selected mode
# ============================================
if ($useDocker) {
    # ========================================
    # MCP-ATLASSIAN (Docker)
    # ========================================

    # Check Docker is running
    if (-not $hasDocker) {
        Write-Host ""
        Write-Host "Docker가 설치되어 있지 않습니다!" -ForegroundColor Red
        Write-Host "먼저 Docker Desktop을 설치해주세요:" -ForegroundColor White
        Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
        Write-Host ""
        throw "Docker is required for local installation"
    }

    if (-not $dockerRunning) {
        Write-Host ""
        Write-Host "Docker가 실행되고 있지 않습니다!" -ForegroundColor Yellow
        Write-Host "Docker Desktop을 시작해주세요." -ForegroundColor White
        Write-Host ""
        $waitDocker = Read-Host "Docker 시작 후 Enter를 누르세요 (취소: q)"
        if ($waitDocker -eq 'q') { throw "Cancelled by user" }

        $null = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker가 아직 실행되지 않았습니다." -ForegroundColor Red
            throw "Docker is not running"
        }
    }
    Write-Host ""
    Write-Host "[OK] Docker 확인 완료" -ForegroundColor Green

    Write-Host ""
    Write-Host "Setting up mcp-atlassian (Docker)..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "API 토큰이 필요합니다. 아래에서 생성하세요:" -ForegroundColor White
    Write-Host "  https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Cyan
    Write-Host ""

    $openToken = Read-Host "브라우저에서 API 토큰 페이지 열기? (y/n)"
    if ($openToken -eq "y" -or $openToken -eq "Y") {
        Start-Process "https://id.atlassian.com/manage-profile/security/api-tokens"
        Write-Host "토큰을 생성하고 복사하세요." -ForegroundColor Yellow
        Read-Host "준비되면 Enter"
    }

    Write-Host ""
    $atlassianUrl = Read-Host "Atlassian URL (예: https://company.atlassian.net)"
    $atlassianUrl = $atlassianUrl.TrimEnd('/')
    $jiraUrl = $atlassianUrl
    $confluenceUrl = "$atlassianUrl/wiki"

    Write-Host "  Jira: $jiraUrl" -ForegroundColor Gray
    Write-Host "  Confluence: $confluenceUrl" -ForegroundColor Gray
    Write-Host ""
    $email = Read-Host "이메일"
    $apiToken = Read-Host "API 토큰"

    # Pull Docker image
    Write-Host ""
    Write-Host "[Pull] mcp-atlassian Docker 이미지 다운로드..." -ForegroundColor Yellow
    docker pull ghcr.io/sooperset/mcp-atlassian:latest 2>$null
    Write-Host "  OK" -ForegroundColor Green

    # Update .mcp.json
    Write-Host ""
    Write-Host "[Config] .mcp.json 업데이트..." -ForegroundColor Yellow
    $mcpConfigPath = "$env:USERPROFILE\.mcp.json"

    $mcpConfig = @{ mcpServers = @{} }
    if (Test-Path $mcpConfigPath) {
        $existingJson = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
        if ($existingJson.mcpServers) {
            $existingJson.mcpServers.PSObject.Properties | ForEach-Object {
                $mcpConfig.mcpServers[$_.Name] = @{
                    command = $_.Value.command
                    args = @($_.Value.args)
                }
            }
        }
    }

    $mcpConfig.mcpServers["atlassian"] = @{
        command = "docker"
        args = @(
            "run", "-i", "--rm",
            "-e", "CONFLUENCE_URL=$confluenceUrl",
            "-e", "CONFLUENCE_USERNAME=$email",
            "-e", "CONFLUENCE_API_TOKEN=$apiToken",
            "-e", "JIRA_URL=$jiraUrl",
            "-e", "JIRA_USERNAME=$email",
            "-e", "JIRA_API_TOKEN=$apiToken",
            "ghcr.io/sooperset/mcp-atlassian:latest"
        )
    }

    $mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding utf8
    Write-Host "  OK" -ForegroundColor Green

} else {
    # ========================================
    # ROVO MCP (Official Atlassian SSE)
    # ========================================
    Write-Host ""
    Write-Host "Setting up Atlassian Rovo MCP..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "브라우저에서 Atlassian 로그인 페이지가 열립니다." -ForegroundColor White
    Write-Host "로그인하여 권한을 승인해주세요." -ForegroundColor White
    Write-Host ""

    claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse

    Write-Host ""
    Write-Host "  Rovo MCP 설정 완료!" -ForegroundColor Green
    Write-Host ""
    Write-Host "가이드: https://support.atlassian.com/atlassian-rovo-mcp-server/" -ForegroundColor Gray
}

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Atlassian MCP 설치 완료!" -ForegroundColor Green
