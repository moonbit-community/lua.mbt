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
/// string.find(s, pattern, init) - Find substring
/// Simplified version: only supports plain string search
pub fn string_find(
  s : @value.TValue,
  pattern : @value.TValue,
  init? : Int,
) -> (Int, Int) raise StdlibError {
  match (s, pattern) {
    (@value.TValue::String(str), @value.TValue::String(pat)) => {
      let start_pos = match init {
        Some(i) => if i > 0 { i - 1 } else { 0 }  // Lua 1-based to 0-based
        None => 0
      }

      // Simple substring search (no regex patterns)
      let str_len = str.length()
      let pat_len = pat.length()

      for i = start_pos; i <= str_len - pat_len; i = i + 1 {
        let mut found = true
        for j = 0; j < pat_len; j = j + 1 {
          if str[i + j] != pat[j] {
            found = false
            break
          }
        }
        if found {
          return (i + 1, i + pat_len)  // Lua 1-based indices
        }
      }

      // Not found - return (0, 0) to indicate failure
      (0, 0)
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.find",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// string.gsub(s, pattern, repl) - Global substitution
/// Simplified version: plain string replacement only
pub fn string_gsub(
  s : @value.TValue,
  pattern : @value.TValue,
  repl : @value.TValue,
) -> (String, Int) raise StdlibError {
  match (s, pattern, repl) {
    (@value.TValue::String(str), @value.TValue::String(pat), @value.TValue::String(replacement)) => {
      let mut result = ""
      let mut i = 0
      let mut count = 0
      let str_len = str.length()
      let pat_len = pat.length()

      if pat_len == 0 {
        return (str, 0)  // Empty pattern matches nothing
      }

      while i < str_len {
        // Check if pattern matches at position i
        let mut matches = true
        if i + pat_len > str_len {
          matches = false
        } else {
          for j = 0; j < pat_len; j = j + 1 {
            if str[i + j] != pat[j] {
              matches = false
              break
            }
          }
        }

        if matches {
          result = result + replacement
          i = i + pat_len
          count = count + 1
        } else {
          result = result + str[i].to_int().unsafe_to_char().to_string()
          i = i + 1
        }
      }

      (result, count)
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.gsub",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// string.format(fmt, ...) - Format string
/// Very simplified version: only supports %s (string) and %d (integer)
pub fn string_format(
  fmt : @value.TValue,
  args : Array[@value.TValue],
) -> String raise StdlibError {
  match fmt {
    @value.TValue::String(format_str) => {
      let mut result = ""
      let mut arg_index = 0
      let mut i = 0
      let len = format_str.length()

      while i < len {
        if format_str[i] == 37 {  // '%' character
          if i + 1 < len {
            let spec = format_str[i + 1]
            if spec == 115 {  // 's' - string
              if arg_index < args.length() {
                result = result + tostring(args[arg_index])
                arg_index = arg_index + 1
              }
              i = i + 2
              continue
            } else if spec == 100 {  // 'd' - decimal integer
              if arg_index < args.length() {
                let val = args[arg_index].to_integer() catch {
                  _ => raise StdlibError::TypeMismatch(
                    func="string.format",
                    expected="number",
                    actual=type_(args[arg_index]),
                  )
                }
                result = result + val.to_string()
                arg_index = arg_index + 1
              }
              i = i + 2
              continue
            }
          }
        }
        result = result + format_str[i].to_int().unsafe_to_char().to_string()
        i = i + 1
      }
      result
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.format",
        expected="string",
        actual=type_(fmt),
      )
  }
}

///|
/// Math library functions (advanced)

///|
/// math.sin(x) - Sine function
/// Note: Simplified stub - MoonBit doesn't expose trig functions yet
pub fn math_sin(x : @value.TValue) -> @value.TValue raise StdlibError {
  let _num = x.to_number() catch {
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.sin",
        expected="number",
        actual=type_(x),
      )
  }
  // TODO: Implement sin when MoonBit exposes math functions
  @value.TValue::number(0.0)  // Stub
}

///|
/// math.cos(x) - Cosine function
/// Note: Simplified stub - MoonBit doesn't expose trig functions yet
pub fn math_cos(x : @value.TValue) -> @value.TValue raise StdlibError {
  let _num = x.to_number() catch {
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.cos",
        expected="number",
        actual=type_(x),
      )
  }
  // TODO: Implement cos when MoonBit exposes math functions
  @value.TValue::number(1.0)  // Stub
}

///|
/// math.log(x, base) - Logarithm
/// Note: Simplified stub - MoonBit doesn't expose log functions yet
pub fn math_log(
  x : @value.TValue,
  base? : @value.TValue,
) -> @value.TValue raise StdlibError {
  let num = x.to_number() catch {
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.log",
        expected="number",
        actual=type_(x),
      )
  }

  if num <= 0.0 {
    raise StdlibError::InvalidArgument(
      func="math.log",
      arg=1,
      message="non-positive number",
    )
  }

  match base {
    Some(b) => {
      let _base_num = b.to_number() catch {
        _ =>
          raise StdlibError::TypeMismatch(
            func="math.log",
            expected="number",
            actual=type_(b),
          )
      }
      // TODO: Implement log with base when MoonBit exposes log functions
      @value.TValue::number(1.0)  // Stub
    }
    None => @value.TValue::number(1.0)  // Stub - natural log (base e)
  }
}

///|
/// math.min(...) - Minimum value
pub fn math_min(values : Array[@value.TValue]) -> @value.TValue raise StdlibError {
  if values.length() == 0 {
    raise StdlibError::InvalidArgument(
      func="math.min",
      arg=1,
      message="no values provided",
    )
  }

  let mut min_val = values[0].to_number() catch {
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.min",
        expected="number",
        actual=type_(values[0]),
      )
  }

  for i = 1; i < values.length(); i = i + 1 {
    let val = values[i].to_number() catch {
      _ =>
        raise StdlibError::TypeMismatch(
          func="math.min",
          expected="number",
          actual=type_(values[i]),
        )
    }
    if val < min_val {
      min_val = val
    }
  }

  @value.TValue::number(min_val)
}

///|
/// math.max(...) - Maximum value
pub fn math_max(values : Array[@value.TValue]) -> @value.TValue raise StdlibError {
  if values.length() == 0 {
    raise StdlibError::InvalidArgument(
      func="math.max",
      arg=1,
      message="no values provided",
    )
  }

  let mut max_val = values[0].to_number() catch {
    _ =>
      raise StdlibError::TypeMismatch(
        func="math.max",
        expected="number",
        actual=type_(values[0]),
      )
  }

  for i = 1; i < values.length(); i = i + 1 {
    let val = values[i].to_number() catch {
      _ =>
        raise StdlibError::TypeMismatch(
          func="math.max",
          expected="number",
          actual=type_(values[i]),
        )
    }
    if val > max_val {
      max_val = val
    }
  }

  @value.TValue::number(max_val)
}

///|
/// math.random(m, n) - Random number
/// Simplified: uses a basic linear congruential generator
pub fn math_random(
  m? : @value.TValue,
  n? : @value.TValue,
  seed : Int,
) -> (@value.TValue, Int) raise StdlibError {
  // Simple LCG: next = (a * seed + c) mod m
  let a = 1103515245
  let c = 12345
  let modulus = 1073741824  // 2^30 (reduced to fit in Int)
  let next_seed = (a * seed + c) % modulus
  let random_float = next_seed.to_double() / modulus.to_double()

  match (m, n) {
    (None, None) => {
      // random() returns float in [0, 1)
      (@value.TValue::number(random_float), next_seed)
    }
    (Some(m_val), None) => {
      // random(m) returns integer in [1, m]
      let m_int = m_val.to_integer() catch {
        _ =>
          raise StdlibError::TypeMismatch(
            func="math.random",
            expected="number",
            actual=type_(m_val),
          )
      }
      let result = 1L + (random_float * m_int.to_double()).to_int64()
      (@value.TValue::integer(result), next_seed)
    }
    (Some(m_val), Some(n_val)) => {
      // random(m, n) returns integer in [m, n]
      let m_int = m_val.to_integer() catch {
        _ =>
          raise StdlibError::TypeMismatch(
            func="math.random",
            expected="number",
            actual=type_(m_val),
          )
      }
      let n_int = n_val.to_integer() catch {
        _ =>
          raise StdlibError::TypeMismatch(
            func="math.random",
            expected="number",
            actual=type_(n_val),
          )
      }
      let range = (n_int - m_int + 1L).to_double()
      let result = m_int + (random_float * range).to_int64()
      (@value.TValue::integer(result), next_seed)
    }
    _ =>
      raise StdlibError::InvalidArgument(
        func="math.random",
        arg=1,
        message="invalid arguments",
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
