// Lua Standard Library Implementation
// Based on Lua 5.4's standard library modules
// Provides core Lua functions like print, type, tonumber, etc.

///|
/// print(...) - Print values to stdout
pub fn print(values : Array[@value.TValue]) -> Unit {
  let parts : Array[String] = []
  for value in values {
    parts.push(tostring(value))
  }
  println(parts.join("\t"))
}

///|
/// type(value) - Get the type name of a value
pub fn type_(value : @value.TValue) -> String {
  match value {
    @value.TValue::Nil => "nil"
    @value.TValue::Boolean(_) => "boolean"
    @value.TValue::Integer(_) | @value.TValue::Number(_) => "number"
    @value.TValue::String(_) => "string"
    @value.TValue::Function(_) => "function"
    @value.TValue::Table(_) => "table"
  }
}

///|
/// tonumber(value) - Convert value to number
pub fn tonumber(value : @value.TValue) -> @value.TValue raise StdlibError {
  match value {
    @value.TValue::Integer(_) | @value.TValue::Number(_) => value
    _ =>
      raise StdlibError::TypeMismatch(
        func="tonumber",
        expected="number",
        actual=type_(value),
      )
  }
}

///|
/// tostring(value) - Convert value to string
pub fn tostring(value : @value.TValue) -> String {
  value.to_string()
}

///|
/// assert(condition, message) - Assert a condition is true
pub fn assert_(
  condition : @value.TValue,
  message? : String,
) -> @value.TValue raise StdlibError {
  if condition.to_boolean() {
    condition
  } else {
    let msg = match message {
      Some(m) => m
      None => "assertion failed!"
    }
    raise StdlibError::InvalidArgument(func="assert", arg=1, message=msg)
  }
}

///|
/// Math library functions

///|
/// math.abs(x) - Absolute value
pub fn math_abs(x : @value.TValue) -> @value.TValue raise StdlibError {
  match x {
    @value.TValue::Integer(i) =>
      if i < 0L {
        @value.TValue::integer(-i)
      } else {
        @value.TValue::integer(i)
      }
    @value.TValue::Number(n) => @value.TValue::number(n.abs())
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.abs",
        expected="number",
        actual=type_(x),
      )
  }
}

///|
/// math.floor(x) - Round down
pub fn math_floor(x : @value.TValue) -> @value.TValue raise StdlibError {
  match x {
    @value.TValue::Integer(i) => @value.TValue::integer(i)
    @value.TValue::Number(n) => @value.TValue::number(n.floor())
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.floor",
        expected="number",
        actual=type_(x),
      )
  }
}

///|
/// math.ceil(x) - Round up
pub fn math_ceil(x : @value.TValue) -> @value.TValue raise StdlibError {
  match x {
    @value.TValue::Integer(i) => @value.TValue::integer(i)
    @value.TValue::Number(n) => @value.TValue::number(n.ceil())
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.ceil",
        expected="number",
        actual=type_(x),
      )
  }
}

///|
/// math.sqrt(x) - Square root
pub fn math_sqrt(x : @value.TValue) -> @value.TValue raise StdlibError {
  let num = x.to_number() catch {
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.sqrt",
        expected="number",
        actual=type_(x),
      )
  }
  if num < 0.0 {
    raise StdlibError::InvalidArgument(
      func="math.sqrt",
      arg=1,
      message="negative number",
    )
  }
  @value.TValue::number(num.sqrt())
}

///|
/// String library functions

///|
/// string.len(s) - String length
pub fn string_len(s : @value.TValue) -> Int raise StdlibError {
  match s {
    @value.TValue::String(str) => str.length()
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.len",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// string.sub(s, i, j) - Substring
/// Lua uses 1-based indexing and supports negative indices
pub fn string_sub(
  s : @value.TValue,
  i : Int,
  j? : Int,
) -> String raise StdlibError {
  match s {
    @value.TValue::String(str) => {
      let len = str.length()

      // Convert Lua 1-based index to 0-based, handle negative indices
      fn normalize_index(idx : Int, len : Int) -> Int {
        if idx < 0 {
          len + idx + 1  // Negative index counts from end
        } else if idx == 0 {
          1  // Lua treats 0 as 1
        } else {
          idx
        }
      }

      let start = normalize_index(i, len)
      let end = match j {
        Some(j_val) => normalize_index(j_val, len)
        None => len
      }

      // Clamp to valid range
      let start_idx = if start < 1 { 0 } else { start - 1 }  // Convert to 0-based
      let end_idx = if end > len { len } else { end }

      if start_idx >= len || end_idx < start {
        ""  // Empty string if invalid range
      } else {
        // MoonBit string slicing uses 0-based indexing
        let actual_end = end_idx
        if start_idx >= actual_end {
          ""
        } else {
          // Handle potential CreatingViewError from string slicing
          try {
            str[start_idx:actual_end].to_string()
          } catch {
            _ => ""  // Return empty string on slicing error
          }
        }
      }
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.sub",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// string.upper(s) - Convert to uppercase
pub fn string_upper(s : @value.TValue) -> String raise StdlibError {
  match s {
    @value.TValue::String(str) => {
      // Build uppercase string character by character
      let mut result = ""
      let len = str.length()
      for i = 0; i < len; i = i + 1 {
        let code = str[i]  // UInt16
        // Convert lowercase a-z (97-122) to uppercase A-Z (65-90)
        if code >= 97 && code <= 122 {
          let upper_code = code - 32
          result = result + upper_code.to_int().unsafe_to_char().to_string()
        } else {
          result = result + code.to_int().unsafe_to_char().to_string()
        }
      }
      result
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.upper",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// string.lower(s) - Convert to lowercase
pub fn string_lower(s : @value.TValue) -> String raise StdlibError {
  match s {
    @value.TValue::String(str) => {
      // Build lowercase string character by character
      let mut result = ""
      let len = str.length()
      for i = 0; i < len; i = i + 1 {
        let code = str[i]  // UInt16
        // Convert uppercase A-Z (65-90) to lowercase a-z (97-122)
        if code >= 65 && code <= 90 {
          let lower_code = code + 32
          result = result + lower_code.to_int().unsafe_to_char().to_string()
        } else {
          result = result + code.to_int().unsafe_to_char().to_string()
        }
      }
      result
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.lower",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// Register all standard library functions into a Lua state
pub fn register_stdlib(state : @state.LuaState) -> Unit {
  // Register placeholder values for standard library functions
  // In a full implementation, these would be function values
  // For now, just register them as nil to indicate they exist
  state.set_global("print", @value.TValue::nil())
  state.set_global("type", @value.TValue::nil())
  state.set_global("tonumber", @value.TValue::nil())
  state.set_global("tostring", @value.TValue::nil())
  state.set_global("assert", @value.TValue::nil())
}
