# ============================================
# MCP OAuth Helper (Windows PowerShell)
# ============================================
# Automates OAuth PKCE flow for remote MCP servers
# Usage: . .\oauth-helper.ps1; Invoke-McpOAuth -ServerName "notion" -ServerUrl "https://mcp.notion.com/mcp"

Add-Type -AssemblyName System.Web

function Invoke-McpOAuth {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$true)]
        [string]$ServerUrl
    )

    $CallbackPort = 3118
    $RedirectUri = "http://localhost:$CallbackPort/callback"
    $CredFile = Join-Path $env:USERPROFILE ".claude\.credentials.json"

    # Parse base URL for OAuth metadata
    $uri = [System.Uri]$ServerUrl
    $BaseUrl = "$($uri.Scheme)://$($uri.Host)"
    $MetadataUrl = "$BaseUrl/.well-known/oauth-authorization-server"

    # ── Step 1: Check if already authenticated ──
    if (Test-Path $CredFile) {
        $creds = Get-Content $CredFile -Raw | ConvertFrom-Json
        if ($creds.mcpOAuth) {
            $existing = $creds.mcpOAuth.PSObject.Properties | Where-Object {
                $_.Value.serverName -eq $ServerName -and $_.Value.accessToken -and $_.Value.accessToken -ne ""
            } | Select-Object -First 1
            if ($existing) {
                $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                if ($existing.Value.expiresAt -gt $now) {
                    Write-Host "  Already authenticated with $ServerName!" -ForegroundColor Green
                    return $true
                }
            }
        }
    }

    # ── Step 2: Fetch OAuth metadata ──
    Write-Host "  Fetching OAuth configuration..." -ForegroundColor Gray
    try {
        $metadata = Invoke-RestMethod -Uri $MetadataUrl -Method Get
    } catch {
        Write-Host "  Failed to fetch OAuth metadata from $MetadataUrl" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        return $false
    }

    # ── Step 3: Get clientId from Claude Code's credentials ──
    $clientId = $null
    $clientSecret = $null
    $mcpKey = $null

    # Trigger CLI to register the client (creates credentials entry)
    $cliCmd = if ($env:CLI_TYPE -eq "gemini") { "gemini" } else { "claude" }
    Write-Host "  Initializing MCP connection..." -ForegroundColor Gray
    & $cliCmd mcp list 2>&1 | Out-Null

    if (Test-Path $CredFile) {
        $creds = Get-Content $CredFile -Raw | ConvertFrom-Json
        if ($creds.mcpOAuth) {
            # Find the entry Claude Code created (has clientId but empty accessToken)
            $existingEntry = $creds.mcpOAuth.PSObject.Properties | Where-Object {
                $_.Value.serverName -eq $ServerName -and $_.Value.clientId
            } | Select-Object -First 1
            if ($existingEntry) {
                $mcpKey = $existingEntry.Name
                $clientId = $existingEntry.Value.clientId
                $clientSecret = $existingEntry.Value.clientSecret
            }
        }
    }

    if (-not $clientId) {
        Write-Host "  Could not find OAuth client for $ServerName." -ForegroundColor Red
        Write-Host "  Make sure '$cliCmd mcp add' was run first." -ForegroundColor Yellow
        return $false
    }

    # ── Step 4: Generate PKCE code_verifier and code_challenge ──
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $codeVerifier = [Convert]::ToBase64String($bytes).Replace('+', '-').Replace('/', '_').TrimEnd('=')

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($codeVerifier))
    $codeChallenge = [Convert]::ToBase64String($hash).Replace('+', '-').Replace('/', '_').TrimEnd('=')

    $state = [guid]::NewGuid().ToString("N")

    # ── Step 5: Build authorization URL ──
    $authParams = @(
        "response_type=code",
        "client_id=$clientId",
        "code_challenge=$codeChallenge",
        "code_challenge_method=S256",
        "redirect_uri=$([System.Web.HttpUtility]::UrlEncode($RedirectUri))",
        "state=$state",
        "resource=$([System.Web.HttpUtility]::UrlEncode($ServerUrl))"
    )

    # Add scope if the server supports it
    if ($metadata.scopes_supported) {
        $scope = ($metadata.scopes_supported -join " ")
        $authParams += "scope=$([System.Web.HttpUtility]::UrlEncode($scope))"
    }

    $authUrl = "$($metadata.authorization_endpoint)?$($authParams -join '&')"

    # ── Step 6: Start local callback listener ──
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$CallbackPort/")
    try {
        $listener.Start()
    } catch {
        Write-Host "  Port $CallbackPort is in use. Close any running Claude Code session first." -ForegroundColor Red
        return $false
    }

    # ── Step 7: Open browser ──
    Write-Host ""
    Write-Host "  Opening browser for $ServerName login..." -ForegroundColor Cyan
    Write-Host "  Waiting for you to log in and allow access..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  If the browser doesn't open, copy and paste this URL:" -ForegroundColor DarkGray
    Write-Host "  $authUrl" -ForegroundColor Gray
    Write-Host ""
    Start-Process $authUrl

    # ── Step 8: Wait for OAuth callback ──
    try {
        $context = $listener.GetContext()
    } catch {
        Write-Host "  Listener error: $_" -ForegroundColor Red
        $listener.Stop()
        return $false
    }

    $query = [System.Web.HttpUtility]::ParseQueryString($context.Request.Url.Query)
    $code = $query["code"]
    $returnedState = $query["state"]
    $error_param = $query["error"]

    # Send response to browser
    if ($code) {
        $html = "<html><head><style>body{font-family:-apple-system,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#f0fdf4}div{text-align:center}h1{color:#16a34a}p{color:#666}</style></head><body><div><h1>Authentication Successful</h1><p>You can close this window and return to the terminal.</p></div></body></html>"
    } else {
        $html = "<html><head><style>body{font-family:-apple-system,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#fef2f2}div{text-align:center}h1{color:#dc2626}p{color:#666}</style></head><body><div><h1>Authentication Failed</h1><p>Error: $error_param. Please try again.</p></div></body></html>"
    }
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.ContentType = "text/html; charset=utf-8"
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.Close()
    $listener.Stop()

    # Validate
    if ($returnedState -ne $state) {
        Write-Host "  State mismatch - possible security issue. Aborting." -ForegroundColor Red
        return $false
    }
    if (-not $code) {
        Write-Host "  Authentication was denied or failed: $error_param" -ForegroundColor Red
        return $false
    }

    # ── Step 9: Exchange authorization code for tokens ──
    Write-Host "  Exchanging authorization code for tokens..." -ForegroundColor Gray

    $tokenParams = @(
        "grant_type=authorization_code",
        "code=$code",
        "redirect_uri=$([System.Web.HttpUtility]::UrlEncode($RedirectUri))",
        "client_id=$clientId",
        "code_verifier=$codeVerifier"
    )
    if ($clientSecret) {
        $tokenParams += "client_secret=$clientSecret"
    }
    $tokenBody = $tokenParams -join "&"

    try {
        $tokenResult = Invoke-RestMethod -Uri $metadata.token_endpoint -Method Post -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    } catch {
        Write-Host "  Token exchange failed: $_" -ForegroundColor Red
        return $false
    }

    # ── Step 10: Save tokens to .credentials.json ──
    $expiresAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + ($tokenResult.expires_in * 1000)

    $tokenEntry = [ordered]@{
        serverName   = $ServerName
        serverUrl    = $ServerUrl
        clientId     = $clientId
        accessToken  = $tokenResult.access_token
        expiresAt    = $expiresAt
        refreshToken = $tokenResult.refresh_token
        scope        = if ($tokenResult.scope) { $tokenResult.scope } else { "" }
    }
    if ($clientSecret) {
        $tokenEntry["clientSecret"] = $clientSecret
    }

    # Determine the key
    if (-not $mcpKey) {
        $urlBytes = [System.Text.Encoding]::UTF8.GetBytes($ServerUrl)
        $md5 = [System.Security.Cryptography.MD5]::Create().ComputeHash($urlBytes)
        $hashStr = -join ($md5[0..7] | ForEach-Object { $_.ToString("x2") })
        $mcpKey = "$ServerName|$hashStr"
    }

    # Escape values for Python
    $accessTokenEsc = $tokenResult.access_token -replace "'", "\'"
    $refreshTokenEsc = $tokenResult.refresh_token -replace "'", "\'"
    $scopeEsc = if ($tokenResult.scope) { $tokenResult.scope -replace "'", "\'" } else { "" }
    $clientSecretEsc = if ($clientSecret) { $clientSecret -replace "'", "\'" } else { "" }

    # Use Python to update only mcpOAuth without touching claudeAiOauth
    $pythonScript = @"
