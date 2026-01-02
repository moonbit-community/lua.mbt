# TODO List for Lua 5.4 Implementation

## Status Summary (Updated 2026-01-02)

**Test Results:**
- All 55 unit tests passing ✓
- All 101 integration tests passing ✓
- 7 comprehensive closure tests passing ✓

## Recently Completed ✅

### Closures (Read-Only) - IMPLEMENTED
**Status:** ✅ Complete for read-only upvalues
**Implementation:** Multi-level upvalue chaining with recursive resolution

**What Works:**
- Functions can capture variables from outer scopes (upvalues) ✓
- Multi-level nesting (inner functions can access grandparent variables) ✓
- Passing closures as values ✓
- Most closure patterns that only read upvalues ✓

**What Doesn't Work:**
- ❌ Modifying upvalues (SetUpval) - requires mutable shared references
- ❌ Local recursive functions - requires open upvalues (see below)

**Example (Works):**
```lua
function outer(x)
  return function(y)
    return function(z)
      return x + y + z  -- Reading upvalues works!
    end
  end
end
```

**Example (Doesn't Work):**
```lua
local function makeCounter()
  local count = 0
  return function()
    count = count + 1  -- FAILS: can't modify upvalue
    return count
  end
end
```

### Truthiness - FIXED
**Status:** ✅ Complete
Only `nil` and `false` are falsy. Everything else (0, "", {}, etc.) is truthy. ✓

### Metatables - IMPLEMENTED
**Status:** ✅ Complete
Full metamethod support including __index, __newindex, __add, __call, etc. ✓

### Standard Library - MOSTLY COMPLETE
**Status:** ✅ Most functions implemented

Implemented:
- Basic: print, type, tonumber, tostring, assert, error, pcall, xpcall, select ✓
- Tables: rawget, rawset, rawequal, rawlen, setmetatable, getmetatable ✓
- Iteration: next, pairs, ipairs ✓
- Math library: pi, huge, abs, floor, ceil, min, max, sqrt, trig functions, exp, log, deg, rad ✓
- Table library: insert, remove, concat, sort, pack, unpack ✓
- String library: len, sub, upper, lower, find, gsub, format, rep, reverse ✓

## Critical Issues Requiring Architectural Changes

### 1. Local Recursive Functions ⚠️ MAJOR LIMITATION
**Priority:** HIGH
**Status:** Blocked - requires open upvalues
**Issue:** Local functions cannot call themselves recursively
**Root Cause:** Current implementation uses "closed" upvalues (value copies) rather than "open" upvalues (stack references)

**Why It Fails:**
When `local function f()` is compiled:
1. Register R is allocated for function name
2. Function body is compiled, sees `f` as upvalue from parent
3. Closure opcode captures value from register R
4. **Problem:** Register R is empty at capture time!
5. Upvalue contains nil instead of the function

**What's Needed:**
Implement Lua's open/closed upvalue system:
- **Open upvalues**: Reference stack slots (not values)
- **Closed upvalues**: Contain heap values (after stack exits)
- **Close instruction**: Convert open → closed when exiting scope
- **Shared upvalue references**: Multiple closures share same upvalue object

**Implementation Complexity:** Very High
- Requires mutable shared references (Rc<RefCell<>> in Rust)
- Need global upvalue registry or reference counting in MoonBit
- Must modify: Closure opcode, GetUpval, SetUpval, function returns
- Estimated effort: 2-3 days of focused work

**Workaround:** Use global functions instead of local functions for recursion

### 2. Mutable Upvalues (SetUpval) ⚠️ ARCHITECTURAL LIMITATION
**Priority:** HIGH
**Status:** Not implementable with current architecture
**Issue:** Cannot modify captured variables from closures
**Root Cause:** Same as #1 - need open upvalues with mutable shared references

**Current Implementation:**
Upvalues are immutable value copies (`Array[TValue]`). GetUpval works (reads), but SetUpval cannot work without architecture change.

**What's Needed:**
Same solution as #1 - implement full open/closed upvalue system

## Known Bugs

### 3. Varargs Issues
**Priority:** HIGH
**Status:** Partially broken
**Issue:** Some varargs patterns fail with runtime errors
**Example:** Creating tables from varargs (`local args = {...}`) triggers "Invalid register write in LEN"

### Table Issues
- [ ] Boolean keys (`true`/`false`) may return `nil`
- [ ] Float keys (e.g., `10.5`) may return `nil`
- [ ] Table keys (using tables as keys) don't work properly
- [ ] Negative indexes behavior

### Function Issues
- [ ] Functions without explicit `return` may return unexpected values
- [ ] Missing function arguments may reuse values from previous calls

### Scope Issues
- [ ] Local variables may persist after block scope ends (shadowing issues)

### Assignment Issues
- [ ] Multiple assignment swap (`a, b = b, a`) may not evaluate RHS fully before LHS assignment

### Type Conversion Issues
- [ ] Implicit string-to-number conversion inconsistent
- [ ] `tonumber()` whitespace/base handling edge cases

## Syntax Limitations

- [ ] Multiline comments (`--[[  ]]`) not supported
- [ ] Unicode escape sequences (`\u{}`) not supported
- [ ] Binary number literals (`0b1010`) not supported

## Implementation Priorities

1. **Fix varargs** (HIGH - needed for many stdlib functions)
2. **Implement open/closed upvalues** (VERY HIGH EFFORT - enables local recursion and mutable upvalues)
3. **Fix remaining table edge cases** (MEDIUM)
4. **Improve error messages** (LOW - nice to have)
5. **Add remaining syntax features** (LOW - minor conveniences)

## What Works Excellently ✓

- ✅ Arithmetic operators (+, -, *, /, //, %, ^)
- ✅ Comparison operators (==, ~=, <, >, <=, >=)
- ✅ Logical operators (and, or, not) with short-circuit
- ✅ Bitwise operators (&, |, ~, <<, >>)
- ✅ String concatenation (..)
- ✅ Length operator (#)
- ✅ Table creation and access (integer/string keys)
- ✅ All loop types (for, while, repeat-until, numeric for, generic for)
- ✅ Break statements
- ✅ Functions (basic, multiple returns, higher-order, closures)
- ✅ Local and global variables
- ✅ Type system (type(), tonumber(), tostring())
- ✅ Metatables and metamethods
- ✅ Protected calls (pcall, xpcall)
- ✅ Error handling (error(), assert())
- ✅ Scientific notation, hex literals
- ✅ Escape sequences in strings
- ✅ Complex expressions and operator precedence
- ✅ Nested tables, large arrays, sparse arrays
- ✅ Read-only closures with multi-level nesting

## Architecture Notes

**Upvalue System:**
- Current: Closed upvalues only (immutable value copies)
- Needed: Open upvalues (mutable stack references) + closed upvalues
- Blocking: Local recursion, mutable captures, full Lua compatibility

**For Full Lua 5.4 Compatibility:**
The open/closed upvalue system is the primary architectural gap. Without it, the interpreter will always have limitations around recursive local functions and stateful closures.
