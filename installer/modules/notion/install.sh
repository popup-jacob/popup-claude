#!/bin/bash
# ============================================
# Notion MCP Module (Mac/Linux) — Remote MCP + Auto OAuth
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

# Check Claude CLI
echo -e "${YELLOW}[Check] Claude CLI...${NC}"
if ! command -v claude > /dev/null 2>&1; then
    echo -e "  ${RED}Claude CLI is required. Please install base module first.${NC}"
    exit 1
fi
echo -e "  ${GREEN}OK${NC}"

# Check python3 (required for OAuth)
echo -e "${YELLOW}[Check] Python 3...${NC}"
if ! command -v python3 > /dev/null 2>&1; then
    echo -e "  ${RED}Python 3 is required for OAuth authentication.${NC}"
    echo -e "  ${YELLOW}Install with: brew install python3 (Mac) or apt install python3 (Linux)${NC}"
    exit 1
fi
echo -e "  ${GREEN}OK${NC}"

# Register Remote MCP server
echo ""
echo -e "${YELLOW}[Config] Registering Notion Remote MCP server...${NC}"
claude mcp add --transport http notion https://mcp.notion.com/mcp
echo -e "  ${GREEN}OK${NC}"

# Auto OAuth authentication
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Notion OAuth Login${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Starting automatic OAuth authentication..."
echo ""

# Load OAuth helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/oauth-helper.sh"

mcp_oauth_flow "notion" "https://mcp.notion.com/mcp"
oauth_result=$?

echo ""
echo "----------------------------------------"
if [ $oauth_result -eq 0 ]; then
    echo -e "${GREEN}Notion MCP setup complete! Ready to use.${NC}"
else
    echo -e "${YELLOW}Notion MCP registered but OAuth login failed.${NC}"
    echo -e "${YELLOW}You can retry by running this installer again,${NC}"
    echo -e "${YELLOW}or manually authenticate via /mcp in Claude Code.${NC}"
fi
echo ""
