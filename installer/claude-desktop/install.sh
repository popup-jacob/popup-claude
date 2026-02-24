#!/bin/bash
# ============================================
# ADW - Claude Desktop Installer (Mac/Linux)
# ============================================
# Usage: curl -fsSL <raw-url>/install.sh | bash
#   or:  ./install.sh
#
# Environment variables:
#   MODULES  — comma-separated MCP modules (github,figma,notion)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'

# Parse MODULES env var
IFS=',' read -ra REQUESTED_MODULES <<< "${MODULES:-}"
HAS_MODULES=false
CLEAN_MODULES=()
for mod in "${REQUESTED_MODULES[@]}"; do
    mod=$(echo "$mod" | xargs) # trim whitespace
    if [ -n "$mod" ]; then
        CLEAN_MODULES+=("$mod")
        HAS_MODULES=true
    fi
done

TOTAL_STEPS=3
if [ "$HAS_MODULES" = true ]; then
    TOTAL_STEPS=4
fi

# ============================================
# Header
# ============================================
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  ADW - Claude Desktop Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${GRAY}AI-Driven Work environment installer${NC}"
if [ "$HAS_MODULES" = true ]; then
    echo -e "${GRAY}Modules: $(IFS=', '; echo "${CLEAN_MODULES[*]}")${NC}"
fi
echo ""

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./install.sh          Install Claude Desktop"
    echo ""
    echo -e "${YELLOW}Environment variables:${NC}"
    echo "  MODULES  — comma-separated MCP modules (github,figma,notion)"
    echo ""
    exit 0
fi

# ============================================
# 1. Check if Claude Desktop is already installed
# ============================================
echo -e "${YELLOW}[1/$TOTAL_STEPS] Checking Claude Desktop...${NC}"

CLAUDE_INSTALLED=false

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if [ -d "/Applications/Claude.app" ]; then
        CLAUDE_INSTALLED=true
        echo -e "  ${GREEN}Claude Desktop is already installed.${NC}"
    fi
else
    # Linux - check common locations
    if command -v claude-desktop > /dev/null 2>&1; then
        CLAUDE_INSTALLED=true
        echo -e "  ${GREEN}Claude Desktop is already installed.${NC}"
    elif [ -f "/usr/bin/claude-desktop" ] || [ -f "$HOME/.local/bin/claude-desktop" ]; then
        CLAUDE_INSTALLED=true
        echo -e "  ${GREEN}Claude Desktop found.${NC}"
    fi
fi

# ============================================
# 2. Install Claude Desktop if not found
# ============================================
if [ "$CLAUDE_INSTALLED" = false ]; then
    echo -e "  ${YELLOW}Claude Desktop not found. Installing...${NC}"
    echo ""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - try brew first
        if command -v brew > /dev/null 2>&1; then
            echo -e "  ${YELLOW}Installing via Homebrew...${NC}"
            brew install --cask claude
            if [ -d "/Applications/Claude.app" ]; then
                CLAUDE_INSTALLED=true
                echo -e "  ${GREEN}Claude Desktop installed successfully!${NC}"
            fi
        fi

        # Fallback: manual download
        if [ "$CLAUDE_INSTALLED" = false ]; then
            echo ""
            echo -e "  ${YELLOW}Please download Claude Desktop manually:${NC}"
            echo -e "  ${CYAN}https://claude.ai/download${NC}"
            echo ""
            open "https://claude.ai/download" 2>/dev/null
            echo -e "  ${YELLOW}Browser opened. Install Claude Desktop, then run this script again.${NC}"
            echo ""
            read -p "  Press Enter after installing Claude Desktop" < /dev/tty

            if [ -d "/Applications/Claude.app" ]; then
                CLAUDE_INSTALLED=true
                echo -e "  ${GREEN}Claude Desktop detected!${NC}"
            fi
        fi
    else
        # Linux
        echo -e "  ${YELLOW}Please download Claude Desktop:${NC}"
        echo -e "  ${CYAN}https://claude.ai/download${NC}"
        echo ""
        if command -v xdg-open > /dev/null 2>&1; then
            xdg-open "https://claude.ai/download" 2>/dev/null
        fi
        echo -e "  ${YELLOW}Install Claude Desktop, then run this script again.${NC}"
        echo ""
        read -p "  Press Enter after installing Claude Desktop" < /dev/tty

        if command -v claude-desktop > /dev/null 2>&1 || [ -f "/usr/bin/claude-desktop" ]; then
            CLAUDE_INSTALLED=true
            echo -e "  ${GREEN}Claude Desktop detected!${NC}"
        fi
    fi

    if [ "$CLAUDE_INSTALLED" = false ]; then
        echo -e "  ${RED}Claude Desktop still not detected.${NC}"
        echo -e "  ${YELLOW}Please install it and run this script again.${NC}"
        echo ""
        exit 1
    fi
