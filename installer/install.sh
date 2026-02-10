#!/bin/bash
# ============================================
# AI-Driven Work Installer (ADW) - Mac/Linux
# ============================================
# Dynamic Module Loading System (Folder Scan)
#
# Usage:
#   ./install.sh --modules "google,atlassian"
#   ./install.sh --all
#   ./install.sh --list
#
# Remote:
#   curl -sSL https://raw.githubusercontent.com/.../install.sh | bash -s -- --modules "google,atlassian"

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Base URL for module downloads
BASE_URL="https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer"

# JSON parser using osascript (macOS built-in)
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

# Check if running locally
USE_LOCAL=false
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -d "$SCRIPT_DIR/modules" ]; then
        USE_LOCAL=true
    fi
fi

# ============================================
# 1. Parse Arguments
# ============================================
# Support both environment variables and command-line arguments
MODULES="${MODULES:-}"
INSTALL_ALL="${INSTALL_ALL:-false}"
SKIP_BASE="${SKIP_BASE:-false}"
LIST_ONLY="${LIST_ONLY:-false}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --modules) MODULES="$2"; shift 2 ;;
        --all) INSTALL_ALL=true; shift ;;
        --skip-base) SKIP_BASE=true; shift ;;
        --list) LIST_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ============================================
# 2. Scan Modules Folder
# ============================================
# Store module info in arrays
declare -a MODULE_NAMES
declare -a MODULE_DISPLAY_NAMES
declare -a MODULE_DESCRIPTIONS
declare -a MODULE_ORDERS
declare -a MODULE_REQUIRED
declare -a MODULE_COMPLEXITY
declare -a MODULE_DOCKER_REQ

