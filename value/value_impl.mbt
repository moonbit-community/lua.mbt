// Lua Value System Implementation
// Implementation of the tagged value system for Lua

///|
/// Tagged Value - internal representation
/// This enum holds the actual Lua values with their types
pub enum TValue {
  Nil
  Boolean(Bool)
  Integer(Int64)
  Number(Double)
  String(String)  // String support added
  // Table, Function, etc. will be added later
} derive(Eq, Show)

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
/// Get the type tag of a value
pub fn TValue::type_of(self : TValue) -> LuaType {
  match self {
    Nil => LuaType::Nil
    Boolean(_) => LuaType::Boolean
    Integer(_) | Number(_) => LuaType::Number
    String(_) => LuaType::String
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
  }
}
