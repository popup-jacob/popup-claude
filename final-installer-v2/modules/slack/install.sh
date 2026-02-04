#!/bin/bash
# ============================================
# Slack MCP Module (Mac/Linux)
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo "Slack MCP lets Claude access:"
echo -e "  ${GRAY}- Send messages to channels${NC}"
echo -e "  ${GRAY}- Read channel history${NC}"
echo -e "  ${GRAY}- Manage conversations${NC}"
echo ""

# Check Node.js
echo -e "${YELLOW}[Check] Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "  ${RED}Node.js is required. Please install base module first.${NC}"
    exit 1
fi
echo -e "  ${GREEN}OK${NC}"

# Guide for Bot Token
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Slack Bot Token Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "You need a Slack Bot Token. Follow these steps:"
echo ""
echo -e "  ${GRAY}1. Go to https://api.slack.com/apps${NC}"
echo -e "  ${GRAY}2. Click 'Create New App' > 'From scratch'${NC}"
echo -e "  ${GRAY}3. Give it a name, select your workspace${NC}"
echo -e "  ${GRAY}4. Go to 'OAuth & Permissions' (left sidebar)${NC}"
echo -e "  ${GRAY}5. Scroll down to 'Scopes' > 'Bot Token Scopes'${NC}"
echo -e "  ${GRAY}6. Click 'Add an OAuth Scope' and add:${NC}"
echo -e "     ${GRAY}- channels:history, channels:read${NC}"
echo -e "     ${GRAY}- chat:write, groups:history${NC}"
echo -e "     ${GRAY}- im:history, mpim:history${NC}"
echo -e "  ${YELLOW}7. Scroll up and click 'Install to Workspace'${NC}"
echo -e "     ${YELLOW}(Token is generated AFTER this step!)${NC}"
echo -e "  ${GRAY}8. Allow permissions${NC}"
echo -e "  ${GRAY}9. Copy 'Bot User OAuth Token' (xoxb-...)${NC}"
echo ""

read -p "Open Slack API page in browser? (y/n): " openPage < /dev/tty
if [ "$openPage" = "y" ] || [ "$openPage" = "Y" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "https://api.slack.com/apps"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://api.slack.com/apps"
    fi
    echo -e "${YELLOW}Create your app and copy the Bot Token.${NC}"
    read -p "Press Enter when ready" < /dev/tty
fi

echo ""
read -p "Bot User OAuth Token (xoxb-...): " botToken < /dev/tty
echo ""
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  How to find Team ID${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "  ${WHITE}[Slack App]${NC}"
echo -e "    ${GRAY}1. Click workspace name (top-left)${NC}"
echo -e "    ${GRAY}2. Select 'Tools & settings'${NC}"
echo -e "    ${GRAY}3. Select 'Manage apps'${NC}"
echo -e "    ${GRAY}4. Browser opens - Team ID is in URL:${NC}"
echo ""
echo -e "       ${GRAY}https://app.slack.com/client/T07XXXXXX/...${NC}"
echo -e "                                    ${YELLOW}^^^^^^^^^^${NC}"
echo ""
read -p "Team ID (starts with T): " teamId < /dev/tty

if [ -z "$botToken" ]; then
    echo -e "${RED}Bot Token is required.${NC}"
    exit 1
fi

if [ -z "$teamId" ]; then
    echo -e "${RED}Team ID is required.${NC}"
    exit 1
fi

# Update .mcp.json using Node.js
echo ""
echo -e "${YELLOW}[Config] Updating .mcp.json...${NC}"
MCP_CONFIG_PATH="$HOME/.mcp.json"

# Build env object
ENV_OBJECT="{ \"SLACK_BOT_TOKEN\": \"$botToken\""
if [ -n "$teamId" ]; then
    ENV_OBJECT="$ENV_OBJECT, \"SLACK_TEAM_ID\": \"$teamId\""
fi
ENV_OBJECT="$ENV_OBJECT }"

node -e "
const fs = require('fs');
const configPath = '$MCP_CONFIG_PATH';
let config = { mcpServers: {} };

if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};
}

config.mcpServers['slack'] = {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-slack'],
    env: $ENV_OBJECT
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
echo -e "  ${GREEN}OK${NC}"

echo ""
echo "----------------------------------------"
echo -e "${GREEN}Slack MCP installation complete!${NC}"
