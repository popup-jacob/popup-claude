#!/bin/bash
# ============================================
# Atlassian (Jira + Confluence) MCP Module (Mac/Linux)
# ============================================
# Auto-detects Docker and recommends best option

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo "Atlassian MCP lets Claude access:"
echo -e "  ${GRAY}- Jira (view issues, create tasks)${NC}"
echo -e "  ${GRAY}- Confluence (search, read pages)${NC}"
echo ""

# ============================================
# Auto-detect Docker
# ============================================
HAS_DOCKER=false
DOCKER_RUNNING=false
if command -v docker > /dev/null 2>&1; then
    HAS_DOCKER=true
    if docker info > /dev/null 2>&1; then
        DOCKER_RUNNING=true
    fi
fi

# ============================================
# Show options based on Docker status
# ============================================
echo "========================================"
if [ "$HAS_DOCKER" = true ]; then
    echo -e "${GREEN}  Docker is installed!${NC}"
    echo "========================================"
    echo ""
    echo "Select installation method:"
    echo -e "  ${GREEN}1. Local install (Recommended) - Uses Docker, runs on your machine${NC}"
    echo "  2. Simple install - Browser login only"
else
    echo -e "${YELLOW}  Docker is not installed.${NC}"
    echo "========================================"
    echo ""
    echo "Select installation method:"
    echo -e "  ${GREEN}1. Simple install (Recommended) - Browser login only, no extra install${NC}"
    echo "  2. Local install - Requires Docker"
fi
echo ""
read -p "Select (1/2): " choice < /dev/tty

# Determine which mode based on Docker status and choice
USE_DOCKER=false
if [ "$HAS_DOCKER" = true ]; then
    # Docker 있음: 1=Docker, 2=Rovo
    if [ "$choice" != "2" ]; then
        USE_DOCKER=true
    fi
else
    # Docker 없음: 1=Rovo, 2=Docker
    if [ "$choice" = "2" ]; then
        USE_DOCKER=true
    fi
fi

# ============================================
# Execute selected mode
# ============================================
if [ "$USE_DOCKER" = true ]; then
    # ========================================
    # MCP-ATLASSIAN (Docker)
    # ========================================

    # Check Docker is available
    if [ "$HAS_DOCKER" = false ]; then
        echo ""
        echo -e "${RED}Docker is not installed!${NC}"
        echo "Please install Docker Desktop first:"
        echo -e "  ${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
        echo ""
        exit 1
    fi

    # Check Docker is running
    if [ "$DOCKER_RUNNING" = false ]; then
        echo ""
        echo -e "${YELLOW}Docker is not running!${NC}"
        echo "Please start Docker Desktop."
        echo ""
        read -p "Press Enter after starting Docker (q to cancel): " waitDocker < /dev/tty
        if [ "$waitDocker" = "q" ]; then
            echo "Cancelled."
            exit 1
        fi

        if ! docker info > /dev/null 2>&1; then
            echo -e "${RED}Docker is still not running.${NC}"
            exit 1
        fi
    fi
    echo ""
    echo -e "${GREEN}[OK] Docker check complete${NC}"

    echo ""
    echo -e "${YELLOW}Setting up mcp-atlassian (Docker)...${NC}"
    echo ""
    echo "API token required. Create one here:"
    echo -e "  ${CYAN}https://id.atlassian.com/manage-profile/security/api-tokens${NC}"
    echo ""

    read -p "Open API token page in browser? (y/n): " openToken < /dev/tty
    if [ "$openToken" = "y" ] || [ "$openToken" = "Y" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "https://id.atlassian.com/manage-profile/security/api-tokens"
        elif command -v xdg-open > /dev/null 2>&1; then
            xdg-open "https://id.atlassian.com/manage-profile/security/api-tokens"
        fi
        echo -e "${YELLOW}Create and copy the token.${NC}"
        read -p "Press Enter when ready: " < /dev/tty
    fi

    echo ""
    read -p "Atlassian URL (e.g., https://company.atlassian.net): " atlassianUrl < /dev/tty
    atlassianUrl="${atlassianUrl%/}"
    jiraUrl="$atlassianUrl"
    confluenceUrl="$atlassianUrl/wiki"

    echo -e "  ${GRAY}Jira: $jiraUrl${NC}"
    echo -e "  ${GRAY}Confluence: $confluenceUrl${NC}"
    echo ""
    read -p "Email: " email < /dev/tty
    read -p "API Token: " apiToken < /dev/tty

    # Pull Docker image
    echo ""
    echo -e "${YELLOW}[Pull] Downloading mcp-atlassian Docker image...${NC}"
    docker pull ghcr.io/sooperset/mcp-atlassian:latest 2>/dev/null
    echo -e "  ${GREEN}OK${NC}"

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

config.mcpServers['atlassian'] = {
    command: 'docker',
    args: [
        'run', '-i', '--rm',
        '-e', 'CONFLUENCE_URL=$confluenceUrl',
        '-e', 'CONFLUENCE_USERNAME=$email',
        '-e', 'CONFLUENCE_API_TOKEN=$apiToken',
        '-e', 'JIRA_URL=$jiraUrl',
        '-e', 'JIRA_USERNAME=$email',
        '-e', 'JIRA_API_TOKEN=$apiToken',
        'ghcr.io/sooperset/mcp-atlassian:latest'
    ]
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
"
    echo -e "  ${GREEN}OK${NC}"

else
    # ========================================
    # ROVO MCP (Official Atlassian SSE)
    # ========================================
    echo ""
    echo -e "${YELLOW}Setting up Atlassian Rovo MCP...${NC}"
    echo ""
    echo "A browser will open for Atlassian login."
    echo "Please login and authorize the access."
    echo ""

    claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse

    echo ""
    echo -e "  ${GREEN}Rovo MCP setup complete!${NC}"
    echo ""
    echo -e "${GRAY}Guide: https://support.atlassian.com/atlassian-rovo-mcp-server/${NC}"
fi

echo ""
echo "----------------------------------------"
echo -e "${GREEN}Atlassian MCP installation complete!${NC}"