load_modules() {
    local idx=0

    if [ "$USE_LOCAL" = true ]; then
        # Local: scan modules/ folder
        for dir in "$SCRIPT_DIR/modules"/*/; do
            if [ -f "${dir}module.json" ]; then
                local json=$(cat "${dir}module.json")
                MODULE_NAMES[$idx]=$(parse_json "$json" "name")
                MODULE_DISPLAY_NAMES[$idx]=$(parse_json "$json" "displayName")
                MODULE_DESCRIPTIONS[$idx]=$(parse_json "$json" "description")
                MODULE_ORDERS[$idx]=$(parse_json "$json" "order")
                MODULE_REQUIRED[$idx]=$(parse_json "$json" "required")
                MODULE_COMPLEXITY[$idx]=$(parse_json "$json" "complexity")
                MODULE_DOCKER_REQ[$idx]=$(parse_json "$json" "requirements.docker")
                ((idx++))
            fi
        done
    else
        # Remote: fetch module list, then load each module
        local modules_json=$(curl -sSL "$BASE_URL/modules.json" 2>/dev/null || echo "")
        if [ -n "$modules_json" ]; then
            # Parse module names from modules.json
            local module_names=$(osascript -l JavaScript -e "JSON.parse(\`$modules_json\`).modules.map(m => m.name).join(' ')" 2>/dev/null)
            for name in $module_names; do
                local json=$(curl -sSL "$BASE_URL/modules/$name/module.json" 2>/dev/null || echo "")
                if [ -n "$json" ]; then
                    MODULE_NAMES[$idx]=$(parse_json "$json" "name")
                    MODULE_DISPLAY_NAMES[$idx]=$(parse_json "$json" "displayName")
                    MODULE_DESCRIPTIONS[$idx]=$(parse_json "$json" "description")
                    MODULE_ORDERS[$idx]=$(parse_json "$json" "order")
                    MODULE_REQUIRED[$idx]=$(parse_json "$json" "required")
                    MODULE_COMPLEXITY[$idx]=$(parse_json "$json" "complexity")
                    MODULE_DOCKER_REQ[$idx]=$(parse_json "$json" "requirements.docker")
                    ((idx++))
                fi
            done
        fi
    fi
}

get_module_index() {
    local name="$1"
    for i in "${!MODULE_NAMES[@]}"; do
        if [ "${MODULE_NAMES[$i]}" = "$name" ]; then
            echo "$i"
            return
        fi
    done
    echo "-1"
}

load_modules

# ============================================
# 3. List Mode
# ============================================
if [ "$LIST_ONLY" = true ]; then
    clear
    echo ""
    echo "========================================"
    echo -e "${CYAN}  Available Modules${NC}"
    echo "========================================"
    echo ""

    # Sort by order and display
    for i in "${!MODULE_NAMES[@]}"; do
        name="${MODULE_NAMES[$i]}"
        display="${MODULE_DISPLAY_NAMES[$i]}"
        desc="${MODULE_DESCRIPTIONS[$i]}"
        complexity="${MODULE_COMPLEXITY[$i]}"
        required="${MODULE_REQUIRED[$i]}"

        req_text=""
        if [ "$required" = "true" ]; then
            req_text="${YELLOW}(required)${NC}"
        fi

        echo -e "  ${GREEN}$name${NC} $req_text ${GRAY}[$complexity]${NC}"
        echo -e "    ${GRAY}$desc${NC}"
        echo ""
    done

    echo "Usage:"
    echo -e "  ${GRAY}./install.sh --modules \"google,atlassian\"${NC}"
    echo -e "  ${GRAY}./install.sh --all${NC}"
    echo ""
    exit 0
fi

# ============================================
# 4. Parse Module Selection
# ============================================
SELECTED_MODULES=""

if [ "$INSTALL_ALL" = true ]; then
    for i in "${!MODULE_NAMES[@]}"; do
        if [ "${MODULE_REQUIRED[$i]}" != "true" ]; then
            SELECTED_MODULES="$SELECTED_MODULES ${MODULE_NAMES[$i]}"
        fi
    done
    SELECTED_MODULES=$(echo "$SELECTED_MODULES" | xargs)  # trim
elif [ -n "$MODULES" ]; then
    SELECTED_MODULES=$(echo "$MODULES" | tr ',' ' ')
fi

# Validate modules
for mod in $SELECTED_MODULES; do
    idx=$(get_module_index "$mod")
    if [ "$idx" = "-1" ]; then
        echo -e "${RED}Unknown module: $mod${NC}"
        echo "Use --list to see available modules."
        exit 1
    fi
done

# ============================================
# 5. Smart Status Check
# ============================================
get_install_status() {
    if command -v node > /dev/null 2>&1; then HAS_NODE="true"; else HAS_NODE="false"; fi
    if command -v git > /dev/null 2>&1; then HAS_GIT="true"; else HAS_GIT="false"; fi
    if command -v code > /dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]; then HAS_VSCODE="true"; else HAS_VSCODE="false"; fi
    if command -v docker > /dev/null 2>&1; then HAS_DOCKER="true"; else HAS_DOCKER="false"; fi
    if command -v claude > /dev/null 2>&1; then HAS_CLAUDE="true"; else HAS_CLAUDE="false"; fi
    HAS_BKIT="false"
    DOCKER_RUNNING="false"

    if [ "$HAS_DOCKER" = "true" ]; then
        if docker info > /dev/null 2>&1; then DOCKER_RUNNING="true"; fi
    fi

    if [ "$HAS_CLAUDE" = "true" ]; then
        claude plugin list 2>/dev/null | grep -q "bkit" && HAS_BKIT="true" || true
    fi
}

clear
echo ""
echo "========================================"
echo -e "${CYAN}  AI-Driven Work Installer v2${NC}"
echo "========================================"
echo ""

get_install_status

# Check Docker requirement for selected modules (before status display)
NEEDS_DOCKER=false
for mod in $SELECTED_MODULES; do
    idx=$(get_module_index "$mod")
    if [ "${MODULE_DOCKER_REQ[$idx]}" = "true" ]; then
        NEEDS_DOCKER=true
        break
    fi
done

echo "Current Status:"
[ "$HAS_NODE" = "true" ] && echo -e "  Node.js:  ${GREEN}[OK]${NC}" || echo -e "  Node.js:  ${GRAY}[  ]${NC}"
[ "$HAS_GIT" = "true" ] && echo -e "  Git:      ${GREEN}[OK]${NC}" || echo -e "  Git:      ${GRAY}[  ]${NC}"
[ "$HAS_VSCODE" = "true" ] && echo -e "  VS Code:  ${GREEN}[OK]${NC}" || echo -e "  VS Code:  ${GRAY}[  ]${NC}"
if [ "$NEEDS_DOCKER" = true ]; then
    if [ "$HAS_DOCKER" = "true" ]; then
        if [ "$DOCKER_RUNNING" = "true" ]; then
            echo -e "  Docker:   ${GREEN}[OK] (Running)${NC}"
        else
            echo -e "  Docker:   ${YELLOW}[OK] (Not Running)${NC}"
        fi
    else
        echo -e "  Docker:   ${GRAY}[  ]${NC}"
    fi
fi
[ "$HAS_CLAUDE" = "true" ] && echo -e "  Claude:   ${GREEN}[OK]${NC}" || echo -e "  Claude:   ${GRAY}[  ]${NC}"
[ "$HAS_BKIT" = "true" ] && echo -e "  bkit:     ${GREEN}[OK]${NC}" || echo -e "  bkit:     ${GRAY}[  ]${NC}"
echo ""

if [ "$NEEDS_DOCKER" = true ] && [ "$HAS_DOCKER" = "true" ] && [ "$DOCKER_RUNNING" = "false" ]; then
    echo "========================================"
    echo -e "${YELLOW}  Docker Desktop is not running!${NC}"
    echo "========================================"
    echo ""
    echo "Selected modules require Docker to be running."
    echo ""
    echo -e "${GRAY}How to start:${NC}"
    echo -e "${GRAY}  - Click Docker icon in Applications (Mac)${NC}"
    echo -e "${GRAY}  - Or run 'sudo systemctl start docker' (Linux)${NC}"
    echo ""
    read -p "Press Enter after starting Docker (or 'q' to quit): " DOCKER_WAIT < /dev/tty
    if [ "$DOCKER_WAIT" = "q" ]; then exit 0; fi

    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Docker still not running. Please start it and try again.${NC}"
        read -p "Press Enter to exit" < /dev/tty
        exit 1
    fi
    echo -e "${GREEN}Docker is now running!${NC}"
    echo ""
fi

# Auto-skip base if all required tools installed
BASE_INSTALLED=true
if [ "$HAS_NODE" != "true" ] || [ "$HAS_GIT" != "true" ] || [ "$HAS_CLAUDE" != "true" ] || [ "$HAS_BKIT" != "true" ]; then
    BASE_INSTALLED=false
fi
if [ "$NEEDS_DOCKER" = true ] && [ "$HAS_DOCKER" != "true" ]; then
    BASE_INSTALLED=false
fi

if [ "$BASE_INSTALLED" = true ] && [ "$SKIP_BASE" = false ] && [ -n "$SELECTED_MODULES" ]; then
    echo -e "${GREEN}All base tools are already installed. Skipping base.${NC}"
    SKIP_BASE=true
    echo ""
fi

# Export NEEDS_DOCKER for base module
export NEEDS_DOCKER

# ============================================
# 6. Calculate Steps & Show Selection
# ============================================
TOTAL_STEPS=0
if [ "$SKIP_BASE" = false ]; then ((TOTAL_STEPS++)) || true; fi
for mod in $SELECTED_MODULES; do
    ((TOTAL_STEPS++)) || true
done

if [ $TOTAL_STEPS -eq 0 ]; then
    TOTAL_STEPS=1
    SKIP_BASE=false
fi

echo "Selected modules:"
if [ "$SKIP_BASE" = false ]; then
    echo -e "  ${GREEN}[*] Base (Claude + bkit)${NC}"
else
    echo -e "  ${GRAY}[ ] Base (skipped)${NC}"
fi

for mod in $SELECTED_MODULES; do
    idx=$(get_module_index "$mod")
    echo -e "  ${GREEN}[*] ${MODULE_DISPLAY_NAMES[$idx]}${NC}"
done
echo ""
[ "$CI" != "true" ] && read -p "Press Enter to start installation" < /dev/tty

# ============================================
# 7. Module Execution Function
# ============================================
run_module() {
    local module_name=$1
    local step=$2
    local total=$3

    local idx=$(get_module_index "$module_name")
    local display_name="${MODULE_DISPLAY_NAMES[$idx]}"
    local description="${MODULE_DESCRIPTIONS[$idx]}"

    echo ""
    echo "========================================"
    echo -e "${CYAN}  [$step/$total] $display_name${NC}"
    echo "========================================"
    echo -e "  ${GRAY}$description${NC}"
    echo ""

    # Temporarily disable set -e to catch errors
    set +e
    if [ "$USE_LOCAL" = true ]; then
        source "$SCRIPT_DIR/modules/$module_name/install.sh"
        local result=$?
    else
        curl -sSL "$BASE_URL/modules/$module_name/install.sh" | bash
        local result=$?
    fi
    set -e

    if [ $result -ne 0 ]; then
        echo ""
        echo -e "${RED}Error in $display_name (exit code: $result)${NC}"
        echo -e "${RED}Installation aborted.${NC}"
        read -p "Press Enter to exit" < /dev/tty
        exit 1
    fi
}

# ============================================
# 8. Execute Modules
# ============================================
CURRENT_STEP=0

# Base module
if [ "$SKIP_BASE" = false ]; then
    ((CURRENT_STEP++)) || true
    run_module "base" $CURRENT_STEP $TOTAL_STEPS
fi

# Selected modules
for mod in $SELECTED_MODULES; do
    ((CURRENT_STEP++)) || true
    run_module "$mod" $CURRENT_STEP $TOTAL_STEPS
done

# ============================================
# 9. Completion Summary
# ============================================
echo ""
echo "========================================"
echo -e "${GREEN}  Installation Complete!${NC}"
echo "========================================"
echo ""
echo "Installed:"

if [ "$SKIP_BASE" = false ]; then
    if command -v node > /dev/null 2>&1; then echo -e "  ${GREEN}[OK] Node.js${NC}"; fi
    if command -v git > /dev/null 2>&1; then echo -e "  ${GREEN}[OK] Git${NC}"; fi
    if [ "$NEEDS_DOCKER" = true ]; then
        if command -v docker > /dev/null 2>&1; then
            echo -e "  ${GREEN}[OK] Docker${NC}"
        else
            echo -e "  ${YELLOW}[!] Docker (start Docker Desktop)${NC}"
        fi
    fi
    if command -v claude > /dev/null 2>&1; then echo -e "  ${GREEN}[OK] Claude Code CLI${NC}"; fi
    if claude plugin list 2>/dev/null | grep -q "bkit"; then echo -e "  ${GREEN}[OK] bkit Plugin${NC}"; fi
fi

# Check MCP config
MCP_CONFIG="$HOME/.mcp.json"
if [ -f "$MCP_CONFIG" ]; then
    for mod in $SELECTED_MODULES; do
        idx=$(get_module_index "$mod")
        display_name="${MODULE_DISPLAY_NAMES[$idx]}"
        echo -e "  ${GREEN}[OK] $display_name${NC}"
    done
fi

echo ""
[ "$CI" != "true" ] && read -p "Press Enter to close" < /dev/tty
