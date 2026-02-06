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
    echo -e "${GREEN}  Docker가 설치되어 있습니다!${NC}"
    echo "========================================"
    echo ""
    echo "설치 방식을 선택하세요:"
    echo -e "  ${GREEN}1. 로컬 설치 (권장) - Docker 사용, 내 컴퓨터에서 실행${NC}"
    echo "  2. 간편 설치 - 브라우저 로그인만"
else
    echo -e "${YELLOW}  Docker가 설치되어 있지 않습니다.${NC}"
    echo "========================================"
    echo ""
    echo "설치 방식을 선택하세요:"
    echo -e "  ${GREEN}1. 간편 설치 (권장) - 브라우저 로그인만, 추가 설치 없음${NC}"
    echo "  2. 로컬 설치 - Docker 설치 필요"
fi
echo ""
read -p "선택 (1/2): " choice < /dev/tty

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
        echo -e "${RED}Docker가 설치되어 있지 않습니다!${NC}"
        echo "먼저 Docker Desktop을 설치해주세요:"
        echo -e "  ${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
        echo ""
        exit 1
    fi

    # Check Docker is running
    if [ "$DOCKER_RUNNING" = false ]; then
        echo ""
        echo -e "${YELLOW}Docker가 실행되고 있지 않습니다!${NC}"
        echo "Docker Desktop을 시작해주세요."
        echo ""
        read -p "Docker 시작 후 Enter를 누르세요 (취소: q): " waitDocker < /dev/tty
        if [ "$waitDocker" = "q" ]; then
            echo "취소되었습니다."
            exit 1
        fi

        if ! docker info > /dev/null 2>&1; then
            echo -e "${RED}Docker가 아직 실행되지 않았습니다.${NC}"
            exit 1
        fi
    fi
    echo ""
    echo -e "${GREEN}[OK] Docker 확인 완료${NC}"

    echo ""
    echo -e "${YELLOW}Setting up mcp-atlassian (Docker)...${NC}"
    echo ""
    echo "API 토큰이 필요합니다. 아래에서 생성하세요:"
    echo -e "  ${CYAN}https://id.atlassian.com/manage-profile/security/api-tokens${NC}"
    echo ""

    read -p "브라우저에서 API 토큰 페이지 열기? (y/n): " openToken < /dev/tty
    if [ "$openToken" = "y" ] || [ "$openToken" = "Y" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "https://id.atlassian.com/manage-profile/security/api-tokens"
        elif command -v xdg-open > /dev/null 2>&1; then
            xdg-open "https://id.atlassian.com/manage-profile/security/api-tokens"
        fi
        echo -e "${YELLOW}토큰을 생성하고 복사하세요.${NC}"
        read -p "준비되면 Enter: " < /dev/tty
    fi

    echo ""
    read -p "Atlassian URL (예: https://company.atlassian.net): " atlassianUrl < /dev/tty
    atlassianUrl="${atlassianUrl%/}"
    jiraUrl="$atlassianUrl"
    confluenceUrl="$atlassianUrl/wiki"

    echo -e "  ${GRAY}Jira: $jiraUrl${NC}"
    echo -e "  ${GRAY}Confluence: $confluenceUrl${NC}"
    echo ""
    read -p "이메일: " email < /dev/tty
    read -p "API 토큰: " apiToken < /dev/tty

    # Pull Docker image
    echo ""
    echo -e "${YELLOW}[Pull] mcp-atlassian Docker 이미지 다운로드...${NC}"
    docker pull ghcr.io/sooperset/mcp-atlassian:latest 2>/dev/null
    echo -e "  ${GREEN}OK${NC}"

    # Update .mcp.json using Node.js
    echo ""
    echo -e "${YELLOW}[Config] .mcp.json 업데이트...${NC}"
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
    echo "브라우저에서 Atlassian 로그인 페이지가 열립니다."
    echo "로그인하여 권한을 승인해주세요."
    echo ""

    claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse

    echo ""
    echo -e "  ${GREEN}Rovo MCP 설정 완료!${NC}"
    echo ""
    echo -e "${GRAY}가이드: https://support.atlassian.com/atlassian-rovo-mcp-server/${NC}"
fi

echo ""
echo "----------------------------------------"
echo -e "${GREEN}Atlassian MCP 설치 완료!${NC}"
