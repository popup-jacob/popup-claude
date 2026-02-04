#!/bin/bash
# ============================================
# Figma Module - MCP Server Installation
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Figma MCP Server Setup${NC}"
echo -e "${CYAN}----------------------${NC}"
echo ""

# ============================================
# 1. Get Figma Personal Access Token
# ============================================
echo -e "${YELLOW}Figma Personal Access Token is required.${NC}"
echo ""
echo -e "${WHITE}How to get your token:${NC}"
echo -e "  ${GRAY}1. Go to https://www.figma.com/developers/api#access-tokens${NC}"
echo -e "  ${GRAY}2. Click 'Get personal access token'${NC}"
echo -e "  ${GRAY}3. Copy the generated token${NC}"
echo ""

read -p "Enter your Figma Personal Access Token: " ACCESS_TOKEN < /dev/tty

if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${YELLOW}No token provided. Skipping Figma setup.${NC}"
    exit 0
fi

# ============================================
# 2. Update .mcp.json
# ============================================
echo ""
echo -e "${YELLOW}Configuring MCP...${NC}"

MCP_CONFIG="$HOME/.mcp.json"

# Create or update config using Node.js for proper JSON handling
node -e "
const fs = require('fs');
const configPath = '$MCP_CONFIG';

let config = { mcpServers: {} };
if (fs.existsSync(configPath)) {
    try {
        config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    } catch (e) {
        config = { mcpServers: {} };
    }
}

if (!config.mcpServers) {
    config.mcpServers = {};
}

config.mcpServers.figma = {
    command: 'npx',
    args: ['-y', '@anthropic/mcp-figma'],
    env: {
        FIGMA_PERSONAL_ACCESS_TOKEN: '$ACCESS_TOKEN'
    }
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log('  OK - Figma MCP configured');
"

echo -e "  ${GREEN}OK - Figma MCP configured${NC}"
echo ""
echo -e "${WHITE}You can now use Claude to:${NC}"
echo -e "  ${GRAY}- Read Figma file contents${NC}"
echo -e "  ${GRAY}- Inspect design components${NC}"
echo -e "  ${GRAY}- Extract design tokens and styles${NC}"
echo ""
