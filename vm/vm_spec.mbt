// Lua VM Execution Specification
// Based on Lua 5.4's lvm.h
// Executes bytecode instructions

///|
/// VM execution errors
pub(all) suberror VMError {
  InvalidOpcode(op~ : Int)
  DivisionByZero
  InvalidOperation(message~ : String)
  RuntimeError(message~ : String)
} derive(Eq, Show, ToJson)

///|
/// Function prototype containing bytecode and constants
#declaration_only
pub type Proto

///|
/// Create a new function prototype
#declaration_only
pub fn Proto::new(
  code : Array[@opcodes.Instruction],
  constants : Array[@value.TValue],
) -> Proto {
  ...
}

///|
/// Get code array
#declaration_only
pub fn Proto::code(self : Proto) -> Array[@opcodes.Instruction] {
  ...
}

///|
/// Get constant at index
#declaration_only
pub fn Proto::constant(self : Proto, index : Int) -> @value.TValue {
  ...
}

///|
/// Execute bytecode on a Lua state
#declaration_only
pub fn execute(state : @state.LuaState, proto : Proto) -> Unit raise VMError {
  ...
}

///|
/// Execute a single instruction
/// Returns Some(offset) for jump instructions, None for sequential execution
#declaration_only
pub fn execute_instruction(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  constants : Array[@value.TValue],
) -> Int? raise VMError {
  ...
}
