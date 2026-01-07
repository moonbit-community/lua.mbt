# Lua 5.4 to MoonBit Port - Spec-Driven Development Setup

This project implements a port of Lua 5.4 to MoonBit using spec-driven development methodology.

## Project Architecture

```
lua.mbt/
├── moon.mod.json          # Module configuration
├── README.md              # This file
│
├── value/                 # Core Value System
│   ├── moon.pkg.json
│   ├── value_spec.mbt     # TValue tagged value types
│   └── value_basic_test.mbt
│
├── opcodes/               # VM Instruction Format
│   ├── moon.pkg.json
│   ├── opcodes_spec.mbt   # 32-bit instruction encoding
│   └── opcodes_basic_test.mbt
│
├── lex/                   # Lexical Analysis
│   ├── moon.pkg.json
│   ├── lex_spec.mbt       # Tokenizer
│   └── lex_basic_test.mbt
│
├── parse/                 # Syntax Analysis
│   ├── moon.pkg.json
│   ├── parse_spec.mbt     # Parser (tokens → AST)
│   └── parse_basic_test.mbt
│
├── compile/               # Code Generation
│   ├── moon.pkg.json
│   ├── compile_spec.mbt   # Compiler (AST → bytecode)
│   └── compile_basic_test.mbt
│
├── state/                 # VM State Management
│   ├── moon.pkg.json
│   ├── state_spec.mbt     # Stack, globals, call frames
│   └── state_basic_test.mbt
│
├── vm/                    # Virtual Machine
│   ├── moon.pkg.json
│   ├── vm_spec.mbt        # Bytecode executor
│   └── vm_basic_test.mbt
│
├── gc/                    # Garbage Collector
│   ├── moon.pkg.json
│   ├── gc_spec.mbt        # Tri-color marking GC
│   └── gc_basic_test.mbt
│
├── stdlib/                # Standard Library
│   ├── moon.pkg.json
│   ├── stdlib_spec.mbt    # print, type, math.*, string.*
│   └── stdlib_basic_test.mbt
│
└── api/                   # C API Compatibility
    ├── moon.pkg.json
    ├── api_spec.mbt       # Embedding interface
    └── api_basic_test.mbt
```

## Data Flow

```
Lua Source Code
      ↓
   [lex] → Tokens
      ↓
  [parse] → AST
      ↓
 [compile] → Bytecode (Proto)
      ↓
   [vm] ← → [state] ← → [value]
      ↓           ↓         ↓
  [stdlib]     [gc]     [api]
```

## Package Dependencies

```
value       (no dependencies - foundation)
  ↓
opcodes     (no dependencies)
  ↓
lex         (no dependencies)
  ↓
parse       (depends on: lex, value)
  ↓
state       (depends on: value)
  ↓
vm          (depends on: value, opcodes, state)
  ↓
compile     (depends on: parse, opcodes, value, vm)
  ↓
stdlib      (depends on: value, state)
gc          (depends on: value)
api         (depends on: all above)
```

## Spec-Driven Development Approach

Each package follows the spec-driven development pattern:

1. **Specification files** (`*_spec.mbt`) - Define the public API contract using `#declaration_only`
2. **Test files** (`*_test.mbt`) - Type-checked tests that validate the spec (before implementation)
3. **Implementation files** - To be created in separate files within the same package

## Current Status

✅ All specification files created (10 packages)
✅ Basic test suites written for each package
✅ `moon check` passes - all specs type-check correctly
✅ 29 source files created
⏳ Implementation pending

## Backend Target And I/O

- Preferred target: `js` (see `moon.mod.json:4`)
- I/O: Uses synchronous Node.js bindings provided via js.mbt-backed module `moonbitlang/x/fs`.
  - Rationale: Simple, deterministic file access for CLI and tests under Node without event loop setup.
  - Example: CLI reads scripts with `@fs.read_file_to_string(path)`.
  - Upstream reference: https://github.com/mizchi/js.mbt

Notes:
- `moon run cmd -- ...` will execute the JS backend by default.
- Legacy native-specific scripts may need adjustment; prefer `moon run cmd` instead of invoking a native binary directly.

## Key Design Decisions

### MoonBit-Specific Adaptations

1. **Error Handling** - Uses MoonBit's `raise` system with typed errors instead of C's error codes
2. **Type System** - Leverages MoonBit's enum and struct with derivation (Eq, Show, ToJson)
3. **Memory Management** - MoonBit's GC instead of Lua's manual memory management
4. **Package Organization** - Logical separation following Lua's architecture but adapted to MoonBit's module system

