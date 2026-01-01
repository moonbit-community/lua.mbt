# TODO List for Lua 5.4 Implementation

## Critical Bugs (Must Fix)

### 1. Fix Truthiness in If/While Statements ⚠️ CRITICAL
**Priority:** HIGHEST
**Status:** Broken
**Issue:** Only `true` is truthy in if/while statements. All other values (numbers, strings, tables) are treated as falsy.
**Expected:** In Lua, only `nil` and `false` are falsy. Everything else should be truthy.
**Impact:** Breaks most real-world Lua programs that rely on standard truthiness.

**Example:**
```lua
if 0 then          -- Should execute, but doesn't
  print("works")
end

if "hello" then    -- Should execute, but doesn't
  print("works")
end
```

### 2. Implement Closures ⚠️ MAJOR
**Priority:** HIGH
**Status:** Not Implemented
**Issue:** Functions cannot access variables from outer scopes (upvalues).
**Impact:** Cannot create counter functions, higher-order functions with state, or any closure patterns.

**Example:**
```lua
local function makeCounter()
  local count = 0
  return function()
    count = count + 1  -- FAILS: can't access outer 'count'
    return count
  end
end
```

### 3. Fix Local Recursive Functions
**Priority:** HIGH
**Status:** Broken
**Issue:** Local functions cannot call themselves recursively.
**Impact:** Cannot write recursive algorithms with local functions.

**Example:**
```lua
local function factorial(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- FAILS: factorial not in scope
end
```

### 4. Fix Varargs
**Priority:** HIGH
**Status:** Broken
**Issue:** All values passed as varargs (`...`) become `nil`.
**Impact:** Variadic functions don't work.

**Example:**
```lua
local function sum(...)
  local args = {...}  -- All values become nil
  -- Can't access actual arguments
end
```

## Missing Standard Library Functions

### Generic For Loop Support
**Priority:** HIGH
- [ ] Implement `pairs()` - iterate over all table entries
- [ ] Implement `ipairs()` - iterate over array entries

### Math Library
**Priority:** MEDIUM
- [ ] Global `math` table
- [ ] `math.pi`, `math.huge`
- [ ] `math.abs()`, `math.floor()`, `math.ceil()`
- [ ] `math.min()`, `math.max()`
- [ ] `math.sqrt()`, `math.pow()`
- [ ] `math.sin()`, `math.cos()`, `math.tan()`
- [ ] `math.exp()`, `math.log()`, `math.log10()`
- [ ] `math.random()`, `math.randomseed()`
- [ ] `math.fmod()`

### String Library
**Priority:** MEDIUM
- [ ] Global `string` table (functions exist internally but not exposed)
- [ ] `string.len()`, `string.sub()`, `string.upper()`, `string.lower()`
- [ ] `string.rep()`, `string.reverse()`
- [ ] `string.char()`, `string.byte()`
- [ ] `string.format()`
- [ ] `string.find()`, `string.match()`, `string.gmatch()`
- [ ] `string.gsub()`

### Table Library
**Priority:** MEDIUM
- [ ] Global `table` table
- [ ] `table.insert()`, `table.remove()`
- [ ] `table.concat()`
- [ ] `table.sort()`
- [ ] `table.pack()`, `table.unpack()`

### Error Handling
**Priority:** MEDIUM
- [ ] `pcall()` - protected call
- [ ] `xpcall()` - protected call with error handler
- [ ] `error()` - raise error
- [ ] `assert()` - assertion

### Metatables
**Priority:** MEDIUM
- [ ] `setmetatable()` - set metatable
- [ ] `getmetatable()` - get metatable
- [ ] Metamethod support (`__index`, `__newindex`, `__add`, `__call`, etc.)

### Other Standard Functions
**Priority:** LOW
- [ ] `select()` - select arguments from varargs
- [ ] `next()` - table iteration
- [ ] `rawget()`, `rawset()` - raw table access
- [ ] `rawequal()` - raw equality
- [ ] `loadstring()` / `load()` - dynamic code loading

## Known Bugs

### Table Issues
- [ ] Boolean keys (`true`/`false`) return `nil` instead of stored value
- [ ] Float keys (e.g., `10.5`) return `nil` instead of stored value
- [ ] Table keys (using tables as keys) don't work
- [ ] Index 0 and negative indexes return `nil` instead of stored value
- [ ] Table length (`#table`) doesn't update correctly after `table[#table] = nil`

### Function Issues
- [ ] Functions without explicit `return` return the function object instead of `nil`
- [ ] Local functions cannot call other local functions in the same scope
- [ ] Missing function arguments reuse values from previous calls instead of being `nil`

### Scope Issues
- [ ] Local variables persist after block scope ends (shadowing broken)
- [ ] Local variables in for loops may leak to outer scope

### Assignment Issues
- [ ] Multiple assignment swap (`a, b = b, a`) doesn't work correctly - RHS not fully evaluated before LHS assignment

### Type Conversion Issues
- [ ] Implicit string-to-number conversion doesn't work (e.g., `"5" + 3` fails)
- [ ] `tonumber()` doesn't handle leading/trailing whitespace
- [ ] `tonumber()` with base 16 needs `0x` prefix

## Syntax Limitations

- [ ] Multiline comments (`--[[  ]]`) not supported
- [ ] Unicode escape sequences (`\u{}`) not supported
- [ ] Binary number literals (`0b1010`) not supported

## Test Statistics

**Total Integration Tests:** 76
**Fully Working Features:** ~17
**Critical Bugs Found:** ~10
**Missing Stdlib Functions:** ~50+

## Priority Order for Implementation

1. **Fix truthiness** (CRITICAL - breaks most programs)
2. **Implement closures** (MAJOR - needed for real programs)
3. **Implement pairs/ipairs** (needed for table iteration)
4. **Fix varargs** (needed for variadic functions)
5. **Fix local recursion** (needed for recursive algorithms)
6. **Implement math library** (commonly used)
7. **Implement string library** (commonly used)
8. **Implement table library** (commonly used)
9. **Implement error handling** (pcall/xpcall/error)
10. **Implement metatables** (needed for OOP patterns)

## What Works Well ✓

- Arithmetic operators (+, -, *, /, %, ^)
- Comparison operators (==, ~=, <, >, <=, >=)
- Logical operators (and, or, not) - including short-circuit evaluation
- Bitwise operators (&, |, ~, <<, >>)
- String concatenation (..)
- Length operator (#)
- Table creation and access (integer and string keys)
- Numeric for loops (with positive/negative step)
- While loops
- Repeat-until loops
- Break statements
- Functions (basic, multiple returns, higher-order)
- Local and global variables (basic usage)
- Type checking (`type()`, `tonumber()`, `tostring()`)
- Scientific notation (1e3)
- Hex literals (0xFF)
- Escape sequences in strings (\n, \t, \\, \', \")
- Complex expressions and operator precedence
- Nested tables
- Large arrays (tested up to 1000 elements)
- Sparse arrays

---

*Last updated: Session adding 76 integration tests*
