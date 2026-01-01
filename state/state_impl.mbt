// Lua State Management Implementation
// Based on Lua 5.4's lstate.c
// Manages the Lua VM state including stack, globals, and call frames

///|
/// Call frame - tracks a function invocation
pub struct CallFrame {
  func : @value.FunctionValue  // The function being executed
  base : Int  // Base stack index for this frame
  mut pc : Int  // Program counter within this frame
  num_results : Int  // Number of expected results
} derive(Show)

///|
/// Create a new call frame
pub fn CallFrame::new(
  func : @value.FunctionValue,
  base : Int,
  num_results : Int,
) -> CallFrame {
  CallFrame::{ func, base, pc: 0, num_results }
}

///|
/// Lua VM state
pub struct LuaState {
  // Value stack (grows upward)
  stack : Array[@value.TValue]

  // Global variables
  globals : Map[String, @value.TValue]

  // Call stack
  call_stack : Array[CallFrame]
} derive(Show)

///|
/// Create a new Lua state
pub fn LuaState::new() -> LuaState {
  LuaState::{ stack: [], globals: {}, call_stack: [] }
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
    None => @value.TValue::nil()  // Undefined globals return nil in Lua
  }
}

///|
/// Check if a global exists
pub fn LuaState::has_global(self : LuaState, name : String) -> Bool {
  self.globals.contains(name)
}

///|
/// Push a new call frame onto the call stack
pub fn LuaState::push_frame(
  self : LuaState,
  func : @value.FunctionValue,
  base : Int,
  num_results : Int,
) -> Unit {
  let frame = CallFrame::new(func, base, num_results)
  self.call_stack.push(frame)
}

///|
/// Pop the top call frame
pub fn LuaState::pop_frame(self : LuaState) -> CallFrame raise StateError {
  match self.call_stack.pop() {
    Some(frame) => frame
    None => raise StateError::CallStackUnderflow
  }
}

///|
/// Get the current (top) call frame
pub fn LuaState::current_frame(self : LuaState) -> CallFrame raise StateError {
  let len = self.call_stack.length()
  if len > 0 {
    self.call_stack[len - 1]
  } else {
    raise StateError::NoActiveFrame
  }
}

///|
/// Get mutable reference to current frame (for PC updates)
pub fn LuaState::current_frame_mut(
  self : LuaState,
) -> CallFrame raise StateError {
  let len = self.call_stack.length()
  if len > 0 {
    self.call_stack[len - 1]
  } else {
    raise StateError::NoActiveFrame
  }
}

///|
/// Get call stack depth
pub fn LuaState::call_depth(self : LuaState) -> Int {
  self.call_stack.length()
}

///|
/// Update the PC of the current frame
pub fn LuaState::update_pc(self : LuaState, new_pc : Int) -> Unit raise StateError {
  let len = self.call_stack.length()
  if len > 0 {
    self.call_stack[len - 1].pc = new_pc
  } else {
    raise StateError::NoActiveFrame
  }
}
