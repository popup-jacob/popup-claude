# ============================================
# Preflight Environment Checks (Windows)
# ============================================
# Purpose: Diagnose environment before installation, warn or abort on issues
# Called by: install.ps1 before base module execution
# Returns: $preflight object with check results

$preflight = @{
    isAdmin          = $false
    isSMode          = $false
    isLTSC           = $false
    isOnline         = $true
    hasProxy         = $false
    proxyServer      = ""
    isMITM           = $false
    isVirtualization = $true
    freeSpaceGB      = 0
    isOneDriveSynced = $false
    hasNvm           = $false
    hasDockerToolbox = $false
    hasNpmClaude     = $false
    hasCodeInsiders  = $false
    hasCode          = $false
    hasAgy           = $false
    isDomainJoined   = $false
    avProducts       = @()
    hasGPRestriction = $false
    hasAppLocker     = $false
    warnings         = @()
    fatal            = $null
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host ""
Write-Host "============================================" -ForegroundColor DarkGray
Write-Host "  Environment Pre-check" -ForegroundColor White
Write-Host "============================================" -ForegroundColor DarkGray

# ============================================
# Check 1: Windows Version / Edition
# ============================================
Write-Host "  Checking Windows version..." -ForegroundColor Gray
try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $buildNumber = [int]$osInfo.BuildNumber
    $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).EditionID

    # S Mode detection
    $ciPolicy = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -ErrorAction SilentlyContinue
    if ($ciPolicy -and $ciPolicy.SkuPolicyRequired -eq 1) {
        $preflight.isSMode = $true
        $preflight.fatal = "Windows S Mode detected. Cannot install software outside Microsoft Store. Disable S Mode first: Settings > System > Activation"
    }

    # LTSC/Server detection
    if ($edition -like "*LTSC*" -or $edition -like "*Server*") {
        $preflight.isLTSC = $true
        $preflight.warnings += "LTSC/Server edition detected. winget may not be pre-installed. Manual install may be required."
    }

    # Minimum build check (1809 = build 17763)
    if ($buildNumber -lt 17763) {
        $preflight.fatal = "Windows 10 version 1809 or later required (current build: $buildNumber). Please update Windows."
    }
} catch {
    # Non-fatal: continue without version check
}

# ============================================
# Check 2: Administrator Rights
# ============================================
Write-Host "  Checking admin rights..." -ForegroundColor Gray
$preflight.isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $preflight.isAdmin) {
    if ($script:needsDocker) {
        $preflight.warnings += "Not running as admin. WSL/Docker installation requires administrator privileges. Recommend: Run as Administrator."
    } else {
        $preflight.warnings += "Not running as admin. Some programs will be installed with --scope user."
    }
}

# ============================================
# Check 3: PowerShell Execution Policy
# ============================================
Write-Host "  Checking execution policy..." -ForegroundColor Gray
try {
    # Constrained Language Mode check
    if ($ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage") {
        $preflight.fatal = "PowerShell Constrained Language Mode detected. Script cannot run. Contact IT administrator."
    }

    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq "Restricted") {
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        } catch {
            $preflight.warnings += "Execution policy is Restricted. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        }
    }
} catch {
    # Non-fatal
}

# ============================================
# Check 4: Internet Connectivity
# ============================================
Write-Host "  Checking internet connection..." -ForegroundColor Gray
try {
    $testUrls = @(
        "cdn.winget.microsoft.com",
        "marketplace.visualstudio.com",
        "claude.ai"
    )
    $failedUrls = @()
    $anySuccess = $false

    foreach ($url in $testUrls) {
        $result = Test-NetConnection -ComputerName $url -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            $anySuccess = $true
        } else {
            $failedUrls += $url
        }
    }

    if (-not $anySuccess) {
        $preflight.isOnline = $false
        $preflight.fatal = "No internet connection. All tested servers unreachable. Please connect to the internet."
    } elseif ($failedUrls.Count -gt 0) {
        $preflight.warnings += "Some servers unreachable (firewall?): $($failedUrls -join ', '). Some downloads may fail."
    }
} catch {
    # If Test-NetConnection fails entirely, assume online and let install steps handle errors
}

