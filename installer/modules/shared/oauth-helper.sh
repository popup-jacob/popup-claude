#!/bin/bash
# ============================================
# MCP OAuth Helper (Mac/Linux)
# ============================================
# Automates OAuth PKCE flow for remote MCP servers
# Usage: source oauth-helper.sh && mcp_oauth_flow "notion" "https://mcp.notion.com/mcp"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

CALLBACK_PORT=3118
REDIRECT_URI="http://localhost:${CALLBACK_PORT}/callback"
CRED_FILE="$HOME/.claude/.credentials.json"

# Generate random base64url string
_random_base64url() {
    openssl rand -base64 32 | tr '+/' '-_' | tr -d '='
}

# SHA256 hash -> base64url
_sha256_base64url() {
    printf '%s' "$1" | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '='
}

# URL encode
_urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('$1', safe=''))"
}

# Open browser (cross-platform)
_open_browser() {
    if command -v open > /dev/null 2>&1; then
        open "$1"
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$1"
    else
        echo -e "  ${YELLOW}Please open this URL manually:${NC}"
        echo "  $1"
    fi
}

# Read JSON field using python3
_json_get() {
    local file="$1"
    local path="$2"
    python3 -c "
import json, sys
try:
    with open('$file') as f:
        data = json.load(f)
    keys = '$path'.split('.')
    val = data
    for k in keys:
        if isinstance(val, dict):
            val = val.get(k, '')
        else:
            val = ''
            break
    print(val if val else '')
except:
    print('')
"
}

