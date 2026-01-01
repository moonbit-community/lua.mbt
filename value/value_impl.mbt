// Lua Value System Implementation
// Implementation of the tagged value system for Lua

///|
/// Function reference - holds bytecode and constants
/// To avoid circular dependency, we duplicate Proto structure here
pub struct FunctionValue {
  code : Array[@opcodes.Instruction]
  constants : Array[TValue]
  upvalues : Array[TValue]
  param_count : Int  // Number of parameters this function expects
} derive(Show)

///|
/// Create a new function value
pub fn FunctionValue::new(
  code : Array[@opcodes.Instruction],
  constants : Array[TValue],
) -> FunctionValue {
  FunctionValue::{ code, constants, upvalues: [], param_count: 0 }
}

///|
/// Create a new function value with parameter count
pub fn FunctionValue::new_with_params(
  code : Array[@opcodes.Instruction],
  constants : Array[TValue],
  param_count : Int,
) -> FunctionValue {
  FunctionValue::{ code, constants, upvalues: [], param_count }
}

///|
/// Native function wrapper - identifies a native MoonBit function by name
/// The actual implementation is looked up in the VM
pub struct NativeFunctionValue {
  name : String  // Function name for lookup (e.g., "print", "type", etc.)
} derive(Show)

///|
/// Create a new native function value
pub fn NativeFunctionValue::new(name : String) -> NativeFunctionValue {
  NativeFunctionValue::{ name, }
}

///|
/// Table - Lua's associative array (array + hash)
/// Uses array for integer keys 1..n and hash for other keys
/// Each table has a unique ID for reference equality
pub struct Table {
  id : Int  // Unique ID for reference equality
  array : Array[TValue]  // Array part for integer keys
  hash : Map[String, TValue]  // Hash part for string keys
} derive(Show)

// Generate unique table IDs using a counter
let table_id_counter : Ref[Int] = { val: 0 }

fn next_table_id() -> Int {
  let id = table_id_counter.val
  table_id_counter.val = id + 1
  id
}

///|
/// Create a new empty table with a unique ID
pub fn Table::new() -> Table {
  Table::{ id: next_table_id(), array: [], hash: {} }
}

///|
/// Get value from table by integer index (1-based)
pub fn Table::get_int(self : Table, index : Int) -> TValue {
  if index >= 1 && index <= self.array.length() {
    self.array[index - 1]
  } else {
    TValue::nil()
  }
}

///|
/// Set value in table by integer index (1-based)
pub fn Table::set_int(self : Table, index : Int, value : TValue) -> Unit {
  if index >= 1 {
    // Extend array if needed
    while self.array.length() < index {
      self.array.push(TValue::nil())
    }
    self.array[index - 1] = value
  }
}

///|
/// Get value from table by string key
pub fn Table::get_string(self : Table, key : String) -> TValue {
  match self.hash.get(key) {
    Some(v) => v
    None => TValue::nil()
  }
}

///|
/// Set value in table by string key
pub fn Table::set_string(self : Table, key : String, value : TValue) -> Unit {
  self.hash[key] = value
}

///|
/// Convert a TValue to a hash key string (for non-integer, non-string keys)
fn tvalue_to_hash_key(key : TValue) -> String? {
  match key {
    TValue::Boolean(b) => Some("bool:" + b.to_string())
    TValue::Number(n) => Some("num:" + n.to_string())
    TValue::Table(t) => Some("table:" + t.id.to_string())
    TValue::Function(f) => Some("func:" + f.to_string())
    TValue::NativeFunction(f) => Some("nfunc:" + f.name)
    _ => None  // Integer and String handled separately, Nil not valid as key
  }
}

///|
/// Get value from table by any TValue key
pub fn Table::get(self : Table, key : TValue) -> TValue {
  match key {
    TValue::Integer(i) => self.get_int(i.to_int())
    TValue::Number(n) => {
      // Check if it's an exact integer
      let i = n.to_int64()
      if i.to_double() == n {
        self.get_int(i.to_int())
      } else {
        // Non-integer number, use hash
        match tvalue_to_hash_key(key) {
          Some(hash_key) => match self.hash.get(hash_key) {
            Some(v) => v
            None => TValue::nil()
          }
          None => TValue::nil()
        }
      }
    }
    TValue::String(s) => self.get_string(s)
    _ => {
      // Boolean, Table, Function, etc.
      match tvalue_to_hash_key(key) {
        Some(hash_key) => match self.hash.get(hash_key) {
          Some(v) => v
          None => TValue::nil()
        }
        None => TValue::nil()
      }
    }
  }
}