# ============================================
# Check 5: Proxy / Firewall Detection
# ============================================
Write-Host "  Checking proxy settings..." -ForegroundColor Gray
try {
    $proxySettings = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
    if ($proxySettings.ProxyEnable -eq 1) {
        $preflight.hasProxy = $true
        $preflight.proxyServer = $proxySettings.ProxyServer
    }
    if ($env:HTTP_PROXY -or $env:HTTPS_PROXY) {
        $preflight.hasProxy = $true
        $preflight.proxyServer = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } else { $env:HTTP_PROXY }
    }
    if ($preflight.hasProxy) {
        $preflight.warnings += "Proxy detected ($($preflight.proxyServer)). If downloads fail, check proxy settings for winget/npm."
    }
} catch {
    # Non-fatal
}

# ============================================
# Check 6: SSL MITM Detection
# ============================================
Write-Host "  Checking SSL certificates..." -ForegroundColor Gray
try {
    $request = [System.Net.HttpWebRequest]::Create("https://claude.ai")
    $request.Timeout = 5000
    $response = $request.GetResponse()
    $cert = $request.ServicePoint.Certificate
    $issuer = $cert.Issuer
    $response.Close()

    $knownCAs = @("DigiCert", "Let's Encrypt", "Cloudflare", "Amazon", "Google Trust", "GlobalSign", "Sectigo", "Comodo")
    $isTrustedCA = $false
    foreach ($ca in $knownCAs) {
        if ($issuer -like "*$ca*") { $isTrustedCA = $true; break }
    }
    if (-not $isTrustedCA) {
        $preflight.isMITM = $true
        $preflight.warnings += @(
            "Corporate SSL inspection detected (issuer: $issuer).",
            "  If certificate errors occur during install:",
            "  - git: git config --global http.sslVerify false (temporary)",
            "  - npm: npm config set strict-ssl false (temporary)",
            "  - VS Code: set NODE_EXTRA_CA_CERTS environment variable",
            "  Or ask IT admin to install corporate CA certificate."
        ) -join "`n"
    }
} catch {
    # Connection failed - handled by Check 4
}

# ============================================
# Check 7: BIOS Virtualization (WSL/Docker)
# ============================================
if ($script:needsDocker) {
    Write-Host "  Checking virtualization support..." -ForegroundColor Gray
    try {
        $computerInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $vmEnabled = $computerInfo.HypervisorPresent

        if (-not $vmEnabled) {
            $proc = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
            $vmEnabled = $proc.VirtualizationFirmwareEnabled
        }

        $preflight.isVirtualization = $vmEnabled
        if (-not $vmEnabled) {
            $preflight.warnings += @(
                "BIOS virtualization (VT-x/AMD-V) appears disabled.",
                "  Required for WSL and Docker Desktop.",
                "  Enable in BIOS settings:",
                "    Intel: VT-x or Intel Virtualization Technology",
                "    AMD: AMD-V or SVM Mode"
            ) -join "`n"
        }
    } catch {
        # Cannot determine - skip
    }
}

# ============================================
# Check 8: Disk Space
# ============================================
Write-Host "  Checking disk space..." -ForegroundColor Gray
try {
    $freeGB = [math]::Round((Get-PSDrive C -ErrorAction SilentlyContinue).Free / 1GB, 1)
    $preflight.freeSpaceGB = $freeGB

    $requiredGB = 1.5
    if ($script:needsDocker) { $requiredGB = 4.0 }

    if ($freeGB -lt $requiredGB) {
        $preflight.warnings += "Low disk space: ${freeGB}GB free on C: drive. Minimum ${requiredGB}GB recommended."
    }
} catch {
    # Non-fatal
}