import json, sys, os
cred_file = r'$CredFile'
mcp_key = '$mcpKey'

token_entry = {
    'serverName': '$ServerName',
    'serverUrl': '$ServerUrl',
    'clientId': '$clientId',
    'accessToken': '$accessTokenEsc',
    'expiresAt': $expiresAt,
    'refreshToken': '$refreshTokenEsc',
    'scope': '$scopeEsc'
}

if '$clientSecretEsc':
    token_entry['clientSecret'] = '$clientSecretEsc'

if os.path.exists(cred_file):
    with open(cred_file, 'r', encoding='utf-8') as f:
        creds = json.load(f)
else:
    creds = {}

if 'mcpOAuth' not in creds:
    creds['mcpOAuth'] = {}

creds['mcpOAuth'][mcp_key] = token_entry

with open(cred_file, 'w', encoding='utf-8') as f:
    json.dump(creds, f, ensure_ascii=False)

print('OK')
"@

    try {
        $result = python -c $pythonScript 2>&1
        if ($result -ne "OK") {
            Write-Host "  Failed to save credentials" -ForegroundColor Red
            Write-Host "  Error: $result" -ForegroundColor Gray
            return $false
        }
    } catch {
        Write-Host "  Python is required but not found. Install Python 3 first." -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Gray
        return $false
    }

    Write-Host "  $ServerName authentication complete!" -ForegroundColor Green
    return $true
}