///|
/// Set value in table by any TValue key
pub fn Table::set(self : Table, key : TValue, value : TValue) -> Unit {
  match key {
    TValue::Integer(i) => self.set_int(i.to_int(), value)
    TValue::Number(n) => {
      // Check if it's an exact integer
      let i = n.to_int64()
      if i.to_double() == n {
        self.set_int(i.to_int(), value)
      } else {
        // Non-integer number, use hash
        match tvalue_to_hash_key(key) {
          Some(hash_key) => self.hash[hash_key] = value
          None => ()  // Nil key is invalid
        }
      }
    }
    TValue::String(s) => self.set_string(s, value)
    _ => {
      // Boolean, Table, Function, etc.
      match tvalue_to_hash_key(key) {
        Some(hash_key) => self.hash[hash_key] = value
        None => ()  // Nil key is invalid
      }
    }
  }
}

///|
/// Get table length (array part only)
/// In Lua, #t returns the "border" of the array: the last index i where
/// t[i] != nil and t[i+1] == nil (or 0 if all elements are nil)
pub fn Table::length(self : Table) -> Int {
  // Search backwards from the end to find the last non-nil element
  let mut i = self.array.length()
  while i > 0 {
    match self.array[i - 1] {
      TValue::Nil => i = i - 1  // Skip trailing nils
      _ => return i  // Found last non-nil element
    }
  }
  // All elements are nil (or array is empty)
  0
}

///|
/// Tagged Value - internal representation
/// This enum holds the actual Lua values with their types
pub enum TValue {
  Nil
  Boolean(Bool)
  Integer(Int64)
  Number(Double)
  String(String)
  Function(FunctionValue)
  NativeFunction(NativeFunctionValue)  // Native MoonBit functions
  Table(Table)  // Table support added
} derive(Show)

///|
/// Create a nil value
pub fn TValue::nil() -> TValue {
  TValue::Nil
}

///|
/// Create a boolean value
pub fn TValue::boolean(value : Bool) -> TValue {
  TValue::Boolean(value)
}

///|
/// Create an integer number value
pub fn TValue::integer(value : Int64) -> TValue {
  TValue::Integer(value)
}

///|
/// Create a float number value
pub fn TValue::number(value : Double) -> TValue {
  TValue::Number(value)
}

///|
/// Create a string value
pub fn TValue::string(value : String) -> TValue {
  TValue::String(value)
}

///|
/// Create a function value
pub fn TValue::function(value : FunctionValue) -> TValue {
  TValue::Function(value)
}

///|
/// Create a native function value
pub fn TValue::native_function(name : String) -> TValue {
  TValue::NativeFunction(NativeFunctionValue::new(name))
}

///|
/// Create a table value
pub fn TValue::table(value : Table) -> TValue {
  TValue::Table(value)
}

///|
/// Get the type tag of a value
pub fn TValue::type_of(self : TValue) -> LuaType {
  match self {
    Nil => LuaType::Nil
    Boolean(_) => LuaType::Boolean
    Integer(_) | Number(_) => LuaType::Number
    String(_) => LuaType::String
    Function(_) | NativeFunction(_) => LuaType::Function
    Table(_) => LuaType::Table
  }
}

///|
/// Check if value is nil
pub fn TValue::is_nil(self : TValue) -> Bool {
  match self {
    Nil => true
    _ => false
  }
}

///|
/// Check if value is a boolean
pub fn TValue::is_boolean(self : TValue) -> Bool {
  match self {
    Boolean(_) => true
    _ => false
  }
}

///|
/// Check if value is a number (int or float)
pub fn TValue::is_number(self : TValue) -> Bool {
  match self {
    Integer(_) | Number(_) => true
    _ => false
  }
}

///|
/// Check if value is an integer
pub fn TValue::is_integer(self : TValue) -> Bool {
  match self {
    Integer(_) => true
    _ => false
  }
}

///|
/// Check if value is a string
pub fn TValue::is_string(self : TValue) -> Bool {
  match self {
    String(_) => true
    _ => false
  }
}

///|
/// Check if value is a table
pub fn TValue::is_table(self : TValue) -> Bool {
  match self {
    Table(_) => true
    _ => false
  }
}

///|
/// Convert value to boolean (Lua semantics: nil and false are falsy)
pub fn TValue::to_boolean(self : TValue) -> Bool {
  match self {
    Nil => false
    Boolean(b) => b
    _ => true // In Lua, everything except nil and false is truthy
  }
}

