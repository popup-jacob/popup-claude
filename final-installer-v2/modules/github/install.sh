#!/bin/bash
# ============================================
# GitHub CLI Module (Mac/Linux)
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo "GitHub CLI (gh) lets Claude access:"
echo -e "  ${GRAY}- View/create issues and PRs${NC}"
echo -e "  ${GRAY}- Manage repositories${NC}"
echo -e "  ${GRAY}- Run GitHub Actions${NC}"
echo ""

# Check/Install gh CLI
echo -e "${YELLOW}[Check] GitHub CLI (gh)...${NC}"

if ! command -v gh > /dev/null 2>&1; then
    echo -e "  ${YELLOW}gh CLI not found. Installing...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use Homebrew
        if command -v brew > /dev/null 2>&1; then
            brew install gh
        else
            echo -e "  ${RED}Homebrew not found. Please install gh manually: https://cli.github.com/${NC}"
            exit 1
        fi
    else
        # Linux
        if command -v apt > /dev/null 2>&1; then
            # Debian/Ubuntu
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh -y
        elif command -v dnf > /dev/null 2>&1; then
            # Fedora/RHEL
            sudo dnf install gh -y
        else
            echo -e "  ${RED}Please install gh manually: https://cli.github.com/${NC}"
            exit 1
        fi
    fi

    if ! command -v gh > /dev/null 2>&1; then
        echo -e "  ${RED}gh installation failed.${NC}"
        exit 1
    fi
fi

GH_VERSION=$(gh --version | head -1)
echo -e "  ${GREEN}OK ($GH_VERSION)${NC}"

# Check auth status
echo ""
echo -e "${YELLOW}[Check] GitHub authentication...${NC}"

if ! gh auth status > /dev/null 2>&1; then
    echo -e "  ${YELLOW}Not logged in. Starting authentication...${NC}"
    echo ""
    echo "A browser will open for GitHub login."
    echo ""

    gh auth login --hostname github.com --git-protocol https --web

    if [ $? -ne 0 ]; then
        echo -e "  ${RED}Authentication failed or cancelled.${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}Logged in successfully!${NC}"
else
    echo -e "  ${GREEN}Already logged in.${NC}"
fi

echo ""
echo "----------------------------------------"
echo -e "${GREEN}GitHub CLI installation complete!${NC}"
echo ""
echo -e "${GRAY}Note: gh CLI is used directly by Claude via Bash tool.${NC}"
echo -e "${GRAY}No MCP configuration needed.${NC}"
