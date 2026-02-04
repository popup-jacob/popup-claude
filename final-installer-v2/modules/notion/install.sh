#!/bin/bash
# ============================================
# Notion MCP Module (Mac/Linux)
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo "Notion MCP lets Claude access:"
echo -e "  ${GRAY}- Read Notion pages${NC}"
echo -e "  ${GRAY}- Search databases${NC}"
echo -e "  ${GRAY}- Query content${NC}"
echo ""

# Check Node.js
echo -e "${YELLOW}[Check] Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "  ${RED}Node.js is required. Please install base module first.${NC}"
    exit 1
fi
echo -e "  ${GREEN}OK${NC}"

# Guide for Integration Token
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Notion Integration Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "You need a Notion Integration Token. Follow these steps:"
echo ""
echo -e "  ${GRAY}1. Go to https://www.notion.so/my-integrations${NC}"
echo -e "  ${GRAY}2. Click '+ New integration'${NC}"
echo -e "  ${YELLOW}3. Select 'Internal' type (not Public)${NC}"
echo -e "  ${GRAY}4. Give it a name, select your workspace${NC}"
echo -e "  ${GRAY}5. Click 'Submit'${NC}"
echo -e "  ${GRAY}6. Copy the 'Internal Integration Secret' (secret_...)${NC}"
echo ""
echo -e "  ${YELLOW}IMPORTANT: Connect pages to your integration!${NC}"
echo -e "  ${GRAY}After setup, for each page you want Claude to access:${NC}"
echo -e "    ${GRAY}1. Open the Notion page${NC}"
echo -e "    ${GRAY}2. Click '...' (top-right)${NC}"
echo -e "    ${GRAY}3. Click 'Connections'${NC}"
echo -e "    ${GRAY}4. Select your integration name${NC}"
echo ""

read -p "Open Notion Integrations page in browser? (y/n): " openPage < /dev/tty
if [ "$openPage" = "y" ] || [ "$openPage" = "Y" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "https://www.notion.so/my-integrations"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://www.notion.so/my-integrations"
    fi
    echo -e "${YELLOW}Create your integration and copy the token.${NC}"
    read -p "Press Enter when ready" < /dev/tty
fi

echo ""
read -p "Integration Token (secret_...): " apiToken < /dev/tty

if [ -z "$apiToken" ]; then
    echo -e "${RED}Integration Token is required.${NC}"
    exit 1
fi

# Update .mcp.json using Node.js
echo ""
echo -e "${YELLOW}[Config] Updating .mcp.json...${NC}"
MCP_CONFIG_PATH="$HOME/.mcp.json"

node -e "
const fs = require('fs');
const configPath = '$MCP_CONFIG_PATH';
let config = { mcpServers: {} };

if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};
}

config.mcpServers['notion'] = {
    command: 'npx',
    args: ['-y', '@notionhq/notion-mcp-server'],
    env: {
        NOTION_TOKEN: '$apiToken'
    }
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
echo -e "  ${GREEN}OK${NC}"

echo ""
echo "----------------------------------------"
echo -e "${GREEN}Notion MCP installation complete!${NC}"
echo ""
echo -e "${YELLOW}Remember to share pages with your integration!${NC}"
