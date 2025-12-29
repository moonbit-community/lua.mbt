// Lua Value System Specification
// This module defines the core tagged value system used throughout Lua.
// Based on Lua 5.4's lobject.h

///|
/// Lua basic types
pub(all) enum LuaType {
  Nil
  Boolean
  LightUserdata
  Number
  String
  Table
  Function
  Userdata
  Thread
} derive(Eq, Show, ToJson)

///|
/// Error types for value operations
pub(all) suberror ValueError {
  TypeMismatch(expected~ : LuaType, actual~ : LuaType)
  InvalidConversion(from~ : LuaType, to~ : LuaType)
  NilValue
} derive(Eq, Show, ToJson)

///|
/// Tagged Value - the fundamental value representation in Lua
/// Combines a value with its type tag
#declaration_only
pub type TValue

///|
/// Create a nil value
#declaration_only
pub fn TValue::nil() -> TValue {
  ...
}

///|
/// Create a boolean value
#declaration_only
pub fn TValue::boolean(value : Bool) -> TValue {
  ...
}

///|
/// Create an integer number value
#declaration_only
pub fn TValue::integer(value : Int64) -> TValue {
  ...
}

///|
/// Create a float number value
#declaration_only
pub fn TValue::number(value : Double) -> TValue {
  ...
}

///|
/// Get the type tag of a value
#declaration_only
pub fn TValue::type_of(self : TValue) -> LuaType {
  ...
}

///|
/// Check if value is nil
#declaration_only
pub fn TValue::is_nil(self : TValue) -> Bool {
  ...
}

///|
/// Check if value is a boolean
#declaration_only
pub fn TValue::is_boolean(self : TValue) -> Bool {
  ...
}

///|
/// Check if value is a number (int or float)
#declaration_only
pub fn TValue::is_number(self : TValue) -> Bool {
  ...
}

///|
/// Check if value is an integer
#declaration_only
pub fn TValue::is_integer(self : TValue) -> Bool {
  ...
}

///|
/// Try to convert value to boolean (Lua semantics: nil and false are falsy)
#declaration_only
pub fn TValue::to_boolean(self : TValue) -> Bool {
  ...
}

///|
/// Try to extract integer value
#declaration_only
pub fn TValue::to_integer(self : TValue) -> Int64 raise ValueError {
  ...
}

///|
/// Try to extract float value
#declaration_only
pub fn TValue::to_number(self : TValue) -> Double raise ValueError {
  ...
}

///|
/// Compare two values for equality (Lua semantics)
#declaration_only
pub fn TValue::equal(self : TValue, other : TValue) -> Bool {
  ...
}

///|
/// Compare two values (less than, for numbers and strings)
#declaration_only
pub fn TValue::less_than(
  self : TValue,
  other : TValue,
) -> Bool raise ValueError {
  ...
}

///|
/// Compare two values (less than or equal)
#declaration_only
pub fn TValue::less_equal(
  self : TValue,
  other : TValue,
) -> Bool raise ValueError {
  ...
}
