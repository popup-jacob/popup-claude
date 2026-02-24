#!/bin/bash
# ============================================
# Preflight Environment Checks (Mac/Linux)
# ============================================
# Purpose: Diagnose environment before installation, warn or abort on issues
# Called by: install.sh via `source`
# Exports:   PREFLIGHT_* variables consumed by install.sh

# ── Result variables ───────────────────────────────────────────────────────────
PREFLIGHT_ARCH="$(uname -m)"          # arm64 or x86_64
PREFLIGHT_BREW_PATH=""                 # /opt/homebrew or /usr/local
PREFLIGHT_IS_ROSETTA=false
PREFLIGHT_MACOS_VERSION=""
PREFLIGHT_MACOS_MAJOR=0
PREFLIGHT_HAS_XCODE_CLT=false
PREFLIGHT_XCODE_NEEDS_REINSTALL=false
PREFLIGHT_IS_ONLINE=true
PREFLIGHT_HAS_PROXY=false
PREFLIGHT_IS_MITM=false
PREFLIGHT_FREE_SPACE_GB=0
PREFLIGHT_HAS_NODE_MANAGER=false      # nvm / fnm / volta detected
PREFLIGHT_HAS_NPM_CLAUDE=false        # deprecated npm global Claude CLI
PREFLIGHT_HAS_CODE=false              # 'code' command available
PREFLIGHT_FATAL=""
PREFLIGHT_WARNING_COUNT=0

# ── Color helpers (reuse from colors.sh if already loaded) ────────────────────
_PF_RED="${RED:-\033[0;31m}"
_PF_YEL="${YELLOW:-\033[1;33m}"
_PF_GRN="${GREEN:-\033[0;32m}"
_PF_GRY="${GRAY:-\033[0;90m}"
_PF_NC="${NC:-\033[0m}"

IS_MAC=false
[[ "$OSTYPE" == "darwin"* ]] && IS_MAC=true

# Helper: print a warning (increments counter, prints inline)
_pf_warn() {
    PREFLIGHT_WARNING_COUNT=$((PREFLIGHT_WARNING_COUNT + 1))
    local title="$1"; shift
    echo -e "  ${_PF_YEL}${PREFLIGHT_WARNING_COUNT}. ${title}${_PF_NC}"
    for _line in "$@"; do
        echo -e "  ${_PF_YEL}   ${_line}${_PF_NC}"
    done
}

# Helper: print fatal and return error
_pf_fatal() {
    PREFLIGHT_FATAL="$1"
    echo -e ""
    echo -e "  ${_PF_RED}FATAL: ${PREFLIGHT_FATAL}${_PF_NC}"
    echo -e ""
    return 1 2>/dev/null || exit 1
}

echo ""
echo -e "${_PF_GRY}============================================${_PF_NC}"
echo -e "  Environment Pre-check"
echo -e "${_PF_GRY}============================================${_PF_NC}"

# ============================================
# Check 1: macOS Version
# ============================================
echo -e "  ${_PF_GRY}Checking OS version...${_PF_NC}"
if $IS_MAC; then
    PREFLIGHT_MACOS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"
    PREFLIGHT_MACOS_MAJOR="$(echo "$PREFLIGHT_MACOS_VERSION" | cut -d. -f1)"

    if [[ "$PREFLIGHT_MACOS_MAJOR" =~ ^[0-9]+$ ]]; then
        if [[ "$PREFLIGHT_MACOS_MAJOR" -lt 12 ]]; then
            _pf_fatal "macOS $PREFLIGHT_MACOS_VERSION is not supported. macOS Monterey 12 or later required." || return 1
        elif [[ "$PREFLIGHT_MACOS_MAJOR" -lt 14 ]]; then
            _pf_warn \
                "macOS $PREFLIGHT_MACOS_VERSION detected (Sonoma 14+ recommended)." \
                "Homebrew may need to build some packages from source (slower install)." \
                "Upgrade recommended: System Settings > General > Software Update"
        fi
    fi
