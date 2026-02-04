#!/bin/bash
# ============================================
# Base Module - Claude + bkit Installation (Mac/Linux)
# ============================================
# This module installs: Homebrew, Node.js, Git, VS Code, Docker, Claude CLI, bkit Plugin

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

DOCKER_NEEDS_RESTART=false

# ============================================
# 1. Homebrew (Mac only)
# ============================================
echo -e "${YELLOW}[1/7] Checking Homebrew...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo -e "  ${GRAY}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    echo -e "  ${GREEN}OK${NC}"
else
    echo -e "  ${GRAY}Skipped (Linux)${NC}"
fi

# ============================================
# 2. Node.js
# ============================================
echo ""
echo -e "${YELLOW}[2/7] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "  ${GRAY}Installing Node.js...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install node
    else
        # Linux - use NodeSource
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
fi
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "  ${GREEN}OK - $NODE_VERSION${NC}"
else
    echo -e "  ${YELLOW}Installed (restart terminal to use)${NC}"
fi

# ============================================
# 3. Git
# ============================================
echo ""
echo -e "${YELLOW}[3/7] Checking Git...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "  ${GRAY}Installing Git...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git
    else
        sudo apt-get install -y git
    fi
fi
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo -e "  ${GREEN}OK - $GIT_VERSION${NC}"
else
    echo -e "  ${YELLOW}Installed (restart terminal to use)${NC}"
fi

# ============================================
# 4. VS Code
# ============================================
echo ""
echo -e "${YELLOW}[4/7] Checking VS Code...${NC}"
if ! command -v code &> /dev/null && [ ! -d "/Applications/Visual Studio Code.app" ]; then
    echo -e "  ${GRAY}Installing VS Code...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install --cask visual-studio-code
    else
        # Linux - use snap or download
        if command -v snap &> /dev/null; then
            sudo snap install code --classic
        else
            echo -e "  ${YELLOW}Please install VS Code manually from https://code.visualstudio.com${NC}"
        fi
    fi
fi
echo -e "  ${GREEN}OK${NC}"

# ============================================
# 5. Docker Desktop (only if needed)
# ============================================
echo ""
echo -e "${YELLOW}[5/7] Checking Docker...${NC}"
if [ "$NEEDS_DOCKER" = true ]; then
    if ! command -v docker &> /dev/null; then
        echo -e "  ${GRAY}Installing Docker Desktop...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install --cask docker
            DOCKER_NEEDS_RESTART=true
            echo -e "  ${YELLOW}Installed (start Docker Desktop after setup)${NC}"
        else
            # Linux
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
            DOCKER_NEEDS_RESTART=true
            echo -e "  ${YELLOW}Installed (logout/login required)${NC}"
        fi
    else
        echo -e "  ${GREEN}OK${NC}"
    fi
else
    echo -e "  ${GRAY}Skipped (not required by selected modules)${NC}"
fi

# ============================================
# 6. Claude Code CLI
# ============================================
echo ""
echo -e "${YELLOW}[6/7] Checking Claude Code CLI...${NC}"
if ! command -v claude &> /dev/null; then
    echo -e "  ${GRAY}Installing Claude Code CLI...${NC}"
    npm install -g @anthropic-ai/claude-code
fi
if command -v claude &> /dev/null; then
    echo -e "  ${GREEN}OK${NC}"
else
    echo -e "  ${YELLOW}Installed (restart terminal to use)${NC}"
fi

# ============================================
# 7. bkit Plugin
# ============================================
echo ""
echo -e "${YELLOW}[7/7] Installing bkit Plugin...${NC}"
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>/dev/null || true
claude plugin install bkit@bkit-marketplace 2>/dev/null || true

if claude plugin list 2>/dev/null | grep -q "bkit"; then
    echo -e "  ${GREEN}OK${NC}"
else
    echo -e "  ${YELLOW}Installed (verify with 'claude plugin list')${NC}"
fi

# ============================================
# Summary
# ============================================
echo ""
echo "----------------------------------------"
echo -e "${GREEN}Base installation complete!${NC}"

if [ "$DOCKER_NEEDS_RESTART" = true ]; then
    echo ""
    echo -e "${YELLOW}IMPORTANT: Docker was installed.${NC}"
    echo "  1. Start Docker Desktop"
    echo "  2. Run installer again with --skip-base flag:"
    echo -e "     ${CYAN}./install.sh --modules \"google,atlassian\" --skip-base${NC}"
fi