fi

# ============================================
# 3. Ensure config directory & file exist
# ============================================
echo ""
echo -e "${YELLOW}[2/$TOTAL_STEPS] Setting up configuration...${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
else
    CONFIG_DIR="$HOME/.config/Claude"
fi
CONFIG_PATH="$CONFIG_DIR/claude_desktop_config.json"

if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo -e "  ${GRAY}Created config directory: $CONFIG_DIR${NC}"
fi

if [ ! -f "$CONFIG_PATH" ]; then
    echo '{ "mcpServers": {} }' > "$CONFIG_PATH"
    echo -e "  ${GRAY}Created default config: $CONFIG_PATH${NC}"
else
    echo -e "  ${GRAY}Config file already exists.${NC}"
fi

echo -e "  ${GREEN}OK${NC}"

# ============================================
# 4. Configure MCP modules (if requested)
# ============================================
if [ "$HAS_MODULES" = true ]; then
    echo ""
    echo -e "${YELLOW}[3/$TOTAL_STEPS] Configuring MCP modules...${NC}"

    # Check for jq or python for JSON manipulation
    HAS_JQ=false
    HAS_PYTHON=false
    if command -v jq > /dev/null 2>&1; then
        HAS_JQ=true
    elif command -v python3 > /dev/null 2>&1; then
        HAS_PYTHON=true
    fi

    if [ "$HAS_JQ" = false ] && [ "$HAS_PYTHON" = false ]; then
        echo -e "  ${YELLOW}Installing jq for JSON processing...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]] && command -v brew > /dev/null 2>&1; then
            brew install jq
            HAS_JQ=true
        elif command -v apt-get > /dev/null 2>&1; then
            sudo apt-get install -y jq 2>/dev/null && HAS_JQ=true
        fi
    fi

    GITHUB_ADDED=false

    for mod in "${CLEAN_MODULES[@]}"; do
        case "$mod" in
            github)
                echo ""
                echo -e "  ${YELLOW}[GitHub] Configuring MCP server...${NC}"

                # Check Node.js (required for npx)
                if ! command -v node > /dev/null 2>&1; then
                    echo -e "  ${YELLOW}Node.js not found. Installing...${NC}"
                    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew > /dev/null 2>&1; then
                        brew install node
                    elif command -v apt-get > /dev/null 2>&1; then
                        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                        sudo apt-get install -y nodejs
                    else
                        echo -e "  ${RED}Please install Node.js manually: https://nodejs.org/${NC}"
                    fi
                fi

                # Also install gh CLI
                if ! command -v gh > /dev/null 2>&1; then
                    echo -e "  ${YELLOW}Installing GitHub CLI (gh)...${NC}"
                    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew > /dev/null 2>&1; then
                        brew install gh
                    elif command -v apt-get > /dev/null 2>&1; then
                        (type -p wget >/dev/null || sudo apt-get install wget -y) \
                            && sudo mkdir -p -m 755 /etc/apt/keyrings \
                            && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
                            && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
                            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
                            && sudo apt-get update \
                            && sudo apt-get install gh -y
                    fi
                fi

                # Add to config via jq or python
                if [ "$HAS_JQ" = true ]; then
                    jq '.mcpServers.github = {"command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":""}}' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
                elif [ "$HAS_PYTHON" = true ]; then
                    python3 -c "
