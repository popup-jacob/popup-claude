#!/bin/bash
# ============================================
# Shared Docker Utilities
# FR-S3-05a: Eliminate 4x duplicate Docker checks
# FR-S2-11: Docker Desktop version compatibility check
# ============================================

# Source colors if not already loaded
if [ -z "$NC" ]; then
    SCRIPT_DIR_DOCKER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SHARED_DIR:-$SCRIPT_DIR_DOCKER}/colors.sh"
fi

# Check if Docker is installed
docker_is_installed() {
    command -v docker > /dev/null 2>&1
}

# Check if Docker daemon is running
docker_is_running() {
    docker info > /dev/null 2>&1
}

# Get Docker status as string
docker_get_status() {
    if ! docker_is_installed; then
        echo "not_installed"
    elif ! docker_is_running; then
        echo "not_running"
    else
        echo "running"
    fi
}

# Full Docker check with user prompts
# Returns 0 if Docker is ready, 1 otherwise
docker_check() {
    local status
    status=$(docker_get_status)

    case "$status" in
        "running")
            echo -e "  ${GREEN}[OK] Docker is running${NC}"
            docker_check_compatibility
            return 0
            ;;
        "not_running")
            echo -e "  ${YELLOW}Docker is not running!${NC}"
            echo "  Please start Docker Desktop."
            echo ""
            read -p "  Press Enter after starting Docker (q to cancel): " waitDocker < /dev/tty
            if [ "$waitDocker" = "q" ]; then
                return 1
            fi
            if docker_is_running; then
                echo -e "  ${GREEN}[OK] Docker is now running${NC}"
                docker_check_compatibility
                return 0
            else
                echo -e "  ${RED}Docker is still not running.${NC}"
                return 1
            fi
            ;;
        "not_installed")
            echo -e "  ${RED}Docker is not installed!${NC}"
            docker_show_install_guide
            return 1
            ;;
    esac
}

# Wait for Docker to start with timeout
docker_wait_for_start() {
    local timeout="${1:-60}"
    local elapsed=0
    while [ $elapsed -lt "$timeout" ]; do
        if docker_is_running; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    return 1
}

# Install Docker Desktop (platform-specific)
docker_install() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew > /dev/null 2>&1; then
            echo -e "  ${YELLOW}Installing Docker Desktop via Homebrew...${NC}"
            brew install --cask docker
        else
            echo -e "  ${YELLOW}Please install Docker Desktop from:${NC}"
            echo -e "  ${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
        fi
    else
        echo -e "  ${YELLOW}Installing Docker via official script...${NC}"
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$USER" 2>/dev/null || true
    fi
}

# Pull Docker image with status
docker_pull_image() {
    local image_name="$1"
    echo -e "  ${YELLOW}Pulling Docker image: $image_name${NC}"
    docker pull "$image_name" 2>/dev/null
    echo -e "  ${GREEN}OK${NC}"
}

# Cleanup container by image name
docker_cleanup_container() {
    local image_name="$1"
    local container_id
    container_id=$(docker ps -q --filter "ancestor=$image_name" 2>/dev/null)
    if [ -n "$container_id" ]; then
        docker stop "$container_id" > /dev/null 2>&1
        docker rm "$container_id" > /dev/null 2>&1
    fi
}

# Show Docker install guide
docker_show_install_guide() {
    echo ""
    echo "  Please install Docker Desktop:"
    echo -e "  ${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
    echo ""
}

# FR-S2-11: Docker Desktop version compatibility check
docker_check_compatibility() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 0
    fi

    local docker_version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "")

    if [ -z "$docker_version" ]; then
        return 0
    fi

    local os_version
    os_version=$(sw_vers -productVersion 2>/dev/null || echo "")
    local major_version="${os_version%%.*}"

    # Docker Desktop 4.42+ requires macOS Sonoma (14.x) or later
    if [[ "$docker_version" > "4.42" ]] && [[ "$major_version" -lt 14 ]]; then
        echo -e "  ${YELLOW}Warning: Docker Desktop $docker_version may not support macOS $os_version${NC}"
        echo -e "  ${YELLOW}Consider using Docker Desktop 4.41 or earlier for macOS Ventura${NC}"
        return 1
    fi

    return 0
}
