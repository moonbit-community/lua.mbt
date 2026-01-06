# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Lua 5.4 interpreter** implemented in **MoonBit** using spec-driven development. The project implements a complete Lua VM with lexer, parser, compiler, and bytecode executor.

## Essential Commands

### Building and Testing
```bash
# Type-check all specs and tests (runs fast, always do this first)
moon check

# Build the project
moon build

# Run unit tests
moon test

# Run specific package tests
moon test value/
moon test vm/

# Run integration test suite
./run_tests.sh
```

### Running Lua Code
```bash
# Execute a Lua script file
moon run cmd -- script.lua

# Execute Lua code from command line
moon run cmd -- -e "print('Hello, Lua!')"

# Show version
moon run cmd -- -v

# Run integration tests individually
moon run cmd -- tests/integration/test_name.lua
```

### Quick Test Loop
```bash
# Fast development cycle: check → test → run
moon check && moon test && moon run cmd -- tests/integration/test_fibonacci.lua
```

## Architecture Overview

### Package Structure and Dependencies

The codebase follows a bottom-up dependency structure:

```
value       → Core value system (TValue tagged union, Lua types)
  ↓
opcodes     → VM instruction encoding (32-bit format)
  ↓
lex         → Lexical analysis (Lua source → tokens)
  ↓
parse       → Syntax analysis (tokens → AST)
  ↓
state       → VM state management (stack, globals, call frames)
  ↓
compile     → Code generation (AST → bytecode Proto)
  ↓
vm          → Bytecode executor (register-based VM)
  ↓
stdlib      → Standard library (print, math, string, table)
gc          → Garbage collector (currently unused - MoonBit has GC)
api         → Lua C API compatibility layer
cmd         → CLI entry point
```

### Execution Pipeline

```
Lua Source Code
    ↓
  [lex]     → Tokenize into TokenType stream
    ↓
  [parse]   → Build AST (Expr/Stmt tree)
    ↓
  [compile] → Generate bytecode (Proto with instructions + constants)
    ↓
  [vm]      → Execute in register-based VM
    ↓         (interacts with state, stdlib, value)
  Output
```

### Key Types Across the System

- **TValue** (value/): Tagged union representing all Lua values (Nil, Boolean, Number, String, Table, Function, etc.)
- **Instruction** (opcodes/): 32-bit encoded VM instruction (OpCode + operands A/B/C/Bx/Ax)
- **Token** (lex/): Lexical token with type and position
- **Expr/Stmt** (parse/): AST node types for expressions and statements
- **Proto** (compile/vm/): Function prototype containing bytecode, constants, and upvalue descriptors
- **LuaState** (state/): VM runtime state with stack and global environment
- **Closure** (value/): Function with captured upvalues

## Spec-Driven Development Workflow

This project uses MoonBit's `#declaration_only` feature for test-driven development:

1. **Spec files** (`*_spec.mbt`) define the public API contract (types, function signatures)
2. **Test files** (`*_test.mbt`) validate the spec (type-checked before implementation exists)
3. **Implementation files** (`*_impl.mbt`) provide the actual implementation

When working on a package:
- Read the `*_spec.mbt` file to understand the API contract
- Look at `*_test.mbt` to understand expected behavior
- Implement in `*_impl.mbt` (or similar implementation files)
- Run `moon check` to verify type correctness
- Run `moon test` to verify behavior

## Critical Implementation Details

### Upvalue System (MAJOR LIMITATION)

**Current implementation**: Closed upvalues only (immutable value copies)
- ✅ Works: Reading captured variables from outer scopes
- ✅ Works: Multi-level nesting (closures capturing grandparent variables)
- ❌ Broken: Modifying upvalues (SetUpval instruction is unimplemented)
- ❌ Broken: Local recursive functions (function captures nil before definition)

**Why local recursion fails**:
```lua
local function fib(n)  -- Register R allocated for 'fib'
  if n <= 1 then return n end
  return fib(n-1) + fib(n-2)  -- Captures 'fib' as upvalue, but R is still nil!
end
```

**Workaround**: Use global functions for recursion, or forward-declare locals:
```lua
local fib
fib = function(n) ... end  -- This works
```

### Register-Based VM

Unlike stack-based VMs (e.g., Python), Lua uses registers (like CPU registers):
- Function locals map to registers R0, R1, R2, ...
- Instructions operate on registers: `ADD R0 R1 R2` means `R0 = R1 + R2`
- Stack only used for function calls and varargs
- Limited to 255 registers per function (8-bit register operands)

### Table Implementation

Tables are the only data structure in Lua (used for arrays, objects, modules):
- Implemented as MoonBit `Map[TValue, TValue]`
- No optimization for array part vs hash part (unlike official Lua)
- Supports metamethods (`__index`, `__newindex`, etc.)

### Known Bugs

1. **Varargs in table constructors**: `{...}` creates empty table (SetList opcode incomplete)
2. **Table keys**: Boolean/float/table keys may not work correctly
3. **Scope issues**: Local variables may persist beyond block scope in edge cases

## Testing Strategy

### Test Organization

- `tests/stage0/` - Basic arithmetic, strings, locals (no control flow)
- `tests/stage1/` - Control flow (if/else, loops)
- `tests/stage2/` - Functions, closures
- `tests/integration/` - Comprehensive feature tests (102 tests)
- `tests/bytecode/` - Low-level bytecode tests
- Package tests: `*/test.mbt` files (55 unit tests)

### Running Specific Tests

```bash
# Single integration test
moon run cmd -- tests/integration/test_fibonacci.lua

# All integration tests with status
for f in tests/integration/*.lua; do
  echo "Testing $f"
  timeout 2 moon run cmd -- "$f" 2>&1 | tail -2
done

# Full test suite with pretty output
./run_tests.sh
```

## Common Development Tasks

### Adding a New Opcode

1. Add to `OpCode` enum in `opcodes/opcodes_spec.mbt`
2. Update `get_op_mode()` in `opcodes/opcodes_impl.mbt`
3. Emit the opcode in `compile/compile_impl.mbt`
4. Handle execution in `vm/vm_impl.mbt`'s main dispatch loop
5. Add tests

### Adding a Standard Library Function

1. Implement in `stdlib/stdlib_impl.mbt` (e.g., `string_upper()`)
2. Register in `init()` function to make it available globally
3. Add integration test in `tests/integration/`

### Debugging Failed Tests

1. Run with explicit output: `moon run cmd -- failing_test.lua`
2. Add `print()` statements in the Lua test
3. Check bytecode: uncomment debug output in `vm/vm_impl.mbt`
4. Use `moon check` to catch type errors early
5. Check FEATURES.md and TODOs.md for known limitations

## Implementation Status

See FEATURES.md for detailed status. Summary:

- ✅ **Fully working**: Arithmetic, strings, tables, control flow, functions, closures (read-only), metatables, standard library (basic/string/table/math), error handling
- ⚠️ **Partially working**: Closures (no mutable upvalues), varargs (no table expansion)
- ❌ **Not implemented**: Coroutines, goto/labels, io/os/debug libraries, mutable upvalues, local recursion

**Test Results**: 157/157 tests passing (55 unit + 102 integration)

## Reference Materials

- Official Lua 5.4 source code: `refs/lua/` (C implementation)
- [Lua 5.4 Reference Manual](https://www.lua.org/manual/5.4/)
- [MoonBit Documentation](https://www.moonbitlang.com/docs/)
- Project-specific docs: README.md, FEATURES.md, TODOs.md
