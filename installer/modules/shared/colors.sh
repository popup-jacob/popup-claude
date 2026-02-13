#!/bin/bash
# ============================================
# Shared Color Definitions & Print Utilities
# FR-S3-05a: Eliminate 7-module color duplication
# ============================================

# ANSI color codes (8 base colors)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Semantic color aliases
COLOR_SUCCESS="$GREEN"
COLOR_ERROR="$RED"
COLOR_WARNING="$YELLOW"
COLOR_INFO="$CYAN"
COLOR_DEBUG="$GRAY"

# Print convenience functions
print_success() { echo -e "  ${COLOR_SUCCESS}$*${NC}"; }
print_error()   { echo -e "  ${COLOR_ERROR}$*${NC}"; }
print_warning() { echo -e "  ${COLOR_WARNING}$*${NC}"; }
print_info()    { echo -e "  ${COLOR_INFO}$*${NC}"; }
print_debug()   { echo -e "  ${COLOR_DEBUG}$*${NC}"; }
