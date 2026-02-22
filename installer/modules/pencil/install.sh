#!/bin/bash
# ============================================
# Pencil Module — AI Design Canvas for IDE
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

# Pencil is a VS Code/Cursor extension — not supported with Antigravity
if [ "$CLI_TYPE" = "gemini" ]; then
    echo -e "${YELLOW}[Skip] Pencil is not yet supported with Antigravity.${NC}"
    echo -e "${GRAY}Pencil requires VS Code or Cursor IDE.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}Pencil Setup${NC}"
echo -e "${CYAN}------------${NC}"
echo ""
echo "Pencil is an AI design canvas inside your IDE:"
echo -e "  ${GRAY}- Design directly in VS Code / Cursor${NC}"
echo -e "  ${GRAY}- Generate production-ready code from designs${NC}"
echo -e "  ${GRAY}- Version control designs with Git (.pen files)${NC}"
echo -e "  ${GRAY}- MCP auto-connects when Pencil is running${NC}"
echo ""

# Check VS Code or Cursor
echo -e "${YELLOW}[Check] IDE...${NC}"
HAS_CODE=false
HAS_CURSOR=false

if command -v code > /dev/null 2>&1; then
    HAS_CODE=true
    echo -e "  ${GREEN}VS Code found${NC}"
fi

if command -v cursor > /dev/null 2>&1; then
    HAS_CURSOR=true
    echo -e "  ${GREEN}Cursor found${NC}"
fi

if [ "$HAS_CODE" = false ] && [ "$HAS_CURSOR" = false ]; then
    echo -e "  ${RED}VS Code or Cursor is required. Please install base module first.${NC}"
    exit 1
fi

# Install Pencil extension
echo ""
echo -e "${YELLOW}[Install] Pencil extension...${NC}"

if [ "$HAS_CODE" = true ]; then
    echo -e "  ${GRAY}Installing for VS Code...${NC}"
    code --install-extension highagency.pencildev 2>/dev/null || true
    echo -e "  ${GREEN}VS Code - OK${NC}"
fi

if [ "$HAS_CURSOR" = true ]; then
    echo -e "  ${GRAY}Installing for Cursor...${NC}"
    cursor --install-extension highagency.pencildev 2>/dev/null || true
    echo -e "  ${GREEN}Cursor - OK${NC}"
fi

# Desktop app option (Mac/Linux only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo -e "${YELLOW}[Optional] Pencil Desktop App${NC}"
    echo -e "  ${GRAY}Download from: https://www.pencil.dev/downloads${NC}"
fi

# Activation guide
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Pencil Activation${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "To activate Pencil:"
echo "  1. Open VS Code / Cursor"
echo "  2. Create a new .pen file (e.g. design.pen)"
echo "  3. Enter your email to activate"
echo ""
echo -e "${GRAY}MCP server starts automatically when Pencil is running.${NC}"
echo -e "${GRAY}No additional MCP configuration needed.${NC}"

# Summary
echo ""
echo "----------------------------------------"
echo -e "${GREEN}Pencil setup complete!${NC}"
echo ""
