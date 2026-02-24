#!/bin/bash
# ============================================
# Figma Module — Remote MCP Server + Auto OAuth
# ============================================

# FR-S3-05a: Source shared color definitions instead of inline
SHARED_DIR="${SHARED_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../shared" 2>/dev/null && pwd)}"
if [ -n "$SHARED_DIR" ] && [ -f "$SHARED_DIR/colors.sh" ]; then
    source "$SHARED_DIR/colors.sh"
else
    # Fallback for remote execution
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'
fi

echo ""
echo -e "${CYAN}Figma MCP Server Setup${NC}"
echo -e "${CYAN}----------------------${NC}"
echo ""
echo "Figma MCP lets Claude access:"
echo -e "  ${GRAY}- Read Figma file contents${NC}"
echo -e "  ${GRAY}- Inspect design components${NC}"
echo -e "  ${GRAY}- Extract design tokens and styles${NC}"
echo ""

# Check AI CLI
CLI_CMD="${CLI_TYPE:-claude}"
echo -e "${YELLOW}[Check] $CLI_CMD CLI...${NC}"
if ! command -v "$CLI_CMD" > /dev/null 2>&1; then
    echo -e "  ${RED}$CLI_CMD CLI is required. Please install base module first.${NC}"
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
echo -e "${YELLOW}[Config] Registering Figma Remote MCP server...${NC}"
$CLI_CMD mcp add --transport http figma https://mcp.figma.com/mcp
echo -e "  ${GREEN}OK${NC}"

# Auto OAuth authentication
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Figma OAuth Login${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Starting automatic OAuth authentication..."
echo ""

# Load OAuth helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/oauth-helper.sh"

mcp_oauth_flow "figma" "https://mcp.figma.com/mcp"
oauth_result=$?

echo ""
echo "----------------------------------------"
if [ $oauth_result -eq 0 ]; then
    echo -e "${GREEN}Figma MCP setup complete! Ready to use.${NC}"
else
    echo -e "${YELLOW}Figma MCP registered but OAuth login failed.${NC}"
    echo -e "${YELLOW}You can retry by running this installer again,${NC}"
    echo -e "${YELLOW}or manually authenticate via /mcp in Claude Code.${NC}"
fi
echo ""