### Lua Compatibility

- Maintains Lua 5.4 semantics for values, operators, and control flow
- Register-based VM with 32-bit instruction format (compatible with Lua 5.x)
- Standard library functions match Lua's behavior
- C API layer provides embedding compatibility

## Spec Overview

### Value System (value/)
- `LuaType` enum: Nil, Boolean, Number, String, Table, Function, Userdata, Thread
- `TValue` type: Tagged value with type-safe operations
- Operations: type checking, conversion, comparison, equality

### Opcodes (opcodes/)
- `OpCode` enum: 40+ VM opcodes (Move, LoadK, Add, Sub, Call, etc.)
- `OpMode` enum: Instruction formats (ABC, ABx, AsBx, Ax, SJ)
- `Instruction` type: 32-bit instruction encoding/decoding

### Lexer (lex/)
- `TokenType` enum: 70+ token types (keywords, operators, literals)
- `Token` struct: Token with position information
- `Lexer` type: Stateful tokenizer

### Parser (parse/)
- `Expr` enum: Expression AST nodes (literals, operators, calls, tables)
- `Stmt` enum: Statement AST nodes (blocks, loops, conditions, functions)
- `Parser` type: Recursive descent parser

### Compiler (compile/)
- `Compiler` type: Stateful code generator
- `compile()` function: One-shot compilation

### State (state/)
- `LuaState` type: VM state with stack and globals
- Operations: push/pop, stack indexing, global variables

### VM (vm/)
- `Proto` type: Function prototype (bytecode + constants)
- `execute()` function: Bytecode execution
- `execute_instruction()` function: Single instruction execution

### GC (gc/)
- `GC` type: Garbage collector state
- `GCColor` enum: White, Gray, Black (tri-color marking)
- Operations: allocate, mark, collect

### Standard Library (stdlib/)
- Basic: print, type, tonumber, tostring, assert
- Math: abs, floor, ceil, sqrt
- String: len, sub, upper, lower

### API (api/)
- `LuaAPI` type: C-compatible embedding interface
- Stack operations: push/pop values
- Execution: load_string, pcall
- Globals: get_global, set_global

## Next Steps

### Recommended Implementation Order

1. **value/** - Foundation for everything else
   - Implement TValue as a tagged union
   - Implement type checking and conversion

2. **opcodes/** - Instruction encoding
   - Implement instruction bit manipulation
   - Implement opcode mode lookup

3. **lex/** - Front-end (part 1)
   - Implement tokenizer state machine
   - Handle keywords, operators, literals

4. **parse/** - Front-end (part 2)
   - Implement recursive descent parser
   - Build AST from tokens

5. **state/** - Runtime foundation
   - Implement stack-based register file
   - Implement global variable storage

6. **compile/** - Code generation
   - Implement AST → bytecode translation
   - Generate function prototypes

7. **vm/** - Execution engine
   - Implement instruction dispatch loop
   - Implement arithmetic, control flow, etc.

8. **gc/** - Memory management
   - Implement tri-color marking
   - Implement sweep phase

9. **stdlib/** - Core functions
   - Implement basic library functions
   - Register into global environment

10. **api/** - Embedding interface
    - Wrap state/vm in C-compatible API
    - Implement error handling

## Running Tests

```bash
# Type-check all specs and tests
moon check

# Run tests (after implementation)
moon test

# Run specific package tests
moon test value/
moon test vm/

# Update test snapshots
moon test --update
```

## Development Workflow

1. Choose a package to implement (start with `value/`)
2. Read the spec file to understand the API contract
3. Create implementation files in the same package directory (e.g., `value_impl.mbt`)
4. Implement the `#declaration_only` functions and types
5. Run `moon test` to validate against the spec tests
6. Add more comprehensive tests as needed
7. Run `moon check` to ensure no type errors

## Reference

- Original Lua 5.4 source: `refs/lua/`
- Lua 5.4 manual: https://www.lua.org/manual/5.4/
- MoonBit documentation: https://www.moonbitlang.com/docs/
- MoonBit tour: https://tour.moonbitlang.com/

## Contributing

When implementing a package:
- Follow the spec exactly - don't change the API
- Add implementation files alongside spec files
- Write additional tests for edge cases
- Document complex algorithms with comments
- Use `///|` to delimit top-level items
- Prefer functional style (immutable by default)
- Use `derive(Eq, Show, ToJson)` for debugging support
