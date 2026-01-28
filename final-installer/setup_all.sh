#!/bin/bash
# AI-Driven Work - Complete Setup Script (Mac/Linux)
# Usage: chmod +x setup_all.sh && ./setup_all.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  AI-Driven Work - Complete Setup"
echo "========================================"
echo ""
echo "This script will install:"
echo "  - Node.js, Git, VS Code"
echo "  - Docker Desktop"
echo "  - Claude Code CLI"
echo "  - bkit Plugin"
echo "  - Google MCP (optional)"
echo "  - Jira/Confluence MCP (optional)"
echo ""
read -p "Press Enter to start"

# ============================================
# PART 1: Basic Tools Installation
# ============================================
echo ""
echo "========================================"
echo -e "${CYAN}  PART 1: Installing Basic Tools${NC}"
echo "========================================"

# Install Homebrew if not exists
echo ""
echo -e "${YELLOW}[1/6] Checking Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo -e "${GREEN}Homebrew OK!${NC}"

# Install Node.js
echo ""
echo -e "${YELLOW}[2/6] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    brew install node
fi
echo -e "${GREEN}Node.js OK!${NC}"

# Install Git
echo ""
echo -e "${YELLOW}[3/6] Checking Git...${NC}"
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    brew install git
fi
echo -e "${GREEN}Git OK!${NC}"

# Install VS Code
echo ""
echo -e "${YELLOW}[4/6] Checking VS Code...${NC}"
if ! command -v code &> /dev/null; then
    echo "Installing VS Code..."
    brew install --cask visual-studio-code
fi
echo -e "${GREEN}VS Code OK!${NC}"

# Install Docker Desktop
echo ""
echo -e "${YELLOW}[5/6] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Installing Docker Desktop..."
    brew install --cask docker
    echo ""
    echo -e "${YELLOW}Docker installed. Please start Docker Desktop after setup.${NC}"
fi
echo -e "${GREEN}Docker OK!${NC}"

# Install Claude Code CLI
echo ""
echo -e "${YELLOW}[6/6] Checking Claude Code CLI...${NC}"
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
fi
echo -e "${GREEN}Claude Code CLI OK!${NC}"

# ============================================
# PART 2: bkit Plugin Installation
# ============================================
echo ""
echo "========================================"
echo -e "${CYAN}  PART 2: Installing bkit Plugin${NC}"
echo "========================================"

echo ""
echo -e "${YELLOW}Adding bkit marketplace...${NC}"
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>/dev/null

echo -e "${YELLOW}Installing bkit plugin...${NC}"
claude plugin install bkit@bkit-marketplace 2>/dev/null
echo -e "${GREEN}bkit OK!${NC}"

# ============================================
# PART 3: Google MCP (Optional)
# ============================================
echo ""
echo "========================================"
echo -e "${CYAN}  PART 3: Google MCP (Optional)${NC}"
echo "========================================"
echo ""
echo "Google MCP lets Claude access:"
echo "  - Gmail (read, send emails)"
echo "  - Calendar (view, create events)"
echo "  - Drive (search, download files)"
echo "  - Docs, Sheets, Slides"
echo ""

read -p "Set up Google MCP? (y/n): " googleChoice