# Find MCP OAuth entry by server name
_find_mcp_entry() {
    local server_name="$1"
    python3 -c "
import json, sys
try:
    with open('$CRED_FILE') as f:
        data = json.load(f)
    mcp = data.get('mcpOAuth', {})
    for key, val in mcp.items():
        if val.get('serverName') == '$server_name':
            print(f\"{key}|{val.get('clientId', '')}|{val.get('clientSecret', '')}|{val.get('accessToken', '')}|{val.get('expiresAt', 0)}\")
            sys.exit(0)
    print('')
except:
    print('')
"
}

# Start callback listener and wait for OAuth redirect
_wait_for_callback() {
    python3 -c "
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        query = parse_qs(urlparse(self.path).query)
        code = query.get('code', [''])[0]
        state = query.get('state', [''])[0]
        error = query.get('error', [''])[0]

        if code:
            html = '<html><head><style>body{font-family:-apple-system,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#f0fdf4}div{text-align:center}h1{color:#16a34a}p{color:#666}</style></head><body><div><h1>Authentication Successful</h1><p>You can close this window and return to the terminal.</p></div></body></html>'
        else:
            html = f'<html><head><style>body{{font-family:-apple-system,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#fef2f2}}div{{text-align:center}}h1{{color:#dc2626}}p{{color:#666}}</style></head><body><div><h1>Authentication Failed</h1><p>Error: {error}. Please try again.</p></div></body></html>'

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(html.encode())

        # Output code and state for the parent script
        print(f'{code}||{state}||{error}', file=sys.stderr)

    def log_message(self, *args):
        pass

server = HTTPServer(('localhost', $CALLBACK_PORT), Handler)
server.handle_request()
" 2>&1 1>/dev/null
}

# Exchange auth code for tokens
_exchange_token() {
    local token_endpoint="$1"
    local code="$2"
    local client_id="$3"
    local code_verifier="$4"
    local client_secret="$5"

    local body="grant_type=authorization_code&code=${code}&redirect_uri=$(_urlencode "$REDIRECT_URI")&client_id=${client_id}&code_verifier=${code_verifier}"
    if [ -n "$client_secret" ]; then
        body="${body}&client_secret=${client_secret}"
    fi

    curl -s -X POST "$token_endpoint" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$body"
}

# Save tokens to credentials file
_save_tokens() {
    local server_name="$1"
    local server_url="$2"
    local client_id="$3"
    local client_secret="$4"
    local mcp_key="$5"
    local token_json="$6"

    python3 -c "
import json, hashlib, time, os

server_name = '$server_name'
server_url = '$server_url'
client_id = '$client_id'
client_secret = '$client_secret'
mcp_key = '$mcp_key'
token_json = '''$token_json'''
cred_file = '$CRED_FILE'

token_data = json.loads(token_json)

# Calculate expiration
expires_in = token_data.get('expires_in', 3600)
expires_at = int(time.time() * 1000) + (expires_in * 1000)

# Build entry
entry = {
    'serverName': server_name,
    'serverUrl': server_url,
    'clientId': client_id,
    'accessToken': token_data.get('access_token', ''),
    'expiresAt': expires_at,
    'refreshToken': token_data.get('refresh_token', ''),
    'scope': token_data.get('scope', '')
}
if client_secret:
    entry['clientSecret'] = client_secret

# Read existing credentials
if os.path.exists(cred_file):
    with open(cred_file) as f:
        creds = json.load(f)
else:
    creds = {}

if 'mcpOAuth' not in creds:
    creds['mcpOAuth'] = {}

# Use existing key or generate new one
if mcp_key:
    creds['mcpOAuth'][mcp_key] = entry
else:
    url_hash = hashlib.md5(server_url.encode()).hexdigest()[:16]
    new_key = f'{server_name}|{url_hash}'
    creds['mcpOAuth'][new_key] = entry

with open(cred_file, 'w') as f:
    json.dump(creds, f, indent=None)

print('OK')
"
}

# ── Main OAuth flow ──
mcp_oauth_flow() {
    local server_name="$1"
    local server_url="$2"

    # Parse base URL
    local base_url
    base_url=$(python3 -c "from urllib.parse import urlparse; u=urlparse('$server_url'); print(f'{u.scheme}://{u.netloc}')")
    local metadata_url="${base_url}/.well-known/oauth-authorization-server"

    # ── Step 1: Check if already authenticated ──
    if [ -f "$CRED_FILE" ]; then
        local entry_info
        entry_info=$(_find_mcp_entry "$server_name")
        if [ -n "$entry_info" ]; then
            local existing_token existing_expires
            existing_token=$(echo "$entry_info" | cut -d'|' -f4)
            existing_expires=$(echo "$entry_info" | cut -d'|' -f5)
            local now
            now=$(python3 -c "import time; print(int(time.time()*1000))")
            if [ -n "$existing_token" ] && [ "$existing_expires" -gt "$now" ] 2>/dev/null; then
                echo -e "  ${GREEN}Already authenticated with $server_name!${NC}"
                return 0
            fi
        fi
    fi

    # ── Step 2: Fetch OAuth metadata ──
    echo -e "  ${GRAY}Fetching OAuth configuration...${NC}"
    local metadata
    metadata=$(curl -s "$metadata_url")
    if [ -z "$metadata" ]; then
        echo -e "  ${RED}Failed to fetch OAuth metadata from $metadata_url${NC}"
        return 1
    fi

    local auth_endpoint token_endpoint reg_endpoint scopes_supported
    auth_endpoint=$(echo "$metadata" | python3 -c "import json,sys; print(json.load(sys.stdin).get('authorization_endpoint',''))")
    token_endpoint=$(echo "$metadata" | python3 -c "import json,sys; print(json.load(sys.stdin).get('token_endpoint',''))")
    reg_endpoint=$(echo "$metadata" | python3 -c "import json,sys; print(json.load(sys.stdin).get('registration_endpoint',''))")
    scopes_supported=$(echo "$metadata" | python3 -c "import json,sys; s=json.load(sys.stdin).get('scopes_supported',[]); print(' '.join(s))")

    # ── Step 3: Get clientId from Claude Code's credentials ──
    local client_id="" client_secret="" mcp_key=""

    # Trigger CLI to register the client (creates credentials entry)
    local cli_cmd="${CLI_TYPE:-claude}"
    echo -e "  ${GRAY}Initializing MCP connection...${NC}"
    $cli_cmd mcp list > /dev/null 2>&1

    if [ -f "$CRED_FILE" ]; then
        local entry_info
        entry_info=$(_find_mcp_entry "$server_name")
        if [ -n "$entry_info" ]; then
            mcp_key=$(echo "$entry_info" | cut -d'|' -f1)
            client_id=$(echo "$entry_info" | cut -d'|' -f2)
            client_secret=$(echo "$entry_info" | cut -d'|' -f3)
        fi
    fi

    if [ -z "$client_id" ]; then
        echo -e "  ${RED}Could not find OAuth client for $server_name.${NC}"
        echo -e "  ${YELLOW}Make sure '$cli_cmd mcp add' was run first.${NC}"
        return 1
    fi

    # ── Step 4: Generate PKCE ──
    local code_verifier code_challenge state
    code_verifier=$(_random_base64url)
    code_challenge=$(_sha256_base64url "$code_verifier")
    state=$(openssl rand -hex 16)

    # ── Step 5: Build authorization URL ──
    local auth_url="${auth_endpoint}?response_type=code&client_id=${client_id}&code_challenge=${code_challenge}&code_challenge_method=S256&redirect_uri=$(_urlencode "$REDIRECT_URI")&state=${state}&resource=$(_urlencode "$server_url")"

    if [ -n "$scopes_supported" ]; then
        auth_url="${auth_url}&scope=$(_urlencode "$scopes_supported")"
    fi

    # ── Step 6: Open browser ──
    echo ""
    echo -e "  ${CYAN}Opening browser for $server_name login...${NC}"
    echo -e "  ${YELLOW}Waiting for you to log in and allow access...${NC}"
    echo ""
    echo -e "  ${GRAY}If the browser doesn't open, copy and paste this URL:${NC}"
    echo "  $auth_url"
    echo ""
    _open_browser "$auth_url"

    # ── Step 7: Wait for callback ──
    local callback_result
    callback_result=$(_wait_for_callback)

    # Parse callback result (format: code||state||error)
    local code returned_state error_param
    IFS='|' read -r code _ returned_state _ error_param <<< "$callback_result"

    if [ -z "$code" ]; then
        echo -e "  ${RED}Authentication failed: $error_param${NC}"
        return 1
    fi

    if [ "$returned_state" != "$state" ]; then
        echo -e "  ${RED}State mismatch - possible security issue. Aborting.${NC}"
        return 1
    fi

    # ── Step 8: Exchange code for tokens ──
    echo -e "  ${GRAY}Exchanging authorization code for tokens...${NC}"
    local token_result
    token_result=$(_exchange_token "$token_endpoint" "$code" "$client_id" "$code_verifier" "$client_secret")

    local access_token
    access_token=$(echo "$token_result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))")
    if [ -z "$access_token" ]; then
        echo -e "  ${RED}Token exchange failed${NC}"
        return 1
    fi

    # ── Step 9: Save tokens ──
    echo -e "  ${GRAY}Saving credentials...${NC}"
    local save_result
    save_result=$(_save_tokens "$server_name" "$server_url" "$client_id" "$client_secret" "$mcp_key" "$token_result")

    if [ "$save_result" = "OK" ]; then
        echo -e "  ${GREEN}$server_name authentication complete!${NC}"
        return 0
    else
        echo -e "  ${RED}Failed to save credentials${NC}"
        return 1
    fi
}
