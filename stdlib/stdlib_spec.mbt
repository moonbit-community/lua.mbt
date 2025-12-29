// Lua Standard Library Specification
// Based on Lua 5.4's standard library modules
// Provides core Lua functions like print, type, tonumber, etc.

///|
/// Standard library errors
pub(all) suberror StdlibError {
  InvalidArgument(func~ : String, arg~ : Int, message~ : String)
  TypeMismatch(func~ : String, expected~ : String, actual~ : String)
} derive(Eq, Show, ToJson)

///|
/// Basic library functions

///|
/// print(...) - Print values to stdout
#declaration_only
pub fn print(values : Array[@value.TValue]) -> Unit {
  ...
}

///|
/// type(value) - Get the type name of a value
#declaration_only
pub fn type_(value : @value.TValue) -> String {
  ...
}

///|
/// tonumber(value) - Convert value to number
#declaration_only
pub fn tonumber(value : @value.TValue) -> @value.TValue raise StdlibError {
  ...
}

///|
/// tostring(value) - Convert value to string
#declaration_only
pub fn tostring(value : @value.TValue) -> String {
  ...
}

///|
/// assert(condition, message) - Assert a condition is true
#declaration_only
pub fn assert_(
  condition : @value.TValue,
  message? : String,
) -> @value.TValue raise StdlibError {
  ...
}

///|
/// Math library functions

///|
/// math.abs(x) - Absolute value
#declaration_only
pub fn math_abs(x : @value.TValue) -> @value.TValue raise StdlibError {
  ...
}

///|
/// math.floor(x) - Round down
#declaration_only
pub fn math_floor(x : @value.TValue) -> @value.TValue raise StdlibError {
  ...
}

///|
/// math.ceil(x) - Round up
#declaration_only
pub fn math_ceil(x : @value.TValue) -> @value.TValue raise StdlibError {
  ...
}

///|
/// math.sqrt(x) - Square root
#declaration_only
pub fn math_sqrt(x : @value.TValue) -> @value.TValue raise StdlibError {
  ...
}

///|
/// String library functions

///|
/// string.len(s) - String length
#declaration_only
pub fn string_len(s : @value.TValue) -> Int raise StdlibError {
  ...
}

///|
/// string.sub(s, i, j) - Substring
#declaration_only
pub fn string_sub(
  s : @value.TValue,
  i : Int,
  j? : Int,
) -> String raise StdlibError {
  ...
}

///|
/// string.upper(s) - Convert to uppercase
#declaration_only
pub fn string_upper(s : @value.TValue) -> String raise StdlibError {
  ...
}

///|
/// string.lower(s) - Convert to lowercase
#declaration_only
pub fn string_lower(s : @value.TValue) -> String raise StdlibError {
  ...
}

///|
/// Register all standard library functions into a Lua state
#declaration_only
pub fn register_stdlib(state : @state.LuaState) -> Unit {
  ...
}
