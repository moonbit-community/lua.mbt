// Lua State Management Specification
// Based on Lua 5.4's lstate.h
// Manages the Lua VM state including stack, globals, and call frames

///|
/// State errors
pub(all) suberror StateError {
  StackOverflow
  StackUnderflow
  InvalidStackIndex(index~ : Int)
  GlobalNotFound(name~ : String)
  CallStackUnderflow
  NoActiveFrame
} derive(Eq, Show, ToJson)

///|
/// Lua VM state
#declaration_only
pub type LuaState

///|
/// Create a new Lua state
#declaration_only
pub fn LuaState::new() -> LuaState {
  ...
}

///|
/// Push a value onto the stack
#declaration_only
pub fn LuaState::push(self : LuaState, value : @value.TValue) -> Unit {
  ...
}

///|
/// Pop a value from the stack
#declaration_only
pub fn LuaState::pop(self : LuaState) -> @value.TValue raise StateError {
  ...
}

///|
/// Get value at stack index (negative indices count from top)
#declaration_only
pub fn LuaState::get(
  self : LuaState,
  index : Int,
) -> @value.TValue raise StateError {
  ...
}

///|
/// Set value at stack index
#declaration_only
pub fn LuaState::set(
  self : LuaState,
  index : Int,
  value : @value.TValue,
) -> Unit raise StateError {
  ...
}

///|
/// Get stack size
#declaration_only
pub fn LuaState::stack_size(self : LuaState) -> Int {
  ...
}

///|
/// Set a global variable
#declaration_only
pub fn LuaState::set_global(
  self : LuaState,
  name : String,
  value : @value.TValue,
) -> Unit {
  ...
}

///|
/// Get a global variable
#declaration_only
pub fn LuaState::get_global(
  self : LuaState,
  name : String,
) -> @value.TValue raise StateError {
  ...
}

///|
/// Check if a global exists
#declaration_only
pub fn LuaState::has_global(self : LuaState, name : String) -> Bool {
  ...
}
