# Lua Interpreter Test Suite

This directory contains test files for validating the Lua 5.4 interpreter implementation.

## Test Organization

### Stage 0: String Type & CLI Integration
Tests basic functionality without control flow or functions.

- `test_arithmetic.lua` - Basic arithmetic operations (+, -, *, /, %)
- `test_strings.lua` - String literal support
- `test_locals.lua` - Local variable declarations and assignments

**Expected:** All tests should compile and execute without errors.

### Stage 1: Control Flow
Tests conditional statements and loops.

- `test_if.lua` - Basic if statement
- `test_if_else.lua` - If-else branching
- `test_nested_if.lua` - Nested if statements
- `test_while.lua` - While loops
- `test_for.lua` - Numeric for loops
- `test_comparisons.lua` - All comparison operators (<, <=, >, >=, ==, ~=)

**Expected:** All tests should compile and execute, properly branching and looping.

## Running Tests

Execute individual test files:
```bash
moon run cmd -- tests/stage0/test_arithmetic.lua
moon run cmd -- tests/stage1/test_if.lua
```

Run all tests in a stage:
```bash
for f in tests/stage0/*.lua; do moon run cmd -- "$f"; done
for f in tests/stage1/*.lua; do moon run cmd -- "$f"; done
```

## Future Stages

- **Stage 2**: Functions (definition, calls, returns, recursion)
- **Stage 3**: Tables (construction, indexing, assignment)
- **Stage 4**: Complete standard library
- **Stage 5**: Integration tests
