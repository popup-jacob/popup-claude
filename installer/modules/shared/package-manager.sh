#!/bin/bash
# ============================================
# Shared Package Manager Utilities
# FR-S3-05a + FR-S2-04: Multi-platform package manager abstraction
# Supports: brew, apt, dnf, yum, pacman
# ============================================

# Source colors if not already loaded
if [ -z "$NC" ]; then
    SCRIPT_DIR_PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SHARED_DIR:-$SCRIPT_DIR_PKG}/colors.sh"
fi

# Detect available package manager
pkg_detect_manager() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command -v brew > /dev/null 2>&1 && echo "brew" || echo "none"
    elif command -v apt > /dev/null 2>&1; then
        echo "apt"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v yum > /dev/null 2>&1; then
        echo "yum"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    else
        echo "none"
    fi
}

# Install a package using detected manager
pkg_install() {
    local package_name="$1"
    local manager
    manager=$(pkg_detect_manager)

    case "$manager" in
        brew)   brew install "$package_name" ;;
        apt)    sudo apt-get update -qq && sudo apt-get install -y "$package_name" ;;
        dnf)    sudo dnf install -y "$package_name" ;;
        yum)    sudo yum install -y "$package_name" ;;
        pacman) sudo pacman -S --noconfirm "$package_name" ;;
        none)
            echo -e "  ${RED}No supported package manager detected.${NC}"
            echo -e "  ${YELLOW}Please install '$package_name' manually.${NC}"
            return 1
            ;;
    esac
}

# Install a cask package (macOS Homebrew only, falls back to pkg_install)
pkg_install_cask() {
    local package_name="$1"
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew > /dev/null 2>&1; then
        brew install --cask "$package_name"
    else
        pkg_install "$package_name"
    fi
}

# Check if a command is available
pkg_is_installed() {
    local cmd_name="$1"
    command -v "$cmd_name" > /dev/null 2>&1
}

# Ensure a package is installed, install if missing
pkg_ensure_installed() {
    local cmd_name="$1"
    local package_name="${2:-$cmd_name}"
    local description="${3:-$package_name}"

    if pkg_is_installed "$cmd_name"; then
        echo -e "  ${GREEN}$description is already installed${NC}"
    else
        echo -e "  ${YELLOW}Installing $description...${NC}"
        pkg_install "$package_name"
    fi
}