# ============================================
# Check 9: OneDrive Sync Path Conflict
# ============================================
Write-Host "  Checking OneDrive sync..." -ForegroundColor Gray
try {
    $userProfile = $env:USERPROFILE
    $oneDrivePath = if ($env:OneDrive) { $env:OneDrive } elseif ($env:OneDriveConsumer) { $env:OneDriveConsumer } elseif ($env:OneDriveCommercial) { $env:OneDriveCommercial } else { $null }

    if ($oneDrivePath -and $userProfile -like "*OneDrive*") {
        $preflight.isOneDriveSynced = $true
    }

    $vscodeExtDir = "$userProfile\.vscode\extensions"
    if ($oneDrivePath -and (Test-Path $vscodeExtDir)) {
        $resolvedPath = (Resolve-Path $vscodeExtDir).Path
        if ($resolvedPath -like "*OneDrive*") {
            $preflight.isOneDriveSynced = $true
        }
    }

    if ($preflight.isOneDriveSynced) {
        $preflight.warnings += "VS Code extensions folder is inside OneDrive sync path. May cause EPERM errors. Exclude .vscode folder from OneDrive sync."
    }
} catch {
    # Non-fatal
}

# ============================================
# Check 10: Existing Installation Conflicts
# ============================================
Write-Host "  Checking existing installations..." -ForegroundColor Gray

# nvm detection
$preflight.hasNvm = (Test-Path "$env:APPDATA\nvm\nvm.exe") -or (Test-CommandExists "nvm")
if ($preflight.hasNvm) {
    $preflight.warnings += "nvm detected. Node.js winget install will be skipped (managed by nvm)."
}

# Docker Toolbox detection
$preflight.hasDockerToolbox = Test-Path "$env:ProgramFiles\Docker Toolbox\docker.exe"
if ($preflight.hasDockerToolbox) {
    $preflight.warnings += "Docker Toolbox detected. May conflict with Docker Desktop. Recommend uninstalling Docker Toolbox first."
}

# npm global Claude CLI detection
# Use exit code: npm list -g returns 0 if found, 1 if not found
$preflight.hasNpmClaude = $false
if (Test-CommandExists "npm") {
    try {
        npm list -g @anthropic-ai/claude-code 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $preflight.hasNpmClaude = $true
            $preflight.warnings += "npm global Claude CLI detected. Will remove to avoid conflict with native install."
        }
    } catch {
        # Non-fatal
    }
}

# VS Code / Insiders detection
$preflight.hasCode = Test-CommandExists "code"
$preflight.hasCodeInsiders = Test-CommandExists "code-insiders"

if ($preflight.hasCodeInsiders -and -not $preflight.hasCode) {
    $preflight.warnings += "VS Code Insiders detected (no regular VS Code). Extensions will be installed via code-insiders."
}

# ============================================
# Check 11: Antivirus Software Detection
# ============================================
Write-Host "  Checking antivirus software..." -ForegroundColor Gray
try {
    $avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if ($avProducts) {
        $avNames = $avProducts | Select-Object -ExpandProperty displayName
        $preflight.avProducts = @($avNames)

        $problematicAVs = @("Norton", "Kaspersky", "McAfee", "Symantec", "Bitdefender", "Avast", "AVG")
        $detected = @()
        foreach ($avName in $avNames) {
            foreach ($pav in $problematicAVs) {
                if ($avName -like "*$pav*") { $detected += $avName; break }
            }
        }
        if ($detected.Count -gt 0) {
            $preflight.warnings += @(
                "Antivirus detected: $($detected -join ', ').",
                "  If files are quarantined during install:",
                "  - Temporarily disable real-time protection, OR",
                "  - Add exception paths: %LOCALAPPDATA%\Programs\, %USERPROFILE%\.vscode\extensions\, %USERPROFILE%\.local\bin\"
            ) -join "`n"
        }
    }
} catch {
    # SecurityCenter2 not available (e.g., Server OS) - skip
}

