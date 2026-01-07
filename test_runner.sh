#!/bin/bash
# Test runner for official Lua test suite

# Prefer JS backend runner (preferred-target=js). Build optional for type-check.
echo "Checking project..."
moon check > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Type check failed!"
  exit 1
fi

echo "Testing Official Lua 5.4 Test Suite"
echo "===================================="
echo ""

PASS=0
FAIL=0
SYNTAX_ERROR=0
RUNTIME_ERROR=0

for test in refs/lua/testes/*.lua; do
  name=$(basename "$test")
  printf "%-30s" "$name"

  # Run via moon runner (JS target). Increase timeout slightly for Node startup.
  output=$(timeout 4 moon run cmd -- "$test" 2>&1)
  status=$?

  if echo "$output" | grep -q "SyntaxError"; then
    echo " [SYNTAX ERROR]"
    SYNTAX_ERROR=$((SYNTAX_ERROR + 1))
    echo "  Error: $(echo "$output" | grep "SyntaxError" | head -1)"
  elif echo "$output" | grep -q "RuntimeError\|Error executing\|Error reading"; then
    echo " [RUNTIME ERROR]"
    RUNTIME_ERROR=$((RUNTIME_ERROR + 1))
    echo "  Error: $(echo "$output" | grep -E "RuntimeError|Error executing|Error reading" | head -1)"
  elif [ $status -ne 0 ]; then
    echo " [FAIL]"
    FAIL=$((FAIL + 1))
    echo "  Error: $(echo "$output" | head -1)"
  else
    # No errors detected and command succeeded
    echo " [PASS]"
    PASS=$((PASS + 1))
  fi
done

echo ""
echo "===================================="
echo "Summary:"
echo "  Passed:         $PASS"
echo "  Syntax Errors:  $SYNTAX_ERROR"
echo "  Runtime Errors: $RUNTIME_ERROR"
echo "  Other Failures: $FAIL"
echo "  Total:          $((PASS + SYNTAX_ERROR + RUNTIME_ERROR + FAIL))"
