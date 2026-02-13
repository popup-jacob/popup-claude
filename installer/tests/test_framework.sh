#!/bin/bash
# ============================================
# Bash Test Framework for Installer Tests
# ============================================

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

# Assertion: Equals
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((PASS_COUNT++))
  else
    echo -e "${RED}✗ FAIL${NC}: $message"
    echo -e "  ${GRAY}Expected: $expected${NC}"
    echo -e "  ${GRAY}Actual: $actual${NC}"
    ((FAIL_COUNT++))
  fi
}

# Assertion: File Exists
assert_file_exists() {
  local filepath="$1"
  local message="$2"

  if [ -f "$filepath" ]; then
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((PASS_COUNT++))
  else
    echo -e "${RED}✗ FAIL${NC}: $message"
    echo -e "  ${GRAY}File not found: $filepath${NC}"
    ((FAIL_COUNT++))
  fi
}

# Assertion: Command Exists
assert_command_exists() {
  local command="$1"
  local message="$2"

  if command -v "$command" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((PASS_COUNT++))
  else
    echo -e "${RED}✗ FAIL${NC}: $message"
    echo -e "  ${GRAY}Command not found: $command${NC}"
    ((FAIL_COUNT++))
  fi
}

# Assertion: String Contains
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((PASS_COUNT++))
  else
    echo -e "${RED}✗ FAIL${NC}: $message"
    echo -e "  ${GRAY}Expected to contain: $needle${NC}"
    echo -e "  ${GRAY}Actual: $haystack${NC}"
    ((FAIL_COUNT++))
  fi
}

# Assertion: Not Empty
assert_not_empty() {
  local value="$1"
  local message="$2"

  if [ -n "$value" ]; then
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((PASS_COUNT++))
  else
    echo -e "${RED}✗ FAIL${NC}: $message"
    echo -e "  ${GRAY}Value was empty${NC}"
    ((FAIL_COUNT++))
  fi
}

# Skip Test
skip_test() {
  local message="$1"
  echo -e "${YELLOW}⊘ SKIP${NC}: $message"
  ((SKIP_COUNT++))
}

# Print Summary
print_summary() {
  echo ""
  echo "===================================="
  echo "Test Summary"
  echo "===================================="
  echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
  echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
  echo -e "${YELLOW}SKIP: $SKIP_COUNT${NC}"
  echo "===================================="

  if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Tests failed${NC}"
    exit 1
  else
    echo -e "${GREEN}All tests passed${NC}"
    exit 0
  fi
}
