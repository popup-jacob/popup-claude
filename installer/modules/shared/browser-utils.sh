#!/bin/bash
# ============================================
# Shared Browser Utilities
# FR-S3-05a: Eliminate 4-module browser open duplication
# Includes WSL detection for proper URL opening
# ============================================

# Source colors if not already loaded
if [ -z "$NC" ]; then
    SCRIPT_DIR_BROWSER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SHARED_DIR:-$SCRIPT_DIR_BROWSER}/colors.sh"
fi

# Cross-platform browser open
browser_open() {
    local url="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url" 2>/dev/null
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        start "$url" 2>/dev/null
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        # WSL: use Windows browser
        cmd.exe /c start "$url" 2>/dev/null || \
        powershell.exe -Command "Start-Process '$url'" 2>/dev/null
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$url" 2>/dev/null
    else
        echo -e "  ${YELLOW}Could not auto-open browser. Please open manually:${NC}"
        echo "  $url"
        return 1
    fi
}

# Open with confirmation prompt
browser_open_with_prompt() {
    local description="$1"
    local url="$2"

    read -p "Open $description in browser? (y/n): " response < /dev/tty
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        browser_open "$url"
    fi
}

# Try to open, fall back to displaying URL
browser_open_or_show() {
    local url="$1"
    local description="${2:-URL}"

    if ! browser_open "$url" 2>/dev/null; then
        echo -e "  ${YELLOW}Please open this $description in your browser:${NC}"
        echo -e "  ${CYAN}$url${NC}"
    fi
}

# Wait for user to complete a browser-based action
browser_wait_for_completion() {
    local action_desc="${1:-action}"
    echo -e "  ${YELLOW}Complete the $action_desc in your browser.${NC}"
    read -p "  Press Enter when done: " < /dev/tty
}
