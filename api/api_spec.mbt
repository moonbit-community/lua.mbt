// Lua C API Compatibility Layer Specification
// Based on Lua 5.4's lua.h and lapi.h
// Provides C-style API for embedding Lua

///|
/// API Status codes
pub(all) enum Status {
  OK
  Yield
  ErrRun
  ErrSyntax
  ErrMem
  ErrErr
} derive(Eq, Show, ToJson)

///|
/// C API errors
pub(all) suberror APIError {
  InvalidIndex(index~ : Int)
  TypeMismatch(expected~ : String, actual~ : String)
  SyntaxError(message~ : String)
  RuntimeError(message~ : String)
} derive(Eq, Show, ToJson)

///|
/// Lua API context (wraps LuaState with C-compatible interface)
#declaration_only
pub type LuaAPI

///|
/// Create a new Lua API context
#declaration_only
pub fn LuaAPI::new() -> LuaAPI {
  ...
}

///|
/// Load and execute a string
#declaration_only
pub fn LuaAPI::load_string(
  self : LuaAPI,
  source : String,
) -> Status raise APIError {
  ...
}

///|
/// Execute loaded code
#declaration_only
pub fn LuaAPI::pcall(
  self : LuaAPI,
  nargs : Int,
  nresults : Int,
) -> Status raise APIError {
  ...
}

///|
/// Get global variable
#declaration_only
pub fn LuaAPI::get_global(self : LuaAPI, name : String) -> Unit {
  ...
}

///|
/// Set global variable
#declaration_only
pub fn LuaAPI::set_global(self : LuaAPI, name : String) -> Unit {
  ...
}

///|
/// Push a number onto the stack
#declaration_only
pub fn LuaAPI::push_number(self : LuaAPI, n : Double) -> Unit {
  ...
}

///|
/// Push a string onto the stack
#declaration_only
pub fn LuaAPI::push_string(self : LuaAPI, s : String) -> Unit {
  ...
}

///|
/// Push nil onto the stack
#declaration_only
pub fn LuaAPI::push_nil(self : LuaAPI) -> Unit {
  ...
}

///|
/// Push a boolean onto the stack
#declaration_only
pub fn LuaAPI::push_boolean(self : LuaAPI, b : Bool) -> Unit {
  ...
}

///|
/// Get number from stack
#declaration_only
pub fn LuaAPI::to_number(self : LuaAPI, index : Int) -> Double raise APIError {
  ...
}

///|
/// Get string from stack
#declaration_only
pub fn LuaAPI::to_string(self : LuaAPI, index : Int) -> String raise APIError {
  ...
}

///|
/// Get boolean from stack
#declaration_only
pub fn LuaAPI::to_boolean(self : LuaAPI, index : Int) -> Bool {
  ...
}

///|
/// Get top of stack (number of elements)
#declaration_only
pub fn LuaAPI::get_top(self : LuaAPI) -> Int {
  ...
}

///|
/// Set top of stack (resize stack)
#declaration_only
pub fn LuaAPI::set_top(self : LuaAPI, index : Int) -> Unit {
  ...
}
