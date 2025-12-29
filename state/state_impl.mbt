// Lua State Management Implementation
// Based on Lua 5.4's lstate.c
// Manages the Lua VM state including stack, globals, and call frames

///|
/// Lua VM state
pub struct LuaState {
  // Value stack (grows upward)
  stack : Array[@value.TValue]

  // Global variables
  globals : Map[String, @value.TValue]
} derive(Show)

///|
/// Create a new Lua state
pub fn LuaState::new() -> LuaState {
  LuaState::{ stack: [], globals: {} }
}

///|
/// Push a value onto the stack
pub fn LuaState::push(self : LuaState, value : @value.TValue) -> Unit {
  self.stack.push(value)
}

///|
/// Pop a value from the stack
pub fn LuaState::pop(self : LuaState) -> @value.TValue raise StateError {
  match self.stack.pop() {
    Some(value) => value
    None => raise StateError::StackUnderflow
  }
}

///|
/// Convert Lua-style index to 0-based array index
/// Lua uses 1-based positive indices and negative indices from top
/// - Positive: 1 = first element, 2 = second, etc.
/// - Negative: -1 = top, -2 = second from top, etc.
fn normalize_index(stack_size : Int, index : Int) -> Int? {
  if index > 0 {
    // Positive index: 1-based from bottom
    let array_index = index - 1
    if array_index >= 0 && array_index < stack_size {
      Some(array_index)
    } else {
      None
    }
  } else if index < 0 {
    // Negative index: from top
    let array_index = stack_size + index
    if array_index >= 0 && array_index < stack_size {
      Some(array_index)
    } else {
      None
    }
  } else {
    // index == 0 is invalid in Lua
    None
  }
}

///|
/// Get value at stack index (negative indices count from top)
pub fn LuaState::get(
  self : LuaState,
  index : Int,
) -> @value.TValue raise StateError {
  let stack_size = self.stack.length()
  match normalize_index(stack_size, index) {
    Some(array_index) => self.stack[array_index]
    None => raise StateError::InvalidStackIndex(index~)
  }
}

///|
/// Set value at stack index
pub fn LuaState::set(
  self : LuaState,
  index : Int,
  value : @value.TValue,
) -> Unit raise StateError {
  let stack_size = self.stack.length()
  match normalize_index(stack_size, index) {
    Some(array_index) => self.stack[array_index] = value
    None => raise StateError::InvalidStackIndex(index~)
  }
}

///|
/// Get stack size
pub fn LuaState::stack_size(self : LuaState) -> Int {
  self.stack.length()
}

///|
/// Set a global variable
pub fn LuaState::set_global(
  self : LuaState,
  name : String,
  value : @value.TValue,
) -> Unit {
  self.globals[name] = value
}

///|
/// Get a global variable
pub fn LuaState::get_global(
  self : LuaState,
  name : String,
) -> @value.TValue raise StateError {
  match self.globals.get(name) {
    Some(value) => value
    None => raise StateError::GlobalNotFound(name~)
  }
}

///|
/// Check if a global exists
pub fn LuaState::has_global(self : LuaState, name : String) -> Bool {
  self.globals.contains(name)
}