fi

# ============================================
# Check 2: Architecture + Rosetta Detection
# ============================================
echo -e "  ${_PF_GRY}Checking CPU architecture...${_PF_NC}"
if $IS_MAC; then
    _hw_is_arm="$(sysctl -n hw.optional.arm64 2>/dev/null || echo "0")"
    if [[ "$_hw_is_arm" == "1" ]]; then
        # Apple Silicon hardware
        PREFLIGHT_BREW_PATH="/opt/homebrew"
        if [[ "$PREFLIGHT_ARCH" == "x86_64" ]]; then
            # Running under Rosetta 2
            PREFLIGHT_IS_ROSETTA=true
            _pf_warn \
                "Running in Rosetta 2 mode. Intel (x86_64) tools will be installed instead of native ARM64." \
                "Fix: Open Terminal.app > Get Info > uncheck 'Open using Rosetta'" \
                "Then close and reopen terminal before running this installer again."
        fi
    else
        # Intel Mac
        PREFLIGHT_BREW_PATH="/usr/local"
    fi
else
    PREFLIGHT_BREW_PATH="/usr/local"
fi

# ============================================
# Check 3: Xcode Command Line Tools (Mac only)
# ============================================
if $IS_MAC; then
    echo -e "  ${_PF_GRY}Checking Xcode Command Line Tools...${_PF_NC}"
    _clt_path="$(xcode-select -p 2>/dev/null || echo "")"
    if [[ -z "$_clt_path" ]]; then
        # Not installed — Homebrew will trigger the GUI dialog
        PREFLIGHT_HAS_XCODE_CLT=false
        _pf_warn \
            "Xcode Command Line Tools not installed." \
            "Homebrew will install them automatically." \
            "A GUI dialog may appear — click 'Install' to continue."
    elif ! xcrun cc --version &>/dev/null 2>&1; then
        # Installed but invalidated (common after macOS upgrade)
        PREFLIGHT_HAS_XCODE_CLT=false
        PREFLIGHT_XCODE_NEEDS_REINSTALL=true
        _pf_warn \
            "Xcode CLT found but invalid (common after macOS upgrade)." \
            "Auto-fix will be attempted during install." \
            "Or run manually: sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install"
    else
        PREFLIGHT_HAS_XCODE_CLT=true
    fi
fi

# ============================================
# Check 4: Internet Connectivity
# ============================================
echo -e "  ${_PF_GRY}Checking internet connection...${_PF_NC}"
_pf_failed_urls=()
_pf_any_success=false