# ============================================
# Check 12: Group Policy / AppLocker
# ============================================
Write-Host "  Checking group policies..." -ForegroundColor Gray
try {
    $gpRestriction = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" -ErrorAction SilentlyContinue
    if ($gpRestriction -and $gpRestriction.DisableMSI) {
        $preflight.hasGPRestriction = $true
        $preflight.warnings += "Group Policy restricts software installation. IT admin approval may be needed."
    }

    # AppLocker check
    try {
        $appLockerPolicy = Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue
        if ($null -ne $appLockerPolicy -and $appLockerPolicy.RuleCollections.Count -gt 0) {
            $preflight.hasAppLocker = $true
            $preflight.warnings += "AppLocker policy detected. Some programs may be blocked from running."
        }
    } catch {
        # Get-AppLockerPolicy not available - skip
    }

    # VS Code extension policy
    $vscodePolicies = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Visual Studio Code" -ErrorAction SilentlyContinue
    if ($vscodePolicies -and $vscodePolicies.AllowedExtensions) {
        $preflight.warnings += "VS Code extension policy detected. IT admin may need to allow Claude/Pencil extensions."
    }
} catch {
    # Non-fatal
}

# ============================================
# Check 13: Docker License Warning
# ============================================
if ($script:needsDocker) {
    Write-Host "  Checking enterprise environment..." -ForegroundColor Gray
    try {
        $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $preflight.isDomainJoined = $computerSystem.PartOfDomain
        if ($preflight.isDomainJoined) {
            $preflight.warnings += "Enterprise environment detected (domain: $($computerSystem.Domain)). Docker Desktop requires paid subscription for companies with 250+ employees. Check: https://www.docker.com/pricing/"
        }
    } catch {
        # Non-fatal
    }
}

# ============================================
# Check 14: Google Account / Region (Gemini)
# ============================================
if ($env:CLI_TYPE -eq "gemini") {
    Write-Host "  Checking Gemini requirements..." -ForegroundColor Gray
    try {
        $region = (Get-WinSystemLocale -ErrorAction SilentlyContinue).Name
        $restrictedRegions = @("zh-CN", "ru-RU", "fa-IR")
        $isRestricted = $false
        foreach ($r in $restrictedRegions) {
            if ($region -like "$r*") { $isRestricted = $true; break }
        }

        $msg = @(
            "Gemini requirements:",
            "  - Personal @gmail.com account recommended (Workspace accounts may be blocked)",
            "  - 18+ Google account required",
            "  - Some countries have access restrictions"
        ) -join "`n"
        if ($isRestricted) {
            $msg += "`n  - WARNING: Your system locale ($region) may indicate a restricted region."
        }
        $preflight.warnings += $msg
    } catch {
        # Non-fatal
    }
}

# ============================================
# Summary Output
# ============================================
Write-Host ""

# Fatal errors - abort
if ($preflight.fatal) {
    Write-Host "  FATAL: $($preflight.fatal)" -ForegroundColor Red
    Write-Host ""
    throw $preflight.fatal
}

# Warnings summary
if ($preflight.warnings.Count -gt 0) {
    Write-Host "  $($preflight.warnings.Count) warning(s) detected:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $preflight.warnings.Count; $i++) {
        $lines = $preflight.warnings[$i] -split "`n"
        Write-Host "  $($i + 1). $($lines[0])" -ForegroundColor Yellow
        for ($j = 1; $j -lt $lines.Count; $j++) {
            Write-Host "     $($lines[$j])" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Only prompt in interactive mode (skip in CI, NONINTERACTIVE, or non-interactive sessions)
    if ([Environment]::UserInteractive -and -not $env:NONINTERACTIVE -and -not $env:CI) {
        Write-Host "  Continue with warnings? (Y/N) " -ForegroundColor White -NoNewline
        $continue = Read-Host
        if ($continue -ne "Y" -and $continue -ne "y") {
            throw "Cancelled by user due to preflight warnings."
        }
    }
} else {
    Write-Host "  All checks passed" -ForegroundColor Green
}

Write-Host "============================================" -ForegroundColor DarkGray
Write-Host ""
