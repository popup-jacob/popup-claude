#!/bin/bash
# ============================================
# Module JSON Validation Test
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

echo "Testing module.json files..."
echo ""

# Find all module.json files
MODULE_JSONS=$(find "$SCRIPT_DIR/../modules" -name "module.json" 2>/dev/null)

if [ -z "$MODULE_JSONS" ]; then
  echo -e "${RED}No module.json files found${NC}"
  exit 1
fi

for module_json in $MODULE_JSONS; do
  module_name=$(basename $(dirname "$module_json"))
  echo "----------------------------------------"
  echo "Testing: $module_name/module.json"
  echo "----------------------------------------"

  # Test 1: Valid JSON syntax
  if command -v jq > /dev/null 2>&1; then
    if jq empty "$module_json" 2>/dev/null; then
      assert_equals "true" "true" "$module_name: Valid JSON syntax"
    else
      assert_equals "true" "false" "$module_name: Valid JSON syntax"
      continue
    fi
  elif command -v python3 > /dev/null 2>&1; then
    if python3 -c "import json; json.load(open('$module_json'))" 2>/dev/null; then
      assert_equals "true" "true" "$module_name: Valid JSON syntax"
    else
      assert_equals "true" "false" "$module_name: Valid JSON syntax"
      continue
    fi
  elif command -v node > /dev/null 2>&1; then
    if node -e "require('$module_json')" 2>/dev/null; then
      assert_equals "true" "true" "$module_name: Valid JSON syntax"
    else
      assert_equals "true" "false" "$module_name: Valid JSON syntax"
      continue
    fi
  else
    skip_test "$module_name: Valid JSON syntax (no JSON parser available)"
    continue
  fi

  # Test 2: Required fields
  required_fields=("name" "displayName" "description" "version" "type" "order")

  if command -v jq > /dev/null 2>&1; then
    for field in "${required_fields[@]}"; do
      value=$(jq -r ".$field // empty" "$module_json")
      if [ -n "$value" ] && [ "$value" != "null" ]; then
        assert_equals "true" "true" "$module_name: Has required field '$field'"
      else
        assert_equals "true" "false" "$module_name: Has required field '$field'"
      fi
    done
  else
    skip_test "$module_name: Required fields check (jq not available)"
  fi

  # Test 3: Type validation
  if command -v jq > /dev/null 2>&1; then
    type=$(jq -r '.type' "$module_json")
    if [[ "$type" == "cli" || "$type" == "mcp" || "$type" == "plugin" ]]; then
      assert_equals "true" "true" "$module_name: Valid type value"
    else
      assert_equals "true" "false" "$module_name: Valid type value (got: $type)"
    fi
  fi

  # Test 4: Complexity validation
  if command -v jq > /dev/null 2>&1; then
    complexity=$(jq -r '.complexity' "$module_json")
    if [[ "$complexity" == "simple" || "$complexity" == "moderate" || "$complexity" == "complex" ]]; then
      assert_equals "true" "true" "$module_name: Valid complexity value"
    else
      assert_equals "true" "false" "$module_name: Valid complexity value (got: $complexity)"
    fi
  fi

  # Test 5: MCP config validation (if type is mcp)
  if command -v jq > /dev/null 2>&1; then
    type=$(jq -r '.type' "$module_json")
    if [ "$type" = "mcp" ]; then
      mcp_config=$(jq -r '.mcpConfig' "$module_json")
      if [ "$mcp_config" != "null" ] && [ -n "$mcp_config" ]; then
        assert_equals "true" "true" "$module_name: MCP module has mcpConfig"
      else
        assert_equals "true" "false" "$module_name: MCP module has mcpConfig"
      fi
    fi
  fi

  echo ""
done

print_summary