///|
/// Try to extract integer value
pub fn TValue::to_integer(self : TValue) -> Int64 raise ValueError {
  match self {
    Integer(i) => i
    Number(n) => {
      // Convert float to int if it's a whole number
      let i = n.to_int64()
      if i.to_double() == n {
        i
      } else {
        raise ValueError::InvalidConversion(
          from=self.type_of(),
          to=LuaType::Number,
        )
      }
    }
    _ =>
      raise ValueError::TypeMismatch(
        expected=LuaType::Number,
        actual=self.type_of(),
      )
  }
}

///|
/// Try to parse a string as a number (for implicit conversion)
fn try_parse_number(s : String) -> Double? {
  // Trim whitespace
  let trimmed = s.trim()
  if trimmed.is_empty() {
    return None
  }

  // Check for hex format
  if trimmed.has_prefix("0x") || trimmed.has_prefix("0X") {
    // Parse as hex integer
    let hex_str = try {
      trimmed[2:].to_string()
    } catch {
      _ => return None
    }
    let mut result : Int64 = 0
    for c in hex_str {
      let digit = if c >= '0' && c <= '9' {
        c.to_int() - '0'.to_int()
      } else if c >= 'a' && c <= 'f' {
        c.to_int() - 'a'.to_int() + 10
      } else if c >= 'A' && c <= 'F' {
        c.to_int() - 'A'.to_int() + 10
      } else {
        return None  // Invalid hex digit
      }
      result = result * 16 + digit.to_int64()
    }
    return Some(result.to_double())
  }

  // Parse as decimal number using standard library
  try {
    Some(@strconv.parse_double!(trimmed))
  } catch {
    _ => None
  }
}

///|
/// Try to extract float value
pub fn TValue::to_number(self : TValue) -> Double raise ValueError {
  match self {
    Integer(i) => i.to_double()
    Number(n) => n
    String(s) => {
      // Try to parse string as number (implicit conversion)
      // Convert to string and parse
      match try_parse_number(s) {
        Some(num) => num
        None =>
          raise ValueError::TypeMismatch(
            expected=LuaType::Number,
            actual=self.type_of(),
          )
      }
    }
    _ =>
      raise ValueError::TypeMismatch(
        expected=LuaType::Number,
        actual=self.type_of(),
      )
  }
}

///|
/// Compare two values for equality (Lua semantics)
pub fn TValue::equal(self : TValue, other : TValue) -> Bool {
  match (self, other) {
    (Nil, Nil) => true
    (Boolean(a), Boolean(b)) => a == b
    (Integer(a), Integer(b)) => a == b
    (Number(a), Number(b)) => a == b
    // Integer and Number can be equal if they represent the same value
    (Integer(a), Number(b)) | (Number(b), Integer(a)) => a.to_double() == b
    (String(a), String(b)) => a == b
    // Tables are compared by reference (identity) using unique ID
    (Table(a), Table(b)) => a.id == b.id
    _ => false
  }
}

///|
/// Compare two values (less than, for numbers)
pub fn TValue::less_than(
  self : TValue,
  other : TValue,
) -> Bool raise ValueError {
  match (self, other) {
    (Integer(a), Integer(b)) => a < b
    (Number(a), Number(b)) => a < b
    (Integer(a), Number(b)) => a.to_double() < b
    (Number(a), Integer(b)) => a < b.to_double()
    (String(a), String(b)) => a < b
    _ =>
      raise ValueError::InvalidConversion(
        from=self.type_of(),
        to=LuaType::Number,
      )
  }
}

///|
/// Compare two values (less than or equal)
pub fn TValue::less_equal(
  self : TValue,
  other : TValue,
) -> Bool raise ValueError {
  match (self, other) {
    (Integer(a), Integer(b)) => a <= b
    (Number(a), Number(b)) => a <= b
    (Integer(a), Number(b)) => a.to_double() <= b
    (Number(a), Integer(b)) => a <= b.to_double()
    (String(a), String(b)) => a <= b
    _ =>
      raise ValueError::InvalidConversion(
        from=self.type_of(),
        to=LuaType::Number,
      )
  }
}

///|
/// Convert value to string (Lua semantics)
pub fn TValue::to_string(self : TValue) -> String {
  match self {
    Nil => "nil"
    Boolean(b) => b.to_string()
    Integer(i) => i.to_string()
    Number(n) => n.to_string()
    String(s) => s
    Function(_) | NativeFunction(_) => "function"
    Table(_) => "table"
  }
}
