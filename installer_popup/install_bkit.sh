#!/bin/bash
# bkit Plugin Installation Script (Mac/Linux)
# Usage: chmod +x install_bkit.sh && ./install_bkit.sh

echo ""
echo "========================================"
echo "  bkit Plugin Installation"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if Claude Code is installed
echo -e "${YELLOW}[1/3] Checking Claude Code...${NC}"
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Claude Code is not installed.${NC}"
    echo ""
    echo "Please run install.sh first."
    echo ""
    exit 1
fi
echo -e "${GREEN}Claude Code OK!${NC}"

# Add bkit marketplace
echo ""
echo -e "${YELLOW}[2/3] Adding bkit marketplace...${NC}"
claude plugin marketplace add popup-studio-ai/bkit-claude-code 2>/dev/null
echo -e "${GREEN}Marketplace added!${NC}"

# Install bkit plugin
echo ""
echo -e "${YELLOW}[3/3] Installing bkit plugin...${NC}"
claude plugin install bkit@bkit-marketplace
echo -e "${GREEN}bkit installed!${NC}"

# Done
echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Restart VS Code to use bkit."
echo ""
