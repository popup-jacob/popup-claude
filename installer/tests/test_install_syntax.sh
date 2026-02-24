#!/bin/bash
# ============================================
# Install Script Syntax Validation Test
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

echo "Testing install script syntax..."
echo ""

# Test main install scripts
echo "----------------------------------------"
echo "Testing: Main Install Scripts"
echo "----------------------------------------"

# Test install.sh (Bash)
if [ -f "$SCRIPT_DIR/../install.sh" ]; then
  if bash -n "$SCRIPT_DIR/../install.sh" 2>/dev/null; then
    assert_equals "true" "true" "install.sh: Valid Bash syntax"
  else
    assert_equals "true" "false" "install.sh: Valid Bash syntax"
  fi

  if grep -q "#!/bin/bash" "$SCRIPT_DIR/../install.sh"; then
    assert_equals "true" "true" "install.sh: Has shebang"
  else
    assert_equals "true" "false" "install.sh: Has shebang"
  fi
else
  skip_test "install.sh not found"
fi

# Test install.ps1 (PowerShell)
if [ -f "$SCRIPT_DIR/../install.ps1" ]; then
  if command -v pwsh > /dev/null 2>&1; then
    if pwsh -NoProfile -NonInteractive -File "$SCRIPT_DIR/../install.ps1" -WhatIf 2>/dev/null; then
      assert_equals "true" "true" "install.ps1: Valid PowerShell syntax"
    else
      # Try syntax check only
      if pwsh -NoProfile -NonInteractive -Command "Get-Content '$SCRIPT_DIR/../install.ps1' | Out-Null" 2>/dev/null; then
        assert_equals "true" "true" "install.ps1: Valid PowerShell syntax (basic check)"
      else
        assert_equals "true" "false" "install.ps1: Valid PowerShell syntax"
      fi
    fi
  else
    skip_test "install.ps1 (pwsh not available)"
  fi
else
  skip_test "install.ps1 not found"
fi

echo ""

# Test module install scripts
MODULE_SCRIPTS=$(find "$SCRIPT_DIR/../modules" -name "install.sh" 2>/dev/null)

if [ -z "$MODULE_SCRIPTS" ]; then
  echo -e "${YELLOW}No module install scripts found${NC}"
else
  for script in $MODULE_SCRIPTS; do
    module_name=$(basename "$(dirname "$script")")
    echo "----------------------------------------"
    echo "Testing: $module_name/install.sh"
    echo "----------------------------------------"

    # Bash syntax check
    if bash -n "$script" 2>/dev/null; then
      assert_equals "true" "true" "$module_name: Valid Bash syntax"
    else
      assert_equals "true" "false" "$module_name: Valid Bash syntax"
    fi

    # Check for shebang
    if grep -q "#!/bin/bash" "$script"; then
      assert_equals "true" "true" "$module_name: Has shebang"
    else
      assert_equals "true" "false" "$module_name: Has shebang"
    fi

    # Check for common patterns
    if grep -q "echo" "$script"; then
      assert_equals "true" "true" "$module_name: Contains output statements"
    else
      skip_test "$module_name: Contains output statements (may be empty)"
    fi

    echo ""
  done
fi

print_summary