for _url in "raw.githubusercontent.com" "nodejs.org" "claude.ai"; do
    if curl -sf --max-time 5 --connect-timeout 3 "https://$_url" -o /dev/null 2>/dev/null; then
        _pf_any_success=true
    else
        _pf_failed_urls[${#_pf_failed_urls[@]}]="$_url"
    fi
done

if ! $_pf_any_success; then
    PREFLIGHT_IS_ONLINE=false
    _pf_fatal "No internet connection. Cannot reach any required servers. Please connect to the internet." || return 1
elif [[ ${#_pf_failed_urls[@]} -gt 0 ]]; then
    _failed_list=""
    for _u in "${_pf_failed_urls[@]}"; do
        _failed_list="${_failed_list:+$_failed_list, }$_u"
    done
    _pf_warn \
        "Some servers unreachable: ${_failed_list}" \
        "Possible firewall or proxy issue. Some downloads may fail." \
        "Required domains: raw.githubusercontent.com, nodejs.org, claude.ai, registry.npmjs.org"
fi

# ============================================
# Check 5: Proxy Detection
# ============================================
echo -e "  ${_PF_GRY}Checking proxy settings...${_PF_NC}"
_proxy_val="${HTTPS_PROXY:-$HTTP_PROXY:-$https_proxy:-$http_proxy}"
if [[ -n "$_proxy_val" ]]; then
    PREFLIGHT_HAS_PROXY=true
    # Mask credentials in output
    _proxy_display="$(echo "$_proxy_val" | sed 's|://[^@]*@|://***@|g')"
    _pf_warn \
        "Proxy detected (${_proxy_display})." \
        "If downloads fail, verify proxy allows: github.com, nodejs.org, registry.npmjs.org, claude.ai"
fi

if $IS_MAC && ! $PREFLIGHT_HAS_PROXY; then
    # Check macOS system proxy (Wi-Fi)
    _sys_proxy="$(networksetup -getwebproxy "Wi-Fi" 2>/dev/null | awk '/^Server:/ && $2!="0.0.0.0" && $2!="" {print $2}')"
    _sys_port="$(networksetup -getwebproxy "Wi-Fi" 2>/dev/null | awk '/^Port:/ && $2!="0" && $2!="" {print $2}')"
    if [[ -n "$_sys_proxy" ]]; then
        PREFLIGHT_HAS_PROXY=true
        _pf_warn \
            "System proxy detected (${_sys_proxy}:${_sys_port})." \
            "If downloads fail, set: export HTTPS_PROXY=http://${_sys_proxy}:${_sys_port}"
    fi
fi

# ============================================
# Check 6: SSL MITM Detection (corporate inspection)
# ============================================
if [[ "$PREFLIGHT_IS_ONLINE" == true ]] && $IS_MAC; then
    echo -e "  ${_PF_GRY}Checking SSL certificates...${_PF_NC}"
    _cert_issuer="$(curl -sv --max-time 5 "https://claude.ai" 2>&1 | grep -i "issuer:" | head -1 || true)"
    if [[ -n "$_cert_issuer" ]]; then
        _known_cas="DigiCert|Let.s Encrypt|Cloudflare|Amazon|Google|GlobalSign|Sectigo|Comodo|Baltimore|ISRG|QuoVadis"
        if ! echo "$_cert_issuer" | grep -qiE "$_known_cas"; then
            PREFLIGHT_IS_MITM=true
            _issuer_name="$(echo "$_cert_issuer" | sed 's/.*issuer: //' | head -c 80)"
            _pf_warn \
                "Corporate SSL inspection detected (issuer: ${_issuer_name})." \
                "SSL certificate errors may occur during install." \
                "Fix: export NODE_EXTRA_CA_CERTS=/path/to/corporate-ca.pem" \
                "Ask your IT admin for the corporate CA certificate file."
        fi
    fi
fi

# ============================================
# Check 7: Disk Space
# ============================================
echo -e "  ${_PF_GRY}Checking disk space...${_PF_NC}"
# df -k gives 1KB blocks, universally supported
_free_kb="$(df -k / 2>/dev/null | awk 'NR==2{print $4}' || echo "0")"
if [[ "$_free_kb" =~ ^[0-9]+$ ]]; then
    PREFLIGHT_FREE_SPACE_GB=$((_free_kb / 1024 / 1024))
fi

_required_gb=3
[[ "${NEEDS_DOCKER:-false}" == true ]] && _required_gb=8

if [[ "$PREFLIGHT_FREE_SPACE_GB" -lt "$_required_gb" ]] 2>/dev/null; then
    _pf_warn \
        "Low disk space: ${PREFLIGHT_FREE_SPACE_GB}GB free (minimum ${_required_gb}GB recommended)." \
        "Free up space before installing:" \
        "  Mac: brew cleanup && open ~/Library/Caches" \
        "  If Docker installed: docker system prune -a"
fi

# ============================================
# Check 8: Node.js Version Manager Conflicts
# ============================================
echo -e "  ${_PF_GRY}Checking existing Node.js setup...${_PF_NC}"
if command -v nvm &>/dev/null 2>&1 || [[ -d "$HOME/.nvm" ]]; then
    PREFLIGHT_HAS_NODE_MANAGER=true
    _pf_warn \
        "nvm detected. brew install node will be skipped to avoid conflict." \
        "nvm's Node.js will be used instead."
elif command -v fnm &>/dev/null 2>&1; then
    PREFLIGHT_HAS_NODE_MANAGER=true
    _pf_warn \
        "fnm detected. brew install node will be skipped to avoid conflict." \
        "fnm's Node.js will be used instead."
elif command -v volta &>/dev/null 2>&1 || [[ -d "$HOME/.volta" ]]; then
    PREFLIGHT_HAS_NODE_MANAGER=true
    _pf_warn \
        "volta detected. brew install node will be skipped to avoid conflict." \
        "volta's Node.js will be used instead."
fi

# ============================================
# Check 9: npm global Claude CLI conflict
# ============================================
echo -e "  ${_PF_GRY}Checking existing CLI installations...${_PF_NC}"
if command -v npm &>/dev/null 2>&1; then
    _npm_claude="$(npm list -g @anthropic-ai/claude-code 2>/dev/null | grep "claude-code" || true)"
    if [[ -n "$_npm_claude" ]]; then
        PREFLIGHT_HAS_NPM_CLAUDE=true
        _pf_warn \
            "npm global Claude CLI detected (deprecated install method)." \
            "Will remove before native install to avoid PATH conflict." \
            "See: https://code.claude.com/docs/en/setup"
    fi
fi

# Tool availability (used by install.sh)
command -v code &>/dev/null 2>&1 && PREFLIGHT_HAS_CODE=true || PREFLIGHT_HAS_CODE=false

# ============================================
# Check 10: Homebrew health (if already installed)
# ============================================
if command -v brew &>/dev/null 2>&1; then
    echo -e "  ${_PF_GRY}Checking Homebrew health...${_PF_NC}"
    if ! brew --version &>/dev/null 2>&1; then
        _pf_warn \
            "Homebrew appears damaged." \
            "Fix: brew update-reset" \
            "Or reinstall: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
fi

# ============================================
# Check 11: Google Account / Region (Gemini only)
# ============================================
if [[ "${CLI_TYPE:-}" == "gemini" ]]; then
    echo -e "  ${_PF_GRY}Checking Gemini requirements...${_PF_NC}"
    _locale="$(locale 2>/dev/null | grep LANG | head -1 | cut -d= -f2 | tr -d '"' || echo "")"
    _region_warn=""
    if echo "$_locale" | grep -qE "^(zh_CN|ru_RU|fa_IR)"; then
        _region_warn=" WARNING: Your locale ($_locale) may indicate a restricted region."
    fi
    _pf_warn \
        "Gemini account requirements:" \
        "- Personal @gmail.com account recommended (Workspace may be blocked)" \
        "- 18+ Google account required" \
        "- Access restricted in some countries (China, Russia, Iran)${_region_warn:+$_region_warn}"
fi

# ============================================
# Summary
# ============================================
echo ""

if [[ "$PREFLIGHT_WARNING_COUNT" -gt 0 ]]; then
    echo -e "  ${_PF_YEL}${PREFLIGHT_WARNING_COUNT} warning(s) detected above.${_PF_NC}"
    echo ""

    # Prompt in interactive mode (skip if NONINTERACTIVE or piped)
    if [[ -t 0 ]] && [[ -z "${NONINTERACTIVE:-}" ]]; then
        printf "  Continue with warnings? (Y/n) "
        read -r _confirm < /dev/tty
        if [[ "$_confirm" == "n" ]] || [[ "$_confirm" == "N" ]]; then
            echo "Cancelled by user."
            return 1 2>/dev/null || exit 1
        fi
    fi
else
    echo -e "  ${_PF_GRN}All checks passed${_PF_NC}"
fi

echo -e "${_PF_GRY}============================================${_PF_NC}"
echo ""
