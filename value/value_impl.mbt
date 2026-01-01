// Lua Value System Implementation
// Implementation of the tagged value system for Lua

///|
/// Function reference - holds bytecode and constants
/// To avoid circular dependency, we duplicate Proto structure here
pub struct FunctionValue {
  code : Array[@opcodes.Instruction]
  constants : Array[TValue]
  upvalues : Array[TValue]
} derive(Show)

///|
/// Create a new function value
pub fn FunctionValue::new(
  code : Array[@opcodes.Instruction],
  constants : Array[TValue],
) -> FunctionValue {
  FunctionValue::{ code, constants, upvalues: [] }
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
/// Get table length (array part only)
pub fn Table::length(self : Table) -> Int {
  self.array.length()
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
/// Try to extract float value
pub fn TValue::to_number(self : TValue) -> Double raise ValueError {
  match self {
    Integer(i) => i.to_double()
    Number(n) => n
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
