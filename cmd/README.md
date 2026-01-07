# Lua CLI

Command-line interface for the Lua 5.4 interpreter implemented in MoonBit.

## Building

```bash
moon build
```

## Running

```bash
moon run cmd -- [OPTIONS] [SCRIPT] [ARGS...]
```

Backend/I/O
- Preferred target is `js` (see `moon.mod.json`).
- CLI file I/O uses synchronous Node bindings via `mizchi/js/node/fs` (js.mbt), e.g. `@fs.read_file_as_string(path)`.
- Reference: https://github.com/mizchi/js.mbt

## Command-line Options

### Flags

- `-v` - Show version information
- `-i` - Enter interactive mode after executing script
- `-E` - Ignore environment variables
- `-W` - Turn warnings into errors

### Named Arguments

- `-e <code>` - Execute a string of Lua code
- `-l <library>` - Load a library (can be specified multiple times)

### Positional Arguments

- `SCRIPT` - Lua script file to execute
- `ARGS...` - Arguments passed to the script

## Examples

### Show version

```bash
moon run cmd -- -v
```

Output:
```
Lua 5.4.0  Copyright (C) 1994-2020 Lua.org, PUC-Rio
MoonBit port Copyright (C) 2025
```

### Execute code string

```bash
moon run cmd -- -e "print('Hello, Lua!')"
```

### Load libraries and enter REPL

```bash
moon run cmd -- -l math -l string
```

### Run a script with arguments

```bash
moon run cmd -- myscript.lua arg1 arg2 arg3
```

### Execute code and enter interactive mode

```bash
moon run cmd -- -i -e "x = 10"
```

### Enter REPL with special options

```bash
moon run cmd -- -E -W
```

## Implementation Status

The CLI framework is complete and all command-line parsing works correctly. The following features are pending implementation:

- Actual Lua code execution (requires `lua/api` implementation)
- Interactive REPL (requires `lua/api` and `lua/vm` implementation)
- Library loading (requires `lua/stdlib` implementation)
- Script file reading and execution

All command-line options are parsed and ready to be connected to the Lua interpreter once the core components are implemented.

## Architecture

The CLI uses the [clap.mbt](https://github.com/TheWaWaR/clap.mbt) library for command-line argument parsing, which provides:

- Robust argument validation
- Automatic help generation
- Support for flags, named arguments, and positional arguments
- Error handling with descriptive messages

The implementation follows standard Lua command-line conventions and is compatible with Lua 5.4's CLI interface.
