#!/bin/bash
# ============================================
# Module Ordering Validation Test
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

echo "Testing module installation order..."
echo ""

# Check for JSON parser
if ! command -v jq > /dev/null 2>&1; then
  echo -e "${RED}jq is required for this test${NC}"
  echo "Please install jq: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

# Collect all module orders
declare -A module_orders
declare -A module_required
declare -a all_modules

MODULE_JSONS=$(find "$SCRIPT_DIR/../modules" -name "module.json" 2>/dev/null)

for module_json in $MODULE_JSONS; do
  module_name=$(jq -r '.name' "$module_json")
  order=$(jq -r '.order' "$module_json")
  required=$(jq -r '.required' "$module_json")

  module_orders[$module_name]=$order
  module_required[$module_name]=$required
  all_modules+=("$module_name")
done

echo "Found ${#all_modules[@]} modules"
echo ""

# Test 1: base module should be order 0
echo "----------------------------------------"
echo "Test 1: Base Module Order"
echo "----------------------------------------"

if [ -n "${module_orders[base]}" ]; then
  assert_equals "0" "${module_orders[base]}" "base module has order 0"
else
  assert_equals "true" "false" "base module exists"
fi

echo ""

# Test 2: Required modules should have lower order than optional
echo "----------------------------------------"
echo "Test 2: Required Module Ordering"
echo "----------------------------------------"

for module in "${all_modules[@]}"; do
  required=${module_required[$module]}
  order=${module_orders[$module]}

  if [ "$required" = "true" ] && [ "$module" != "base" ]; then
    if [ "$order" -lt 5 ]; then
      assert_equals "true" "true" "$module: Required module has low order ($order < 5)"
    else
      assert_equals "true" "false" "$module: Required module should have order < 5 (got: $order)"
    fi
  fi
done

echo ""

# Test 3: No duplicate orders
echo "----------------------------------------"
echo "Test 3: Unique Order Values"
echo "----------------------------------------"

sorted_orders=$(printf '%s\n' "${module_orders[@]}" | sort -n)
unique_orders=$(printf '%s\n' "${module_orders[@]}" | sort -n | uniq)

if [ "$sorted_orders" = "$unique_orders" ]; then
  assert_equals "true" "true" "All modules have unique order values"
else
  assert_equals "true" "false" "All modules have unique order values"

  # Find duplicates
  duplicate_orders=$(printf '%s\n' "${module_orders[@]}" | sort -n | uniq -d)
  echo -e "  ${GRAY}Duplicate orders found: $duplicate_orders${NC}"
fi

echo ""

# Test 4: Order values are sequential
echo "----------------------------------------"
echo "Test 4: Sequential Order Values"
echo "----------------------------------------"

expected_max=$((${#all_modules[@]} - 1))
actual_max=$(printf '%s\n' "${module_orders[@]}" | sort -n | tail -1)

if [ "$actual_max" -le "$expected_max" ]; then
  assert_equals "true" "true" "Order values are reasonable (max: $actual_max <= $expected_max)"
else
  assert_equals "true" "false" "Order values should be sequential (max: $actual_max > $expected_max)"
fi

echo ""

# Test 5: Display order table
echo "----------------------------------------"
echo "Module Order Table"
echo "----------------------------------------"
echo "Order | Module       | Required"
echo "------|--------------|----------"

for module in "${all_modules[@]}"; do
  order=${module_orders[$module]}
  required=${module_required[$module]}
  printf "%-5s | %-12s | %s\n" "$order" "$module" "$required"
done | sort -n

echo ""

print_summary
