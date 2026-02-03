#!/bin/bash
# Google Workspace MCP - Admin Setup Script (Mac/Linux)
# Usage: chmod +x setup_admin.sh && ./setup_admin.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Google Workspace MCP - Admin Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ============================================
# Step 1: Check and Install gcloud CLI
# ============================================
echo -e "${YELLOW}[1/6] Checking gcloud CLI...${NC}"

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}gcloud CLI is not installed.${NC}"
    echo ""

    # Mac: Use Homebrew
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo -e "${YELLOW}Installing gcloud CLI via Homebrew...${NC}"
            echo -e "${GRAY}(This may take a few minutes)${NC}"
            echo ""

            brew install --cask google-cloud-sdk

            # Source the completion scripts
            if [ -f "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc" ]; then
                source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
            fi
        else
            echo -e "${YELLOW}Homebrew not found. Installing gcloud manually...${NC}"
            echo ""
            curl https://sdk.cloud.google.com | bash
            echo ""
            echo "gcloud installed. Please restart terminal and run this script again."
            exit 0
        fi
    # Linux: Use curl installer
    else
        echo -e "${YELLOW}Installing gcloud CLI...${NC}"
        echo -e "${GRAY}(This may take a few minutes)${NC}"
        echo ""

        curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
        source "$HOME/google-cloud-sdk/path.bash.inc"
    fi

    # Check again
    if ! command -v gcloud &> /dev/null; then
        echo ""
        echo -e "${YELLOW}gcloud installed but not in PATH yet.${NC}"
        echo "Please close this terminal and run the script again."
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
fi
echo -e "${GREEN}gcloud CLI OK!${NC}"

# ============================================
# Step 2: Check gcloud login
# ============================================
echo ""
echo -e "${YELLOW}[2/6] Checking gcloud login...${NC}"

ACCOUNT=$(gcloud config get-value account 2>/dev/null)
if [ -z "$ACCOUNT" ] || [ "$ACCOUNT" == "(unset)" ]; then
    echo "Not logged in. Opening browser for login..."
    gcloud auth login
    ACCOUNT=$(gcloud config get-value account 2>/dev/null)
fi
echo -e "${GREEN}Logged in as: $ACCOUNT${NC}"

# ============================================
# Step 3: Ask Internal vs External
# ============================================
echo ""
echo -e "${YELLOW}[3/6] Setup type selection...${NC}"
echo ""
echo "Do you use Google Workspace (company email like @company.com)?"
echo ""
echo "  1. Yes - I have a company email (@company.com)"
echo -e "${GRAY}       -> Internal app (unlimited users, no token expiry)${NC}"
echo ""
echo "  2. No - I use personal Gmail (@gmail.com)"
echo -e "${GRAY}       -> External app (100 test users, 7-day token expiry)${NC}"
echo ""

read -p "Select (1 or 2): " CHOICE

if [ "$CHOICE" == "1" ]; then
    APP_TYPE="internal"
    echo -e "${GREEN}Selected: Internal (Google Workspace)${NC}"
else
    APP_TYPE="external"
    echo -e "${GREEN}Selected: External (Personal Gmail)${NC}"
fi

# ============================================
# Step 4: Create or select project
# ============================================
echo ""
echo -e "${YELLOW}[4/6] Setting up Google Cloud project...${NC}"
echo ""
echo "Options:"
echo "  1. Create new project"
echo "  2. Use existing project"
echo ""

read -p "Select (1 or 2): " PROJECT_CHOICE

if [ "$PROJECT_CHOICE" == "1" ]; then
    PROJECT_ID="workspace-mcp-$((RANDOM % 900000 + 100000))"
    echo -e "${YELLOW}Creating project: $PROJECT_ID${NC}"
    gcloud projects create "$PROJECT_ID" --name="Google Workspace MCP"
    gcloud config set project "$PROJECT_ID"
