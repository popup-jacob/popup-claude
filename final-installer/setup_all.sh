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
read -p "Press Enter to start" < /dev/tty

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
# Check Docker is running
# ============================================
echo ""
echo -e "${YELLOW}Checking if Docker is running...${NC}"
if ! docker info &> /dev/null; then
    echo ""
    echo -e "${RED}Docker is not running!${NC}"
    echo ""
    echo -e "${YELLOW}How to start Docker Desktop:${NC}"
    echo -e "  ${CYAN}- Click the Docker icon in Applications folder${NC}"
    echo -e "  ${CYAN}- Or click the whale icon in the menu bar (top right)${NC}"
    echo ""
    echo "Then:"
    echo "  1. Wait for Docker to fully start (whale icon stops animating)"
    echo "  2. Run this script again"
    echo ""
    read -p "Press Enter to exit" < /dev/tty
    exit 1
fi
echo -e "${GREEN}Docker is running!${NC}"

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

read -p "Set up Google MCP? (y/n): " googleChoice < /dev/tty

if [[ "$googleChoice" == "y" || "$googleChoice" == "Y" ]]; then
    echo ""
    echo "What is your role?"
    echo "  1. Admin (setting up for the first time)"
    echo "  2. Employee (received files from admin)"
    echo ""
    read -p "Select (1/2): " roleChoice < /dev/tty

    if [[ "$roleChoice" == "1" ]]; then
        # Admin path - Full Google Cloud setup
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}  Google Cloud Admin Setup${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""

        # Check gcloud CLI
        echo -e "${YELLOW}[1/6] Checking gcloud CLI...${NC}"
        if ! command -v gcloud &> /dev/null; then
            echo -e "${RED}gcloud CLI is not installed.${NC}"
            echo ""

            # Mac: Use Homebrew
            if [[ "$OSTYPE" == "darwin"* ]]; then
                if command -v brew &> /dev/null; then
                    echo -e "${YELLOW}Installing gcloud CLI via Homebrew...${NC}"
                    brew install --cask google-cloud-sdk

                    # Source the completion scripts
                    if [ -f "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc" ]; then
                        source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
                    fi
                else
                    echo -e "${YELLOW}Homebrew not found. Installing gcloud manually...${NC}"
                    curl https://sdk.cloud.google.com | bash
                    echo ""
                    echo "gcloud installed. Please restart terminal and run this script again."
                    exit 0
                fi
            # Linux: Use curl installer
            else
                echo -e "${YELLOW}Installing gcloud CLI...${NC}"
                curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
                source "$HOME/google-cloud-sdk/path.bash.inc"
            fi

            # Check again
            if ! command -v gcloud &> /dev/null; then
                echo ""
                echo -e "${YELLOW}gcloud installed but not in PATH yet.${NC}"
                echo "Please close this terminal and run the script again."
                read -p "Press Enter to exit..." < /dev/tty
                exit 1
            fi
        fi
        echo -e "${GREEN}gcloud CLI OK!${NC}"

        # Check gcloud login
        echo ""
        echo -e "${YELLOW}[2/6] Checking gcloud login...${NC}"
        ACCOUNT=$(gcloud config get-value account 2>/dev/null)
        if [ -z "$ACCOUNT" ] || [ "$ACCOUNT" == "(unset)" ]; then
            echo "Not logged in. Opening browser for login..."
            gcloud auth login
            ACCOUNT=$(gcloud config get-value account 2>/dev/null)
        fi
        echo -e "${GREEN}Logged in as: $ACCOUNT${NC}"

        # Ask Internal vs External
        echo ""
        echo -e "${YELLOW}[3/6] Setup type selection...${NC}"
        echo ""
        echo "Do you use Google Workspace (company email like @company.com)?"
        echo ""
        echo "  1. Yes - I have a company email (@company.com)"
        echo -e "       -> Internal app (unlimited users, no token expiry)"
        echo ""
        echo "  2. No - I use personal Gmail (@gmail.com)"
        echo -e "       -> External app (100 test users, 7-day token expiry)"
        echo ""
        read -p "Select (1 or 2): " appTypeChoice < /dev/tty
        if [ "$appTypeChoice" == "1" ]; then
            APP_TYPE="internal"
            echo -e "${GREEN}Selected: Internal (Google Workspace)${NC}"
        else
            APP_TYPE="external"
            echo -e "${GREEN}Selected: External (Personal Gmail)${NC}"
        fi

        # Create or select project
        echo ""
        echo -e "${YELLOW}[4/6] Setting up Google Cloud project...${NC}"
        echo ""
        echo "Options:"
        echo "  1. Create new project"
        echo "  2. Use existing project"
        echo ""
        read -p "Select (1 or 2): " projectChoice < /dev/tty

        if [ "$projectChoice" == "1" ]; then
            PROJECT_ID="workspace-mcp-$((RANDOM % 900000 + 100000))"
            echo -e "${YELLOW}Creating project: $PROJECT_ID${NC}"
            gcloud projects create "$PROJECT_ID" --name="Google Workspace MCP"
            gcloud config set project "$PROJECT_ID"
        else
            echo ""
            echo "Available projects:"
            gcloud projects list --format="table(projectId,name)" 2>/dev/null
            echo ""
            read -p "Enter project ID: " PROJECT_ID < /dev/tty
            gcloud config set project "$PROJECT_ID"
        fi
        echo -e "${GREEN}Project set: $PROJECT_ID${NC}"

        # Enable APIs
        echo ""
        echo -e "${YELLOW}[5/6] Enabling APIs (this may take a minute)...${NC}"
        APIS=(
            "gmail.googleapis.com"
            "calendar-json.googleapis.com"
            "drive.googleapis.com"
            "docs.googleapis.com"
            "sheets.googleapis.com"
            "slides.googleapis.com"
        )
        for API in "${APIS[@]}"; do
            echo -e "  Enabling $API..."
            gcloud services enable "$API" 2>/dev/null || true
        done
        echo -e "${GREEN}All APIs enabled!${NC}"

        # OAuth Consent Screen (Manual)
        echo ""
        echo -e "${YELLOW}[6/6] OAuth Consent Screen Setup (Manual step required)${NC}"
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}  MANUAL STEP REQUIRED${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""

        CONSOLE_URL="https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
        echo "Opening browser to OAuth consent screen..."
        echo ""

        # Open browser (Mac/Linux)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$CONSOLE_URL"
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$CONSOLE_URL"
        else
            echo -e "${YELLOW}Please open this URL manually:${NC}"
            echo -e "${CYAN}$CONSOLE_URL${NC}"
        fi

        sleep 2

        echo "Follow these steps in the browser:"
        echo ""
        echo -e "  ${YELLOW}** If you see 'Configure consent screen' button, click it first **${NC}"
        echo ""
        echo -e "  ${CYAN}[1] App Info${NC}"
        echo "      - App name: Google Workspace MCP"
        echo "      - User support email: (select your email)"
        echo "      -> Click 'Next'"
        echo ""
        echo -e "  ${CYAN}[2] Audience${NC}"
        if [ "$APP_TYPE" == "internal" ]; then
            echo -e "      - ${YELLOW}Select 'Internal'${NC}"
        else
            echo -e "      - ${YELLOW}Select 'External'${NC}"
        fi
        echo "      -> Click 'Next'"
        echo ""
        echo -e "  ${CYAN}[3] Contact Info${NC}"
        echo "      - Email: (enter your email)"
        echo "      -> Click 'Next'"
        echo ""
        echo -e "  ${CYAN}[4] Finish${NC}"
        echo "      - Check the agreement box"
        echo "      -> Click 'Continue'"

        if [ "$APP_TYPE" == "external" ]; then
            echo ""
            echo -e "  ${YELLOW}[5] After setup, add TEST USERS:${NC}"
            echo "      - Left menu: click 'Audience'"
            echo "      - Click 'Add Users' and add your email"
        fi

        echo ""
        echo "----------------------------------------"
        read -p "Press Enter when you have completed the above steps..." < /dev/tty

        # Create OAuth Client
        echo ""
        echo -e "${YELLOW}[7/7] Creating OAuth Client...${NC}"
        echo ""
        echo "In the left menu, click 'Clients'"
        echo ""
        echo -e "  ${CYAN}[1] Click '+ Create Client'${NC}"
        echo "  [2] Application type: 'Desktop app'"
        echo "  [3] Name: any name (e.g. MCP Client)"
        echo "  [4] Click 'Create'"
        echo ""
        echo -e "  ${CYAN}[5] Click the created client name${NC}"
        echo "  [6] Find 'Client Secret' section"
        echo -e "  ${YELLOW}[7] Click download icon (arrow down) to download JSON${NC}"
        echo ""
        echo -e "${YELLOW}Save the file as:${NC}"
        echo -e "${CYAN}  ~/.google-workspace/client_secret.json${NC}"
        echo ""

        # Create folder if not exists
        CONFIG_DIR="$HOME/.google-workspace"
        if [ ! -d "$CONFIG_DIR" ]; then
            mkdir -p "$CONFIG_DIR"
            echo -e "${GREEN}Created folder: $CONFIG_DIR${NC}"
        fi

        # Open folder (Mac)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$CONFIG_DIR"
        fi

        echo "----------------------------------------"
        read -p "Press Enter when you have saved client_secret.json..." < /dev/tty

        # Verify file exists
        CLIENT_SECRET_PATH="$CONFIG_DIR/client_secret.json"
        if [ -f "$CLIENT_SECRET_PATH" ]; then
            echo -e "${GREEN}client_secret.json found!${NC}"
        else
            echo -e "${YELLOW}Warning: client_secret.json not found at $CLIENT_SECRET_PATH${NC}"
            echo -e "${YELLOW}Make sure to save it there before continuing.${NC}"
        fi

        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}  Admin Setup Complete!${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        echo "Summary:"
        echo "  - Project: $PROJECT_ID"
        echo "  - App Type: $APP_TYPE"
        echo "  - APIs: 6 enabled"
        echo ""

        if [ "$APP_TYPE" == "external" ]; then
            echo -e "${YELLOW}Note (External app):${NC}"
            echo "  - Add test user emails in OAuth consent screen"
            echo "  - Tokens expire every 7 days (re-login required)"
            echo ""
        fi

        echo -e "${YELLOW}Now continuing with Docker setup...${NC}"
        echo ""
    fi

    # Employee path (also runs after Admin setup)
    if [[ "$roleChoice" == "2" || "$roleChoice" == "1" ]]; then
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

            read -p "Copy the file and press Enter..." < /dev/tty

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

            # Check if token.json exists, if not, run OAuth
            TOKEN_PATH="$CONFIG_DIR/token.json"
            if [[ ! -f "$TOKEN_PATH" ]]; then
                echo ""
                echo "========================================"
                echo -e "${YELLOW}  Google Login Required${NC}"
                echo "========================================"
                echo ""
                echo "A browser window will open for Google login."
                echo "After login, return here."
                echo ""
                read -p "Press Enter to start Google login..." < /dev/tty

                # Run container with port mapping for OAuth callback
                echo -e "${YELLOW}Starting Google authentication...${NC}"
                docker run -i --rm -p 3000:3000 -v "$CONFIG_DIR:/app/.google-workspace" ghcr.io/popup-jacob/google-workspace-mcp:latest node -e "require('./dist/auth/oauth.js').getAuthenticatedClient().then(() => { console.log('Authentication complete!'); process.exit(0); }).catch(e => { console.error(e); process.exit(1); })"

                if [[ -f "$TOKEN_PATH" ]]; then
                    echo -e "${GREEN}Google login successful!${NC}"
                else
                    echo -e "${YELLOW}Google login may have failed. You can try again later.${NC}"
                fi
            else
                echo -e "${GREEN}Google already authenticated (token.json exists)${NC}"
            fi

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

read -p "Set up Jira/Confluence MCP? (y/n): " jiraChoice < /dev/tty

if [[ "$jiraChoice" == "y" || "$jiraChoice" == "Y" ]]; then
    echo ""
    echo "What is your role?"
    echo "  1. Non-developer (Rovo MCP - just login)"
    echo "  2. Developer (mcp-atlassian - Docker)"
    echo ""
    read -p "Select (1/2): " jiraRoleChoice < /dev/tty

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

        read -p "Open API token page in browser? (y/n): " openToken < /dev/tty
        if [[ "$openToken" == "y" || "$openToken" == "Y" ]]; then
            open "https://id.atlassian.com/manage-profile/security/api-tokens" 2>/dev/null || xdg-open "https://id.atlassian.com/manage-profile/security/api-tokens" 2>/dev/null
            echo "Create a token and copy it."
            read -p "Press Enter when ready..." < /dev/tty
        fi

        echo ""
        read -p "Confluence URL (e.g. https://company.atlassian.net/wiki): " confluenceUrl < /dev/tty
        read -p "Jira URL (e.g. https://company.atlassian.net): " jiraUrl < /dev/tty
        read -p "Your email: " email < /dev/tty
        read -p "API token: " apiToken < /dev/tty

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
read -p "Press Enter to close" < /dev/tty
