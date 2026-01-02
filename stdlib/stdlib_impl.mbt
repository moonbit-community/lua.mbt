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
    @value.TValue::Function(_) | @value.TValue::NativeFunction(_) => "function"
    @value.TValue::Table(_) => "table"
  }
}

///|
/// tonumber(value) - Convert value to number
pub fn tonumber(value : @value.TValue) -> @value.TValue raise StdlibError {
  match value {
    @value.TValue::Integer(_) | @value.TValue::Number(_) => value
    @value.TValue::String(s) => {
      // Try to parse as number (supports decimal and hex)
      let num = if s.starts_with("0x") || s.starts_with("0X") {
        // Parse hexadecimal
        let hex_str = s.substring(start=2)
        match parse_hex_string(hex_str) {
          Some(n) => n.to_double()
          None =>
            raise StdlibError::InvalidArgument(
              func="tonumber",
              arg=1,
              message="invalid hex number",
            )
        }
      } else {
        // Parse decimal
        @strconv.parse_double(s) catch {
          _ =>
            raise StdlibError::InvalidArgument(
              func="tonumber",
              arg=1,
              message="invalid number",
            )
        }
      }
      @value.TValue::number(num)
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="tonumber",
        expected="number or string",
        actual=type_(value),
      )
  }
}

///|
/// Parse a hexadecimal string to an integer
fn parse_hex_string(hex_str : String) -> Int? {
  let mut result = 0
  for i = 0; i < hex_str.length(); i = i + 1 {
    let c = hex_str[i]
    let digit = match c.to_int().unsafe_to_char() {
      '0' => 0
      '1' => 1
      '2' => 2
      '3' => 3
      '4' => 4
      '5' => 5
      '6' => 6
      '7' => 7
      '8' => 8
      '9' => 9
      'a' | 'A' => 10
      'b' | 'B' => 11
      'c' | 'C' => 12
      'd' | 'D' => 13
      'e' | 'E' => 14
      'f' | 'F' => 15
      _ => return None
    }
    result = result * 16 + digit
  }
  Some(result)
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
/// string.rep(s, n) - Repeat a string n times
pub fn string_rep(s : @value.TValue, n : Int) -> String raise StdlibError {
  match s {
    @value.TValue::String(str) => {
      if n < 0 {
        raise StdlibError::InvalidArgument(
          func="string.rep",
          arg=2,
          message="negative repetition count",
        )
      }
      if n == 0 {
        return ""
      }
      let mut result = ""
      for _i = 0; _i < n; _i = _i + 1 {
        result = result + str
      }
      result
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.rep",
        expected="string",
        actual=type_(s),
      )
  }
}

///|
/// string.reverse(s) - Reverse a string
pub fn string_reverse(s : @value.TValue) -> String raise StdlibError {
  match s {
    @value.TValue::String(str) => {
      let len = str.length()
      let mut result = ""
      for i = len - 1; i >= 0; i = i - 1 {
        result = result + str[i].to_int().unsafe_to_char().to_string()
      }
      result
    }
    _ =>
      raise StdlibError::TypeMismatch(
        func="string.reverse",
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
  // Register native function values for standard library functions
  state.set_global("print", @value.TValue::native_function("print"))
  state.set_global("type", @value.TValue::native_function("type"))
  state.set_global("tonumber", @value.TValue::native_function("tonumber"))
  state.set_global("tostring", @value.TValue::native_function("tostring"))
  state.set_global("assert", @value.TValue::native_function("assert"))
  state.set_global("error", @value.TValue::native_function("error"))
  state.set_global("select", @value.TValue::native_function("select"))

  // Raw table access functions (bypass metatables)
  state.set_global("rawget", @value.TValue::native_function("rawget"))
  state.set_global("rawset", @value.TValue::native_function("rawset"))
  state.set_global("rawequal", @value.TValue::native_function("rawequal"))
  state.set_global("rawlen", @value.TValue::native_function("rawlen"))

  // Metatable functions
  state.set_global("setmetatable", @value.TValue::native_function("setmetatable"))
  state.set_global("getmetatable", @value.TValue::native_function("getmetatable"))

  // Iteration functions
  state.set_global("next", @value.TValue::native_function("next"))
  state.set_global("pairs", @value.TValue::native_function("pairs"))
  state.set_global("ipairs", @value.TValue::native_function("ipairs"))

  // Create math library table
  let math_table = @value.Table::new()

  // Math constants
  math_table.set_string("pi", @value.TValue::number(3.14159265358979323846))
  math_table.set_string("huge", @value.TValue::number(1.0 / 0.0))  // infinity

  // Math functions
  math_table.set_string("abs", @value.TValue::native_function("math.abs"))
  math_table.set_string("floor", @value.TValue::native_function("math.floor"))
  math_table.set_string("ceil", @value.TValue::native_function("math.ceil"))
  math_table.set_string("min", @value.TValue::native_function("math.min"))
  math_table.set_string("max", @value.TValue::native_function("math.max"))
  math_table.set_string("sqrt", @value.TValue::native_function("math.sqrt"))
  math_table.set_string("sin", @value.TValue::native_function("math.sin"))
  math_table.set_string("cos", @value.TValue::native_function("math.cos"))
  math_table.set_string("tan", @value.TValue::native_function("math.tan"))
  math_table.set_string("asin", @value.TValue::native_function("math.asin"))
  math_table.set_string("acos", @value.TValue::native_function("math.acos"))
  math_table.set_string("atan", @value.TValue::native_function("math.atan"))
  math_table.set_string("exp", @value.TValue::native_function("math.exp"))
  math_table.set_string("log", @value.TValue::native_function("math.log"))
  math_table.set_string("deg", @value.TValue::native_function("math.deg"))
  math_table.set_string("rad", @value.TValue::native_function("math.rad"))

  state.set_global("math", @value.TValue::table(math_table))

  // Create table library table
  let table_table = @value.Table::new()
  table_table.set_string("insert", @value.TValue::native_function("table.insert"))
  table_table.set_string("remove", @value.TValue::native_function("table.remove"))
  table_table.set_string("concat", @value.TValue::native_function("table.concat"))
  table_table.set_string("sort", @value.TValue::native_function("table.sort"))
  table_table.set_string("pack", @value.TValue::native_function("table.pack"))
  table_table.set_string("unpack", @value.TValue::native_function("table.unpack"))

  state.set_global("table", @value.TValue::table(table_table))

  // Create string library table
  let string_table = @value.Table::new()
  string_table.set_string("len", @value.TValue::native_function("string.len"))
  string_table.set_string("sub", @value.TValue::native_function("string.sub"))
  string_table.set_string("upper", @value.TValue::native_function("string.upper"))
  string_table.set_string("lower", @value.TValue::native_function("string.lower"))
  string_table.set_string("find", @value.TValue::native_function("string.find"))
  string_table.set_string("gsub", @value.TValue::native_function("string.gsub"))
  string_table.set_string("format", @value.TValue::native_function("string.format"))
  string_table.set_string("rep", @value.TValue::native_function("string.rep"))
  string_table.set_string("reverse", @value.TValue::native_function("string.reverse"))

  state.set_global("string", @value.TValue::table(string_table))
}
