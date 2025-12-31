// Lua C API Compatibility Layer Implementation
// Based on Lua 5.4's lua.h and lapi.c
// Provides C-style API for embedding Lua

///|
/// Lua API context (wraps LuaState with C-compatible interface)
pub struct LuaAPI {
  state : @state.LuaState
} derive(Show)

///|
/// Create a new Lua API context
pub fn LuaAPI::new() -> LuaAPI {
  let state = @state.LuaState::new()
  // Register standard library
  @stdlib.register_stdlib(state)
  LuaAPI::{ state, }
}

///|
/// Load and execute a string
pub fn LuaAPI::load_string(
  self : LuaAPI,
  source : String,
) -> Status raise APIError {
  // Lex the source
  let lexer = @lex.Lexer::new(source)

  // Parse into AST
  let parser = @parse.Parser::new(lexer)
  let stmt = parser.parse_chunk() catch {
    @parse.ParseError::UnexpectedToken(expected~, actual~, line~, ..) =>
      raise APIError::SyntaxError(
        message="Unexpected token '\{actual}', expected '\{expected}' at line \{line}",
      )
    @parse.ParseError::InvalidSyntax(message~, line~) =>
      raise APIError::SyntaxError(
        message="Syntax error at line \{line}: \{message}",
      )
    @parse.ParseError::UnexpectedEof(line~) =>
      raise APIError::SyntaxError(
        message="Unexpected end of file at line \{line}",
      )
  }

  // Compile to bytecode
  let proto = @compile.compile(stmt) catch {
    @compile.CompileError::TooManyLocals(line~) =>
      raise APIError::RuntimeError(
        message="Too many local variables at line \{line}",
      )
    @compile.CompileError::TooManyConstants(line~) =>
      raise APIError::RuntimeError(message="Too many constants at line \{line}")
    @compile.CompileError::InvalidJumpTarget(line~) =>
      raise APIError::RuntimeError(
        message="Invalid jump target at line \{line}",
      )
    @compile.CompileError::UndefinedVariable(name~, line~) =>
      raise APIError::RuntimeError(
        message="Undefined variable '\{name}' at line \{line}",
      )
    @compile.CompileError::BreakOutsideLoop(line~) =>
      raise APIError::RuntimeError(
        message="Break statement outside loop at line \{line}",
      )
  }

  // Execute the bytecode
  @vm.execute(self.state, proto) catch {
    @vm.VMError::InvalidOpcode(op~) =>
      raise APIError::RuntimeError(message="Invalid opcode: \{op}")
    @vm.VMError::DivisionByZero =>
      raise APIError::RuntimeError(message="Division by zero")
    @vm.VMError::InvalidOperation(message~) =>
      raise APIError::RuntimeError(message="Invalid operation: \{message}")
    @vm.VMError::RuntimeError(message~) =>
      raise APIError::RuntimeError(message="Runtime error: \{message}")
  }
  Status::OK
}

///|
/// Execute loaded code (protected call)
pub fn LuaAPI::pcall(
  self : LuaAPI,
  nargs : Int,
  nresults : Int,
) -> Status raise APIError {
  // For now, this is a simplified implementation
  // In a full implementation, this would execute a function on the stack
  ignore(nargs)
  ignore(nresults)
  Status::OK
}

///|
/// Get global variable and push onto stack
pub fn LuaAPI::get_global(self : LuaAPI, name : String) -> Unit {
  let value = self.state.get_global(name) catch { _ => @value.TValue::nil() }
  self.state.push(value)
}

///|
/// Set global variable from top of stack
pub fn LuaAPI::set_global(self : LuaAPI, name : String) -> Unit {
  let value = self.state.get(-1) catch { _ => @value.TValue::nil() }
  self.state.set_global(name, value)
}

///|
/// Push a number onto the stack
pub fn LuaAPI::push_number(self : LuaAPI, n : Double) -> Unit {
  self.state.push(@value.TValue::number(n))
}

///|
/// Push a string onto the stack
pub fn LuaAPI::push_string(self : LuaAPI, s : String) -> Unit {
  self.state.push(@value.TValue::string(s))
}

///|
/// Push nil onto the stack
pub fn LuaAPI::push_nil(self : LuaAPI) -> Unit {
  self.state.push(@value.TValue::nil())
}

///|
/// Push a boolean onto the stack
pub fn LuaAPI::push_boolean(self : LuaAPI, b : Bool) -> Unit {
  self.state.push(@value.TValue::boolean(b))
}

///|
/// Get number from stack at index
pub fn LuaAPI::to_number(self : LuaAPI, index : Int) -> Double raise APIError {
  let value = self.state.get(index) catch {
    @state.StateError::InvalidStackIndex(index~) =>
      raise APIError::InvalidIndex(index~)
    _ => raise APIError::RuntimeError(message="Stack error")
  }
  value.to_number() catch {
    _ =>
      raise APIError::TypeMismatch(
        expected="number",
        actual=value.type_of().to_string(),
      )
  }
}

///|
/// Get string from stack at index
pub fn LuaAPI::to_string(self : LuaAPI, index : Int) -> String raise APIError {
  let value = self.state.get(index) catch {
    @state.StateError::InvalidStackIndex(index~) =>
      raise APIError::InvalidIndex(index~)
    _ => raise APIError::RuntimeError(message="Stack error")
  }
  value.to_string()
}

///|
/// Get boolean from stack at index
pub fn LuaAPI::to_boolean(self : LuaAPI, index : Int) -> Bool {
  let value = self.state.get(index) catch { _ => @value.TValue::nil() }
  value.to_boolean()
}

///|
/// Get top of stack (number of elements)
pub fn LuaAPI::get_top(self : LuaAPI) -> Int {
  self.state.stack_size()
}

///|
/// Set top of stack (resize stack)
pub fn LuaAPI::set_top(self : LuaAPI, index : Int) -> Unit {
  let current = self.state.stack_size()
  if index > current {
    // Extend stack with nil values
    for i = current; i < index; i = i + 1 {
      self.state.push(@value.TValue::nil())
    }
  } else if index < current {
    // Shrink stack
    for i = index; i < current; i = i + 1 {
      ignore(self.state.pop() catch { _ => @value.TValue::nil() })
    }
  }
}
