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

# Determine available JSON parser (node first -- always available after base install)
JSON_PARSER=""
if command -v node > /dev/null 2>&1; then
  JSON_PARSER="node"
elif command -v jq > /dev/null 2>&1; then
  JSON_PARSER="jq"
elif command -v python3 > /dev/null 2>&1; then
  JSON_PARSER="python3"
fi

if [ -z "$JSON_PARSER" ]; then
  echo -e "${RED}No JSON parser available (need node, jq, or python3)${NC}"
  exit 1
fi

echo "Using JSON parser: $JSON_PARSER"
echo ""

# Helper: parse a JSON field using the detected parser
# Usage: parse_field "$file" "fieldName"
parse_field() {
  local file="$1"
  local field="$2"

  case "$JSON_PARSER" in
    node)
      node -e "
        const fs = require('fs');
        try {
          const d = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
          const v = d[process.argv[2]];
          process.stdout.write(v === undefined || v === null ? '' : String(v));
        } catch(e) { process.stdout.write(''); }
      " "$file" "$field" 2>/dev/null
      ;;
    jq)
      jq -r ".$field // empty" "$file" 2>/dev/null
      ;;
    python3)
      python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    v = d.get(sys.argv[2], '')
    print(v if v else '', end='')
except: print('', end='')
" "$file" "$field" 2>/dev/null
      ;;
  esac
}

# Helper: validate JSON syntax
validate_json() {
  local file="$1"

  case "$JSON_PARSER" in
    node)
      node -e "
        const fs = require('fs');
        JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
      " "$file" 2>/dev/null
      ;;
    jq)
      jq empty "$file" 2>/dev/null
      ;;
    python3)
      python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$file" 2>/dev/null
      ;;
  esac
}

for module_json in $MODULE_JSONS; do
  module_name=$(basename "$(dirname "$module_json")")
  echo "----------------------------------------"
  echo "Testing: $module_name/module.json"
  echo "----------------------------------------"

  # Test 1: Valid JSON syntax
  if validate_json "$module_json"; then
    assert_equals "true" "true" "$module_name: Valid JSON syntax"
  else
    assert_equals "true" "false" "$module_name: Valid JSON syntax"
    continue
  fi

  # Test 2: Required fields
  required_fields=("name" "displayName" "description" "version" "type" "order")

  for field in "${required_fields[@]}"; do
    value=$(parse_field "$module_json" "$field")
    if [ -n "$value" ]; then
      assert_equals "true" "true" "$module_name: Has required field '$field'"
    else
      assert_equals "true" "false" "$module_name: Has required field '$field'"
    fi
  done

  # Test 3: Type validation
  type=$(parse_field "$module_json" "type")
  if [[ "$type" == "cli" || "$type" == "mcp" || "$type" == "remote-mcp" || "$type" == "plugin" || "$type" == "extension" ]]; then
    assert_equals "true" "true" "$module_name: Valid type value"
  else
    assert_equals "true" "false" "$module_name: Valid type value (got: $type)"
  fi

  # Test 4: Complexity validation
  complexity=$(parse_field "$module_json" "complexity")
  if [[ "$complexity" == "simple" || "$complexity" == "moderate" || "$complexity" == "complex" ]]; then
    assert_equals "true" "true" "$module_name: Valid complexity value"
  else
    assert_equals "true" "false" "$module_name: Valid complexity value (got: $complexity)"
  fi

  # Test 5: MCP config validation (if type is mcp)
  if [ "$type" = "mcp" ]; then
    mcp_config=$(parse_field "$module_json" "mcpConfig")
    if [ -n "$mcp_config" ] && [ "$mcp_config" != "null" ]; then
      assert_equals "true" "true" "$module_name: MCP module has mcpConfig"
    else
      assert_equals "true" "false" "$module_name: MCP module has mcpConfig"
    fi
  fi

  echo ""
done

print_summary