import json
with open('$CONFIG_PATH', 'r') as f: c = json.load(f)
c.setdefault('mcpServers', {})['github'] = {'command':'npx','args':['-y','@modelcontextprotocol/server-github'],'env':{'GITHUB_PERSONAL_ACCESS_TOKEN':''}}
with open('$CONFIG_PATH', 'w') as f: json.dump(c, f, indent=2)
"
                fi

                GITHUB_ADDED=true
                echo -e "  ${GREEN}GitHub MCP added to config.${NC}"
                echo -e "  ${GRAY}Note: Set your GitHub token in config after setup.${NC}"
                ;;
            figma)
                echo ""
                echo -e "  ${YELLOW}[Figma] Configuring MCP server...${NC}"

                if ! command -v node > /dev/null 2>&1; then
                    echo -e "  ${YELLOW}Node.js not found. Installing...${NC}"
                    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew > /dev/null 2>&1; then
                        brew install node
                    elif command -v apt-get > /dev/null 2>&1; then
                        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                        sudo apt-get install -y nodejs
                    else
                        echo -e "  ${RED}Please install Node.js manually: https://nodejs.org/${NC}"
                    fi
                fi

                if [ "$HAS_JQ" = true ]; then
                    jq '.mcpServers.figma = {"command":"npx","args":["-y","mcp-remote","https://mcp.figma.com/mcp"]}' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
                elif [ "$HAS_PYTHON" = true ]; then
                    python3 -c "
import json
with open('$CONFIG_PATH', 'r') as f: c = json.load(f)
c.setdefault('mcpServers', {})['figma'] = {'command':'npx','args':['-y','mcp-remote','https://mcp.figma.com/mcp']}
with open('$CONFIG_PATH', 'w') as f: json.dump(c, f, indent=2)
"
                fi

                echo -e "  ${GREEN}Figma MCP added (OAuth on first use).${NC}"
                ;;
            notion)
                echo ""
                echo -e "  ${YELLOW}[Notion] Configuring MCP server...${NC}"

                if ! command -v node > /dev/null 2>&1; then
                    echo -e "  ${YELLOW}Node.js not found. Installing...${NC}"
                    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew > /dev/null 2>&1; then
                        brew install node
                    elif command -v apt-get > /dev/null 2>&1; then
                        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                        sudo apt-get install -y nodejs
                    else
                        echo -e "  ${RED}Please install Node.js manually: https://nodejs.org/${NC}"
                    fi
                fi

                if [ "$HAS_JQ" = true ]; then
                    jq '.mcpServers.notion = {"command":"npx","args":["-y","mcp-remote","https://mcp.notion.com/mcp"]}' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
                elif [ "$HAS_PYTHON" = true ]; then
                    python3 -c "
import json
with open('$CONFIG_PATH', 'r') as f: c = json.load(f)
c.setdefault('mcpServers', {})['notion'] = {'command':'npx','args':['-y','mcp-remote','https://mcp.notion.com/mcp']}
with open('$CONFIG_PATH', 'w') as f: json.dump(c, f, indent=2)
"
                fi

                echo -e "  ${GREEN}Notion MCP added (OAuth on first use).${NC}"
                ;;
            *)
                echo -e "  ${YELLOW}Unknown module: $mod (skipped)${NC}"
                ;;
        esac
    done

    echo ""
    echo -e "  ${GREEN}MCP config updated.${NC}"
fi

# ============================================
# Summary
# ============================================
echo ""
echo -e "${YELLOW}[$TOTAL_STEPS/$TOTAL_STEPS] Done!${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Claude Desktop Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "  ${GRAY}App:    /Applications/Claude.app${NC}"
else
    echo -e "  ${GRAY}App:    claude-desktop${NC}"
fi
echo -e "  ${GRAY}Config: $CONFIG_PATH${NC}"
if [ "$HAS_MODULES" = true ]; then
    echo -e "  ${GRAY}MCP:    $(IFS=', '; echo "${CLEAN_MODULES[*]}")${NC}"
fi
echo ""
if [ "$GITHUB_ADDED" = true ]; then
    echo -e "  ${YELLOW}[Action Required] GitHub MCP needs a personal access token.${NC}"
    echo -e "  ${WHITE}1. Go to https://github.com/settings/tokens${NC}"
    echo -e "  ${WHITE}2. Create a token with repo scope${NC}"
    echo -e "  ${WHITE}3. Edit $CONFIG_PATH${NC}"
    echo -e "  ${WHITE}   Set GITHUB_PERSONAL_ACCESS_TOKEN to your token${NC}"
    echo ""
fi
echo "  Launch Claude Desktop and sign in to get started."
echo ""