if [[ "$googleChoice" == "y" || "$googleChoice" == "Y" ]]; then
    echo ""
    echo "What is your role?"
    echo "  1. Admin (setting up for the first time)"
    echo "  2. Employee (received files from admin)"
    echo ""
    read -p "Select (1/2): " roleChoice

    if [[ "$roleChoice" == "1" ]]; then
        # Admin path
        echo ""
        echo "========================================"
        echo -e "${YELLOW}  Admin Setup Required${NC}"
        echo "========================================"
        echo ""
        echo "You need to set up Google Cloud Console first."
        echo ""
        echo "Required steps:"
        echo "  1. Create Google Cloud project"
        echo "  2. Enable APIs (Gmail, Calendar, Drive, etc.)"
        echo "  3. Set up OAuth consent screen"
        echo "  4. Create OAuth Client ID"
        echo "  5. Download client_secret.json"
        echo ""

        read -p "Open setup guide in browser? (y/n): " openGuide
        if [[ "$openGuide" == "y" || "$openGuide" == "Y" ]]; then
            open "https://console.cloud.google.com" 2>/dev/null || xdg-open "https://console.cloud.google.com" 2>/dev/null
            echo ""
            echo "After completing the setup:"
            echo "  1. Run this script again"
            echo "  2. Select 'Employee' option"
            echo "  3. Provide client_secret.json"
        fi
        echo ""
        echo -e "${YELLOW}Google MCP admin setup skipped for now.${NC}"

    else
        # Employee path
        echo ""
        echo -e "${YELLOW}Setting up Google MCP...${NC}"

        # Create config folder
        CONFIG_DIR="$HOME/.google-workspace"
        mkdir -p "$CONFIG_DIR"

        # Check for client_secret.json
        CLIENT_SECRET_PATH="$CONFIG_DIR/client_secret.json"
        if [[ ! -f "$CLIENT_SECRET_PATH" ]]; then
            echo ""
            echo "client_secret.json file is required."
            echo "Copy the file from admin to this folder:"
            echo -e "  ${CYAN}$CLIENT_SECRET_PATH${NC}"
            echo ""

            # Open Finder (Mac)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "$CONFIG_DIR"
            fi

            read -p "Copy the file and press Enter..."

            if [[ ! -f "$CLIENT_SECRET_PATH" ]]; then
                echo -e "${RED}client_secret.json not found. Skipping Google MCP.${NC}"
            fi
        fi

        if [[ -f "$CLIENT_SECRET_PATH" ]]; then
            # Pull Docker image from ghcr.io
            echo ""
            echo -e "${YELLOW}Pulling Google MCP Docker image...${NC}"
            docker pull ghcr.io/popup-jacob/google-workspace-mcp:latest
            echo -e "${GREEN}Image pulled!${NC}"

            # Create .mcp.json
            IMAGE_EXISTS=$(docker images -q ghcr.io/popup-jacob/google-workspace-mcp 2>/dev/null)
            if [[ -n "$IMAGE_EXISTS" ]]; then
                MCP_CONFIG_PATH="$HOME/.mcp.json"

                # Create or update config
                if [[ -f "$MCP_CONFIG_PATH" ]]; then
                    # Simple append - in real scenario would need jq for proper JSON handling
                    echo -e "${YELLOW}Note: Please manually add google-workspace to existing .mcp.json${NC}"
                else
                    cat > "$MCP_CONFIG_PATH" << EOF
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "$CONFIG_DIR:/app/.google-workspace",
        "ghcr.io/popup-jacob/google-workspace-mcp:latest"
      ]
    }
  }
}
EOF
                fi
                echo -e "${GREEN}Google MCP configured!${NC}"
            fi
        fi
    fi
else
    echo "Google MCP skipped."
fi

# ============================================
# PART 4: Jira/Confluence MCP (Optional)
# ============================================
echo ""
echo "========================================"
echo -e "${CYAN}  PART 4: Jira/Confluence MCP (Optional)${NC}"
echo "========================================"
echo ""
echo "Jira/Confluence MCP lets Claude access:"
echo "  - Jira (view issues, create tasks)"
echo "  - Confluence (search, read pages)"
echo ""
echo "Requirements:"
echo "  - Atlassian account"
echo "  - API token from: https://id.atlassian.com/manage-profile/security/api-tokens"
echo ""

read -p "Set up Jira/Confluence MCP? (y/n): " jiraChoice

