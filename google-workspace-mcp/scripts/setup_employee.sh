#!/bin/bash
# Google Workspace MCP - Employee Setup Script (Mac/Linux)
# Usage: chmod +x setup_employee.sh && ./setup_employee.sh

echo ""
echo "========================================"
echo "  Google Workspace MCP Setup"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Docker check
echo -e "${YELLOW}[1/5] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed.${NC}"
    echo ""
    echo "Please install Docker Desktop first:"
    echo -e "${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
    echo ""
    read -p "Press Enter after installation..."
fi

# Docker Desktop running check
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker Desktop is not running.${NC}"
    echo "Please start Docker Desktop."
    echo ""
    read -p "Press Enter after starting Docker..."
fi
echo -e "${GREEN}Docker OK!${NC}"

# 2. Create folder
echo ""
echo -e "${YELLOW}[2/5] Creating config folder...${NC}"
CONFIG_DIR="$HOME/.google-workspace"
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo -e "${GREEN}Folder created: $CONFIG_DIR${NC}"
else
    echo -e "${GREEN}Folder exists: $CONFIG_DIR${NC}"
fi

# 3. client_secret.json check
echo ""
echo -e "${YELLOW}[3/5] Checking client_secret.json...${NC}"
CLIENT_SECRET_PATH="$CONFIG_DIR/client_secret.json"

if [ ! -f "$CLIENT_SECRET_PATH" ]; then
    echo ""
    echo "client_secret.json file is required."
    echo "Copy the file from admin to this folder:"
    echo ""
    echo -e "  ${CYAN}$CLIENT_SECRET_PATH${NC}"
    echo ""

    # Open Finder (Mac)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$CONFIG_DIR"
    fi

    read -p "Copy the file and press Enter..."

    if [ ! -f "$CLIENT_SECRET_PATH" ]; then
        echo -e "${RED}client_secret.json not found. Please try again.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}client_secret.json OK!${NC}"

# 4. Docker image check
echo ""
echo -e "${YELLOW}[4/5] Checking Docker image...${NC}"
IMAGE_EXISTS=$(docker images -q google-workspace-mcp 2>/dev/null)

if [ -z "$IMAGE_EXISTS" ]; then
    echo "Docker image not found."
    echo ""
    echo "Select option:"
    echo "  1. Load from file (google-workspace-mcp.tar)"
    echo "  2. Build from source"
    echo "  3. Skip (setup later)"
    echo ""
    read -p "Select (1/2/3): " CHOICE

    case $CHOICE in
        1)
            read -p "Enter tar file path (drag and drop): " TAR_FILE
            TAR_FILE=$(echo "$TAR_FILE" | tr -d "'\"")
            if [ -f "$TAR_FILE" ]; then
                echo -e "${YELLOW}Loading image...${NC}"
                docker load -i "$TAR_FILE"
                echo -e "${GREEN}Image loaded!${NC}"
            else
                echo -e "${RED}File not found: $TAR_FILE${NC}"
            fi
            ;;
        2)
            read -p "Enter source folder path: " SOURCE_DIR
            if [ -f "$SOURCE_DIR/Dockerfile" ]; then
                echo -e "${YELLOW}Building image... (may take a few minutes)${NC}"
                cd "$SOURCE_DIR"
                docker build -t google-workspace-mcp .
                cd -
                echo -e "${GREEN}Image built!${NC}"
            else
                echo -e "${RED}Dockerfile not found: $SOURCE_DIR${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Skipped. Please setup Docker image later.${NC}"
            ;;
    esac
else
    echo -e "${GREEN}Docker image OK!${NC}"
fi

# 5. Create .mcp.json
echo ""
echo -e "${YELLOW}[5/5] Creating Claude config...${NC}"

MCP_CONFIG='{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "'$CONFIG_DIR':/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}'

# Global config (home folder)
GLOBAL_MCP_PATH="$HOME/.mcp.json"
echo "$MCP_CONFIG" > "$GLOBAL_MCP_PATH"
echo -e "${GREEN}Config saved: $GLOBAL_MCP_PATH${NC}"

# Done
echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Restart VS Code"
echo "  2. Ask Claude: 'Show my calendar'"
echo "  3. Login with your company account"
echo ""
echo -e "${YELLOW}Contact IT team if you have problems.${NC}"
echo ""