else
    echo ""
    echo "Available projects:"
    gcloud projects list --format="table(projectId,name)" 2>/dev/null
    echo ""
    read -p "Enter project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
fi
echo -e "${GREEN}Project set: $PROJECT_ID${NC}"

# ============================================
# Step 5: Enable APIs
# ============================================
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
    echo -e "${GRAY}  Enabling $API...${NC}"
    gcloud services enable "$API" 2>/dev/null || true
done
echo -e "${GREEN}All APIs enabled!${NC}"

# ============================================
# Step 6: OAuth Consent Screen (Manual)
# ============================================
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

if [ "$APP_TYPE" == "internal" ]; then
    echo -e "  ${CYAN}[1] App Info${NC}"
    echo "      - App name: Google Workspace MCP"
    echo "      - User support email: (select your email)"
    echo -e "${GRAY}      -> Click 'Next'${NC}"
    echo ""
    echo -e "  ${CYAN}[2] Audience${NC}"
    echo -e "      - ${YELLOW}Select 'Internal'${NC}"
    echo -e "${GRAY}      -> Click 'Next'${NC}"
    echo ""
    echo -e "  ${CYAN}[3] Contact Info${NC}"
    echo "      - Email: (enter your email)"
    echo -e "${GRAY}      -> Click 'Next'${NC}"
    echo ""
    echo -e "  ${CYAN}[4] Finish${NC}"
    echo "      - Check the agreement box"
    echo -e "${GRAY}      -> Click 'Continue'${NC}"
else
    echo -e "  ${CYAN}[1] App Info${NC}"
    echo "      - App name: Google Workspace MCP"
    echo "      - User support email: (select your email)"
    echo -e "${GRAY}      -> Click 'Next'${NC}"
    echo ""
    echo -e "  ${CYAN}[2] Audience${NC}"
    echo -e "      - ${YELLOW}Select 'External'${NC}"
    echo -e "${GRAY}      -> Click 'Next'${NC}"
    echo ""
    echo -e "  ${CYAN}[3] Contact Info${NC}"
    echo "      - Email: (enter your email)"
    echo -e "${GRAY}      -> Click 'Next'${NC}"
    echo ""
    echo -e "  ${CYAN}[4] Finish${NC}"
    echo "      - Check the agreement box"
    echo -e "${GRAY}      -> Click 'Continue'${NC}"
    echo ""
    echo -e "  ${YELLOW}[5] After setup, add TEST USERS:${NC}"
    echo "      - Left menu: click 'Audience'"
    echo "      - Click 'Add Users' and add your email"
fi

echo ""
echo -e "${GRAY}----------------------------------------${NC}"
read -p "Press Enter when you have completed the above steps..."

# ============================================
# Step 7: Create OAuth Client
# ============================================
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

echo -e "${GRAY}----------------------------------------${NC}"
read -p "Press Enter when you have saved client_secret.json..."

# Verify file exists
CLIENT_SECRET_PATH="$CONFIG_DIR/client_secret.json"
if [ -f "$CLIENT_SECRET_PATH" ]; then
    echo -e "${GREEN}client_secret.json found!${NC}"
else
    echo -e "${YELLOW}Warning: client_secret.json not found at $CLIENT_SECRET_PATH${NC}"
    echo -e "${YELLOW}Make sure to save it there before running employee setup.${NC}"
fi

# ============================================
# Done
# ============================================
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Admin Setup Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Summary:"
echo "  - Project: $PROJECT_ID"
echo "  - App Type: $APP_TYPE"
echo "  - APIs: 6 enabled"
echo "  - OAuth: Configured"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run ./setup_all.sh (for yourself)"
echo "  2. Share client_secret.json with team members"
echo "  3. Team members run ./setup_all.sh"
echo ""

if [ "$APP_TYPE" == "external" ]; then
    echo -e "${YELLOW}Note (External app):${NC}"
    echo "  - Add test user emails in OAuth consent screen"
    echo "  - Tokens expire every 7 days (re-login required)"
    echo ""
fi