if [[ "$jiraChoice" == "y" || "$jiraChoice" == "Y" ]]; then
    echo ""
    echo "What is your role?"
    echo "  1. Non-developer (Rovo MCP - just login)"
    echo "  2. Developer (mcp-atlassian - Docker)"
    echo ""
    read -p "Select (1/2): " jiraRoleChoice

    if [[ "$jiraRoleChoice" == "1" ]]; then
        # Rovo MCP (Official Atlassian) - Non-developer
        echo ""
        echo -e "${YELLOW}Setting up Atlassian Rovo MCP...${NC}"
        echo ""
        echo "This will open Atlassian login in your browser."
        echo "Login with your Atlassian account to authorize."
        echo ""

        claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse

        echo ""
        echo -e "${GREEN}Rovo MCP configured!${NC}"
        echo ""
        echo "Guide: https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/"

    else
        # mcp-atlassian - Developer
        echo ""
        echo -e "${YELLOW}Setting up mcp-atlassian...${NC}"
        echo ""
        echo "You need an API token. Get one from:"
        echo -e "  ${CYAN}https://id.atlassian.com/manage-profile/security/api-tokens${NC}"
        echo ""

        read -p "Open API token page in browser? (y/n): " openToken
        if [[ "$openToken" == "y" || "$openToken" == "Y" ]]; then
            open "https://id.atlassian.com/manage-profile/security/api-tokens" 2>/dev/null || xdg-open "https://id.atlassian.com/manage-profile/security/api-tokens" 2>/dev/null
            echo "Create a token and copy it."
            read -p "Press Enter when ready..."
        fi

        echo ""
        read -p "Confluence URL (e.g. https://company.atlassian.net/wiki): " confluenceUrl
        read -p "Jira URL (e.g. https://company.atlassian.net): " jiraUrl
        read -p "Your email: " email
        read -p "API token: " apiToken

        # Pull mcp-atlassian image
        echo ""
        echo -e "${YELLOW}Pulling mcp-atlassian Docker image...${NC}"
        docker pull ghcr.io/sooperset/mcp-atlassian:latest 2>/dev/null

        # Create/update .mcp.json
        MCP_CONFIG_PATH="$HOME/.mcp.json"

        if [[ ! -f "$MCP_CONFIG_PATH" ]]; then
            cat > "$MCP_CONFIG_PATH" << EOF
{
  "mcpServers": {
    "atlassian": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "CONFLUENCE_URL=$confluenceUrl",
        "-e", "CONFLUENCE_USERNAME=$email",
        "-e", "CONFLUENCE_API_TOKEN=$apiToken",
        "-e", "JIRA_URL=$jiraUrl",
        "-e", "JIRA_USERNAME=$email",
        "-e", "JIRA_API_TOKEN=$apiToken",
        "ghcr.io/sooperset/mcp-atlassian:latest"
      ]
    }
  }
}
EOF
            echo -e "${GREEN}Jira/Confluence MCP configured!${NC}"
        else
            echo -e "${YELLOW}Note: Please manually add atlassian to existing .mcp.json${NC}"
        fi
    fi
else
    echo "Jira/Confluence MCP skipped."
fi

# ============================================
# COMPLETE
# ============================================
echo ""
echo "========================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "========================================"
echo ""
echo "Status:"

# Check Node.js
if command -v node &> /dev/null; then
    echo -e "  ${GREEN}[OK] Node.js${NC}"
else
    echo -e "  ${RED}[X] Node.js - not found${NC}"
fi

# Check Git
if command -v git &> /dev/null; then
    echo -e "  ${GREEN}[OK] Git${NC}"
else
    echo -e "  ${RED}[X] Git - not found${NC}"
fi

# Check VS Code
if command -v code &> /dev/null || [ -d "/Applications/Visual Studio Code.app" ]; then
    echo -e "  ${GREEN}[OK] VS Code${NC}"
else
    echo -e "  ${RED}[X] VS Code - not found${NC}"
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "  ${GREEN}[OK] Docker${NC}"
else
    echo -e "  ${YELLOW}[!] Docker - not found (may need to start Docker Desktop)${NC}"
fi

# Check Claude CLI
if command -v claude &> /dev/null; then
    echo -e "  ${GREEN}[OK] Claude Code CLI${NC}"
else
    echo -e "  ${RED}[X] Claude Code CLI - not found${NC}"
fi

# Check bkit plugin
if claude plugin list 2>/dev/null | grep -q "bkit"; then
    echo -e "  ${GREEN}[OK] bkit Plugin${NC}"
else
    echo -e "  ${RED}[X] bkit Plugin - not found${NC}"
fi

echo ""
echo "Next steps:"
echo -e "  ${YELLOW}1. Start Docker Desktop${NC}"
echo "  2. Open VS Code and test Claude"
echo ""
echo "Test commands in Claude:"
echo "  - 'Show my calendar' (Google)"
echo "  - 'List Jira projects' (Jira)"
echo ""
read -p "Press Enter to close"
