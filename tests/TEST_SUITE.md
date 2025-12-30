# Test Suite Documentation

This directory contains comprehensive tests for the MoonBit Lua 5.4 implementation.

## Test Organization

### Integration Tests (`tests/integration/`)
18 integration tests covering real-world usage patterns:
- Function calls (simple, chained, nested)
- Recursion (factorial, fibonacci)
- Control flow (if, while, for loops)
- Tables with various operations
- Variable scoping

### Comprehensive Test Suite (`tests/suite/`)
11 systematic tests covering all implemented features:

#### 1. **test_arithmetic.lua**
- Basic operations: +, -, *, /
- Operator precedence
- Parentheses grouping
- Negative numbers
- Mixed operations

#### 2. **test_comparisons.lua**
- Equality (==)
- Less than (<)
- Less than or equal (<=)
- Greater than (>)
- Greater than or equal (>=)
- Comparisons in conditionals

#### 3. **test_conditionals.lua**
- Simple if statements
- If-else branches
- Nested conditionals
- Multiple if statements
- Complex conditional expressions
- Conditionals in functions

#### 4. **test_loops_while.lua**
- Simple while loops
- Complex loop conditions
- Nested while loops
- While loops with counters
- While loops in functions

#### 5. **test_loops_for.lua**
- Basic for loops (1 to n)
- For loops with custom step
- Countdown loops (negative step)
- Single iteration loops
- Nested for loops
- For loops in functions

#### 6. **test_functions_basic.lua**
- Functions with no parameters
- Functions with single parameter
- Functions with multiple parameters
- Function calling functions
- Functions with local variables
- Nested function calls
- Function variables

#### 7. **test_functions_recursion.lua**
- Simple recursion (countdown)
- Factorial (classic recursion)
- Fibonacci (dual recursion)
- Recursive sum
- Multiple base cases
- Deep recursion

#### 8. **test_tables_basic.lua**
- Empty table creation
- Array-like tables (numeric indices)
- Table assignment
- Reading and writing sequences
- Tables in function parameters
- Table modification in functions
- Expression indices

#### 9. **test_tables_loops.lua**
- Building tables with loops
- Summing table elements
- Modifying tables in loops
- Tables with while loops
- Nested loops with tables
- Finding elements
- Copying tables

#### 10. **test_variables_scope.lua**
- Global variables
- Local variables
- Variable shadowing
- Nested scopes
- Scope in loops
- Function parameters shadowing
- Global modification in functions

#### 11. **test_mixed_features.lua**
- Fibonacci with memoization
- Prime number checking
- Array reversal
- Binary search (simplified)
- Nested data structures
- Complex algorithms combining multiple features

## Running Tests

### Run All Tests
```bash
./run_tests.sh
```

### Run Specific Test Category
```bash
# Integration tests only
for f in tests/integration/*.lua; do moon run cmd -- "$f"; done

# Test suite only
for f in tests/suite/*.lua; do moon run cmd -- "$f"; done
```

### Run Individual Test
```bash
moon run cmd -- tests/suite/test_arithmetic.lua
```

## Test Coverage

### Implemented Features (100% coverage)
✅ **Value Types**
- Numbers (integers and floats)
- Strings
- Booleans (true/false)
- Nil
- Tables
- Functions

✅ **Operators**
- Arithmetic: +, -, *, /
- Comparison: ==, <, <=, >, >=
- Unary: - (negation)

✅ **Control Flow**
- If/else conditionals
- While loops
- For loops (numeric with optional step)

✅ **Functions**
- Function definitions
- Function calls
- Parameters
- Return values
- Recursion
- Local functions
- Function variables

✅ **Tables**
- Table creation
- Numeric indexing (1-based)
- Assignment
- Reading values
- Nested tables

✅ **Variables**
- Global variables
- Local variables
- Variable scoping
- Shadowing

### Not Yet Implemented
❌ Operators: %, ^, //, &, |, ~, <<, >>
❌ Boolean operators: and, or, not
❌ String concatenation (..)
❌ Table length (#)
❌ Table iteration (pairs, ipairs)
❌ Metatables and metamethods
❌ Multiple return values
❌ Varargs (...)
❌ Method call syntax (:)
❌ Closures and upvalues
❌ Coroutines
❌ Standard library (beyond placeholders)
❌ I/O operations
❌ Module system (require)
❌ Error handling (pcall, xpcall)
❌ Goto statements
❌ Break and continue

## Test Results

**Current Status: 29/29 tests passing (100%)**

- Integration Tests: 18/18 ✓
- Comprehensive Suite: 11/11 ✓

All tests run successfully with zero failures, demonstrating a robust implementation of core Lua 5.4 features.

## Adding New Tests

When adding new tests:
1. Create test file in appropriate directory
2. Use descriptive names: `test_<feature>.lua`
3. Add comments explaining what's being tested
4. Test edge cases and error conditions
5. Run `./run_tests.sh` to verify all tests still pass

## Test Philosophy

These tests focus on:
- **Correctness**: Verifying the implementation behaves as expected
- **Coverage**: Exercising all implemented features
- **Real-world usage**: Testing practical code patterns
- **Regression prevention**: Catching bugs from future changes

Tests do NOT focus on:
- Features not yet implemented
- Performance benchmarking
- Memory usage
- Edge cases requiring unsupported features
