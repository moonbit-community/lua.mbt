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
/// Execution result - indicates what should happen after instruction
#declaration_only
pub type ExecutionResult

///|
/// Execute bytecode on a Lua state
/// Now supports function calls via call stack
#declaration_only
pub fn execute(state : @state.LuaState, proto : @proto.Proto[@value.TValue]) -> Unit raise VMError {
  ...
}

///|
/// Execute a single instruction
/// Returns ExecutionResult indicating next action
#declaration_only
pub fn execute_instruction(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  constants : Array[@value.TValue],
  base : Int,
) -> ExecutionResult raise VMError {
  ...
}
