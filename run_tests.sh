#!/bin/bash
# Test Suite Runner for MoonBit Lua Implementation

echo "====================================="
echo "MoonBit Lua Test Suite Runner"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
total=0
passed=0
failed=0

# Function to run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file")

    total=$((total + 1))

    # Run test with timeout
    if timeout 3 moon run cmd -- "$test_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $test_name"
        passed=$((passed + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        failed=$((failed + 1))
    fi
}

# Run integration tests
echo "Integration Tests:"
echo "-----------------------------------"
for test in tests/integration/*.lua; do
    run_test "$test"
done

echo ""
echo "Test Suite Tests:"
echo "-----------------------------------"
for test in tests/suite/*.lua; do
    run_test "$test"
done

echo ""
echo "====================================="
echo "Test Results:"
echo "Total:  $total"
echo -e "${GREEN}Passed: $passed${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}Failed: $failed${NC}"
else
    echo "Failed: $failed"
fi
echo "====================================="

# Exit with error code if any tests failed
if [ $failed -gt 0 ]; then
    exit 1
else
    exit 0
fi
