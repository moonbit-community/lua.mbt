// Lua Proto (Function Prototype) Implementation
// Based on Lua 5.4's Proto structure
// Represents the compile-time representation of a function

///|
/// Upvalue descriptor (information about captured variables)
pub struct UpvalueDesc {
  in_stack : Bool  // true = capture from parent's local, false = from parent's upvalue
  index : Int      // index in parent's locals or upvalues array
  name : String    // variable name (for debugging)
} derive(Show)

///|
/// Create a new upvalue descriptor
pub fn UpvalueDesc::new(in_stack : Bool, index : Int, name : String) -> UpvalueDesc {
  UpvalueDesc::{ in_stack, index, name }
}

///|
/// Function prototype containing bytecode and constants
/// Generic over constant type T to avoid circular dependencies
pub struct Proto[T] {
  code : Array[@opcodes.Instruction]
  constants : Array[T]
  protos : Array[Proto[T]] // Nested function prototypes
  upvalue_count : Int   // Number of upvalues this function captures
  upvalue_descs : Array[UpvalueDesc]  // Descriptors for capturing upvalues
  param_count : Int     // Number of parameters this function expects
  is_vararg : Bool      // Whether this function accepts varargs
} derive(Show)

///|
/// Create a new function prototype
pub fn[T] Proto::new(
  code : Array[@opcodes.Instruction],
  constants : Array[T],
  protos : Array[Proto[T]],
  param_count : Int,
  is_vararg : Bool,
) -> Proto[T] {
  Proto::{ code, constants, protos, upvalue_count: 0, upvalue_descs: [], param_count, is_vararg }
}

///|
/// Create a new function prototype with upvalue count
pub fn[T] Proto::new_with_upvalues(
  code : Array[@opcodes.Instruction],
  constants : Array[T],
  protos : Array[Proto[T]],
  upvalue_count : Int,
  upvalue_descs : Array[UpvalueDesc],
  param_count : Int,
  is_vararg : Bool,
) -> Proto[T] {
  Proto::{ code, constants, protos, upvalue_count, upvalue_descs, param_count, is_vararg }
}

///|
/// Get code array
pub fn[T] Proto::code(self : Proto[T]) -> Array[@opcodes.Instruction] {
  self.code
}

///|
/// Get constant at index
pub fn[T] Proto::constant(self : Proto[T], index : Int) -> T {
  self.constants[index]
}

///|
/// Get all constants
pub fn[T] Proto::constants(self : Proto[T]) -> Array[T] {
  self.constants
}

///|
/// Get nested proto at index
pub fn[T] Proto::proto(self : Proto[T], index : Int) -> Proto[T] {
  self.protos[index]
}
