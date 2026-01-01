// Lua VM Execution Implementation
// Based on Lua 5.4's lvm.c
// Register-based virtual machine

///|
/// Function prototype containing bytecode and constants
pub struct Proto {
  code : Array[@opcodes.Instruction]
  constants : Array[@value.TValue]
  protos : Array[Proto] // Nested function prototypes
} derive(Show)

///|
/// Create a new function prototype
pub fn Proto::new(
  code : Array[@opcodes.Instruction],
  constants : Array[@value.TValue],
  protos : Array[Proto],
) -> Proto {
  Proto::{ code, constants, protos }
}

///|
/// Get code array
pub fn Proto::code(self : Proto) -> Array[@opcodes.Instruction] {
  self.code
}

///|
/// Get constant at index
pub fn Proto::constant(self : Proto, index : Int) -> @value.TValue {
  self.constants[index]
}

///|
/// Get all constants
pub fn Proto::constants(self : Proto) -> Array[@value.TValue] {
  self.constants
}

///|
/// Get nested proto at index
pub fn Proto::proto(self : Proto, index : Int) -> Proto {
  self.protos[index]
}

///|
/// Execute bytecode on a Lua state
/// Now supports function calls via call stack
pub fn execute(state : @state.LuaState, proto : Proto) -> Unit raise VMError {
  // Convert proto to FunctionValue and push initial frame
  let func = @value.FunctionValue::new(proto.code, proto.constants)
  let base = state.stack_size()

  // Ensure we have enough stack space for registers
  let max_register = calculate_max_register(proto.code)
  while state.stack_size() <= base + max_register {
    state.push(@value.TValue::nil())
  }

  // Push initial call frame
  state.push_frame(func, base, 0) catch {
    _ => raise VMError::RuntimeError(message="Failed to push initial frame")
  }

  // Main execution loop - continue while there are active frames
  while state.call_depth() > 0 {
    let frame = state.current_frame() catch {
      _ => raise VMError::RuntimeError(message="No active frame")
    }

    // Check if we've finished executing this frame
    if frame.pc >= frame.func.code.length() {
      // Implicit return at end of function
      execute_return(state, 0, 0)
      continue
    }

    let instr = frame.func.code[frame.pc]
    let constants = frame.func.constants

    // Execute instruction and get result
    let result = execute_instruction(state, instr, constants, frame.base)

    // Update PC based on execution result
    match result {
      ExecutionResult::Continue =>
        state.update_pc(frame.pc + 1) catch {
          _ => raise VMError::RuntimeError(message="Failed to update PC")
        }
      ExecutionResult::Jump(offset) =>
        state.update_pc(frame.pc + 1 + offset) catch {
          _ => raise VMError::RuntimeError(message="Failed to update PC")
        }
      ExecutionResult::Call => {
        // Call pushed a new frame, which already has PC=0
        // No need to update PC - just continue with the new frame
        ()
      }
      ExecutionResult::Return => {
        // Return already popped frame, nothing to do
        ()
      }
    }
  }
}

///|
/// Execution result - indicates what should happen after instruction
enum ExecutionResult {
  Continue          // Normal sequential execution
  Jump(Int)         // Jump by offset
  Call              // Function call (frame already pushed)
  Return            // Function return (frame already popped)
} derive(Show)

///|
/// Calculate maximum register index used in code
fn calculate_max_register(code : Array[@opcodes.Instruction]) -> Int {
  let mut max = 0
  for instr in code {
    let a = instr.get_a()
    if a > max {
      max = a
    }
    // Check B and C for ABC instructions
    match @opcodes.op_mode(instr.get_opcode()) {
      @opcodes.OpMode::ABC => {
        let b = instr.get_b()
        let c = instr.get_c()
        if b > max {
          max = b
        }
        if c > max {
          max = c
        }
      }
      _ => ()
    }
  }
  max
}

///|
/// Execute a single instruction
/// Returns ExecutionResult indicating next action
pub fn execute_instruction(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  constants : Array[@value.TValue],
  base : Int,
) -> ExecutionResult raise VMError {
  let opcode = instr.get_opcode()
  match opcode {
    @opcodes.OpCode::Move => {
      // Move: R[A] := R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let value = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in MOVE")
      }
      state.set(base + a + 1, value) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in MOVE")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::LoadK => {
      // LoadK: R[A] := K[Bx]
      let a = instr.get_a()
      let bx = instr.get_bx()
      if bx < 0 || bx >= constants.length() {
        raise VMError::RuntimeError(message="Invalid constant index in LOADK")
      }
      let value = constants[bx]
      state.set(base + a + 1, value) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in LOADK")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::LoadFalse => {
      // LoadFalse: R[A] := false
      let a = instr.get_a()
      state.set(base + a + 1, @value.TValue::boolean(false)) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in LOADFALSE",
          )
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::LoadTrue => {
      // LoadTrue: R[A] := true
      let a = instr.get_a()
      state.set(base + a + 1, @value.TValue::boolean(true)) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in LOADTRUE",
          )
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::LoadNil => {
      // LoadNil: R[A] := nil
      let a = instr.get_a()
      state.set(base + a + 1, @value.TValue::nil()) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in LOADNIL",
          )
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Add => {
      // Add: R[A] := R[B] + R[C]
      execute_binary_arith(state, instr, base, fn(a, b) { a + b }, "ADD")
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Sub => {
      // Sub: R[A] := R[B] - R[C]
      execute_binary_arith(state, instr, base, fn(a, b) { a - b }, "SUB")
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Mul => {
      // Mul: R[A] := R[B] * R[C]
      execute_binary_arith(state, instr, base, fn(a, b) { a * b }, "MUL")
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Div => {
      // Div: R[A] := R[B] / R[C]
      // Division by zero returns inf/-inf (IEEE 754 semantics)
      execute_binary_arith(
        state,
        instr,
        base,
        fn(a, b) { a / b },
        "DIV",
      )
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Idiv => {
      // Idiv: R[A] := R[B] // R[C] (floor division)
      // Division by zero returns inf/-inf (IEEE 754 semantics)
      execute_binary_arith(
        state,
        instr,
        base,
        fn(a, b) { (a / b).floor() },
        "IDIV",
      )
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Mod => {
      // Mod: R[A] := R[B] % R[C]
      execute_binary_arith(
        state,
        instr,
        base,
        fn(a, b) {
          if b == 0.0 {
            raise VMError::DivisionByZero
          }
          a % b
        },
        "MOD",
      )
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Pow => {
      // Pow: R[A] := R[B] ^ R[C]
      execute_binary_arith(state, instr, base, fn(a, b) { a.pow(b) }, "POW")
      ExecutionResult::Continue
    }
    @opcodes.OpCode::BAnd => {
      // BAnd: R[A] := R[B] & R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BAND")
      }
      let val_c = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BAND")
      }
      let num_b_double = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BAND requires number")
      }
      let num_c_double = val_c.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BAND requires number")
      }
      let num_b = num_b_double.to_int64()
      let num_c = num_c_double.to_int64()
      let result = num_b.land(num_c)
      state.set(base + a + 1, @value.TValue::number(result.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in BAND")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::BOr => {
      // BOr: R[A] := R[B] | R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BOR")
      }
      let val_c = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BOR")
      }
      let num_b_double = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BOR requires number")
      }
      let num_c_double = val_c.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BOR requires number")
      }
      let num_b = num_b_double.to_int64()
      let num_c = num_c_double.to_int64()
      let result = num_b.lor(num_c)
      state.set(base + a + 1, @value.TValue::number(result.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in BOR")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::BXor => {
      // BXor: R[A] := R[B] ~ R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BXOR")
      }
      let val_c = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BXOR")
      }
      let num_b_double = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BXOR requires number")
      }
      let num_c_double = val_c.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BXOR requires number")
      }
      let num_b = num_b_double.to_int64()
      let num_c = num_c_double.to_int64()
      let result = num_b.lxor(num_c)
      state.set(base + a + 1, @value.TValue::number(result.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in BXOR")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::BNot => {
      // BNot: R[A] := ~R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in BNOT")
      }
      let num_b_double = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="BNOT requires number")
      }
      let num_b = num_b_double.to_int64()
      let result = num_b.lnot()
      state.set(base + a + 1, @value.TValue::number(result.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in BNOT")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Shl => {
      // Shl: R[A] := R[B] << R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SHL")
      }
      let val_c = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SHL")
      }
      let num_b_double = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="SHL requires number")
      }
      let num_c_double = val_c.to_number() catch {
        _ => raise VMError::InvalidOperation(message="SHL requires number")
      }
      let num_b = num_b_double.to_int64()
      let num_c = num_c_double.to_int()
      let result = num_b.lsl(num_c)
      state.set(base + a + 1, @value.TValue::number(result.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in SHL")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Shr => {
      // Shr: R[A] := R[B] >> R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SHR")
      }
      let val_c = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SHR")
      }
      let num_b_double = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="SHR requires number")
      }
      let num_c_double = val_c.to_number() catch {
        _ => raise VMError::InvalidOperation(message="SHR requires number")
      }
      let num_b = num_b_double.to_int64()
      let num_c = num_c_double.to_int()
      let result = num_b.lsr(num_c)
      state.set(base + a + 1, @value.TValue::number(result.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in SHR")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Unm => {
      // Unm: R[A] := -R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in UNM")
      }
      let num = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="UNM requires number")
      }
      state.set(base + a + 1, @value.TValue::number(-num)) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in UNM")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Concat => {
      // Concat: R[A] := R[B].. ... ..R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()

      // Concatenate all values from R[B] to R[C]
      let mut result = ""
      for i = b; i <= c; i = i + 1 {
        let val = state.get(base + i + 1) catch {
          _ =>
            raise VMError::RuntimeError(message="Invalid register access in CONCAT")
        }
        result = result + val.to_string()
      }

      state.set(base + a + 1, @value.TValue::string(result)) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in CONCAT")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Len => {
      // Len: R[A] := #R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in LEN")
      }

      // Get length based on type
      let length = match val_b {
        @value.TValue::String(s) => s.length()
        @value.TValue::Table(t) => t.length()
        _ => raise VMError::RuntimeError(message="attempt to get length of a \{val_b.type_of()} value")
      }

      state.set(base + a + 1, @value.TValue::number(length.to_double())) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in LEN")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Not => {
      // Not: R[A] := not R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in NOT")
      }
      let result = !val_b.to_boolean()
      state.set(base + a + 1, @value.TValue::boolean(result)) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in NOT")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Test => {
      // Test: if (not R[A]) != k then PC++
      // If k=false: skip if R[A] is truthy
      // If k=true: skip if R[A] is falsy
      let a = instr.get_a()
      let k = instr.get_k()
      let val_a = state.get(base + a + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in TEST")
      }
      let is_truthy = val_a.to_boolean()
      let should_skip = if k { !is_truthy } else { is_truthy }
      if should_skip {
        ExecutionResult::Jump(1)  // Skip next instruction
      } else {
        ExecutionResult::Continue
      }
    }
    @opcodes.OpCode::Eq => {
      // Eq: if (R[B] == R[C]) ~= k then PC++
      let should_skip = execute_comparison(
        state,
        instr,
        base,
        fn(a, b) { a.equal(b) },
        "EQ",
      )
      if should_skip {
        ExecutionResult::Jump(1)  // Skip next instruction
      } else {
        ExecutionResult::Continue
      }
    }
    @opcodes.OpCode::Lt => {
      // Lt: if (R[B] < R[C]) ~= k then PC++
      let should_skip = execute_comparison(
        state,
        instr,
        base,
        fn(a, b) {
          a.less_than(b) catch {
            _ => raise VMError::InvalidOperation(message="LT comparison failed")
          }
        },
        "LT",
      )
      if should_skip {
        ExecutionResult::Jump(1)  // Skip next instruction
      } else {
        ExecutionResult::Continue
      }
    }
    @opcodes.OpCode::Le => {
      // Le: if (R[B] <= R[C]) ~= k then PC++
      let b_reg = instr.get_b()
      let c_reg = instr.get_c()
      let should_skip = execute_comparison(
        state,
        instr,
        base,
        fn(a, b) {
          a.less_equal(b) catch {
            _ => {
              let a_str = a.to_string()
              let b_str = b.to_string()
              raise VMError::InvalidOperation(
                message="LE comparison failed: \{a_str} <= \{b_str} (regs \{b_reg} and \{c_reg}, base \{base})",
              )
            }
          }
        },
        "LE",
      )
      if should_skip {
        ExecutionResult::Jump(1)  // Skip next instruction
      } else {
        ExecutionResult::Continue
      }
    }
    @opcodes.OpCode::Jmp => {
      // Jmp: PC += sBx
      let sbx = instr.get_sbx()
      ExecutionResult::Jump(sbx)
    }
    @opcodes.OpCode::Call => {
      // Call: R[A](R[A+1], ..., R[A+B])
      execute_call(state, instr, base)
    }
    @opcodes.OpCode::Return => {
      // Return: return R[A], ..., R[A+B-1]
      let a = instr.get_a()
      let b = instr.get_b()
      execute_return(state, base + a, b)
      ExecutionResult::Return
    }
    @opcodes.OpCode::NewTable => {
      // NewTable: R[A] := {} (create new empty table)
      let a = instr.get_a()
      let table = @value.Table::new()
      state.set(base + a + 1, @value.TValue::table(table)) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in NEWTABLE",
          )
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::GetTable => {
      // GetTable: R[A] := R[B][R[C]]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()

      let table_val = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in GETTABLE")
      }

      let key_val = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in GETTABLE")
      }

      let result = match table_val {
        @value.TValue::Table(table) => table.get(key_val)
        _ =>
          raise VMError::InvalidOperation(
            message="Attempt to index non-table value",
          )
      }

      state.set(base + a + 1, result) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in GETTABLE")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::SetTable => {
      // SetTable: R[A][R[B]] := R[C]
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()

      let table_val = state.get(base + a + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SETTABLE")
      }

      let key_val = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SETTABLE")
      }

      let value_val = state.get(base + c + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SETTABLE")
      }

      match table_val {
        @value.TValue::Table(table) => table.set(key_val, value_val)
        _ =>
          raise VMError::InvalidOperation(
            message="Attempt to index non-table value",
          )
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::GetGlobal => {
      // GetGlobal: R[A] := Globals[K[Bx]]
      let a = instr.get_a()
      let bx = instr.get_bx()

      // Get global name from constants
      if bx < 0 || bx >= constants.length() {
        raise VMError::RuntimeError(message="Invalid constant index in GETGLOBAL")
      }

      let name = match constants[bx] {
        @value.TValue::String(s) => s
        _ => raise VMError::RuntimeError(message="GETGLOBAL requires string constant")
      }

      // Get value from globals (returns nil for undefined globals)
      let value = state.get_global(name) catch {
        err => raise VMError::RuntimeError(message="Unexpected error getting global '\{name}': \{err}")
      }
      state.set(base + a + 1, value) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in GETGLOBAL")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::SetGlobal => {
      // SetGlobal: Globals[K[Bx]] := R[A]
      let a = instr.get_a()
      let bx = instr.get_bx()

      // Get global name from constants
      if bx < 0 || bx >= constants.length() {
        raise VMError::RuntimeError(message="Invalid constant index in SETGLOBAL")
      }

      let name = match constants[bx] {
        @value.TValue::String(s) => s
        _ => raise VMError::RuntimeError(message="SETGLOBAL requires string constant")
      }

      // Get value from register
      let value = state.get(base + a + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SETGLOBAL")
      }

      // Set global
      state.set_global(name, value)
      ExecutionResult::Continue
    }
    _ => raise VMError::InvalidOpcode(op=@opcodes.opcode_to_int(opcode))
  }
}

///|
/// Helper: Execute binary arithmetic operation
fn execute_binary_arith(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  base : Int,
  op : (Double, Double) -> Double raise VMError,
  name : String,
) -> Unit raise VMError {
  let a = instr.get_a()
  let b = instr.get_b()
  let c = instr.get_c()
  let val_b = state.get(base + b + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (B)",
      )
  }
  let val_c = state.get(base + c + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (C)",
      )
  }
  let num_b = val_b.to_number() catch {
    _ => raise VMError::InvalidOperation(message="\{name} requires numbers")
  }
  let num_c = val_c.to_number() catch {
    _ => raise VMError::InvalidOperation(message="\{name} requires numbers")
  }
  let result = op(num_b, num_c)

  // Check if result can be represented as integer
  let result_val = if result == result.to_int64().to_double() {
    @value.TValue::integer(result.to_int64())
  } else {
    @value.TValue::number(result)
  }
  state.set(base + a + 1, result_val) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register write in \{name} (A)",
      )
  }
}

///|
/// Helper: Execute comparison operation
/// Returns true if the next instruction should be skipped
fn execute_comparison(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  base : Int,
  op : (@value.TValue, @value.TValue) -> Bool raise VMError,
  name : String,
) -> Bool raise VMError {
  let b = instr.get_b()
  let c = instr.get_c()
  let k = instr.get_k()
  let val_b = state.get(base + b + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (B)",
      )
  }
  let val_c = state.get(base + c + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (C)",
      )
  }

  // Evaluate comparison and check against k flag
  let comparison_result = op(val_b, val_c)
  // Skip next instruction if (comparison_result ~= k), per Lua semantics
  comparison_result != k
}

///|
/// Execute a native function call
fn execute_native_call(
  state : @state.LuaState,
  func_name : String,
  a : Int,
  b : Int,
  _c : Int,
  base : Int,
) -> Unit raise VMError {
  // Collect arguments from stack starting at R[A+1]
  // b-1 is the number of arguments (b=1 means 0 args, b=2 means 1 arg, etc.)
  let nargs = if b == 0 {
    // Variable number of arguments - use all values from R[A+1] to top
    state.stack_size() - (base + a + 2)
  } else {
    b - 1
  }

  let args : Array[@value.TValue] = []
  for i = 0; i < nargs; i = i + 1 {
    // Arguments start at R[A+1], which is base + a + 1 + 1 (since function is at base + a + 1)
    let arg = state.get(base + a + 2 + i) catch {
      _ => @value.TValue::nil()
    }
    args.push(arg)
  }

  // Call the native function by name
  let results = call_native_function(state, func_name, args)

  // Store results starting at R[A]
  for i = 0; i < results.length(); i = i + 1 {
    state.set(base + a + 1 + i, results[i]) catch {
      _ => ()  // Ignore set errors for now
    }
  }
}

///|
/// Call a native function by name
fn call_native_function(
  state : @state.LuaState,
  name : String,
  args : Array[@value.TValue],
) -> Array[@value.TValue] raise VMError {
  match name {
    "print" => {
      @stdlib.print(args)
      []  // print returns no values
    }
    "type" => {
      let arg = if args.length() > 0 { args[0] } else { @value.TValue::nil() }
      let type_name = @stdlib.type_(arg)
      [@value.TValue::string(type_name)]
    }
    "tostring" => {
      let arg = if args.length() > 0 { args[0] } else { @value.TValue::nil() }
      let str = @stdlib.tostring(arg)
      [@value.TValue::string(str)]
    }
    "tonumber" => {
      let arg = if args.length() > 0 { args[0] } else { @value.TValue::nil() }
      try {
        let num = @stdlib.tonumber(arg)
        [num]
      } catch {
        _ => [@value.TValue::nil()]
      }
    }
    "assert" => {
      let condition = if args.length() > 0 { args[0] } else { @value.TValue::nil() }
      let message = if args.length() > 1 {
        match args[1] {
          @value.TValue::String(s) => Some(s)
          _ => None
        }
      } else {
        None
      }
      try {
        let result = @stdlib.assert_(condition, message?)
        [result]
      } catch {
        err => raise VMError::RuntimeError(message=err.to_string())
      }
    }
    "error" => {
      // error(message, [level])
      // Raises a Lua error with the given message
      // level parameter is ignored for now (used for error reporting depth)
      let message = if args.length() > 0 {
        match args[0] {
          @value.TValue::String(s) => s
          @value.TValue::Nil => "error"
          _ => args[0].to_string()
        }
      } else {
        "error"
      }
      raise VMError::RuntimeError(message=message)
    }
    // Raw table access functions (bypass metatables)
    "rawget" => {
      // rawget(table, index) - Get table element without invoking metamethods
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="rawget requires 2 arguments")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="rawget requires a table")
      }
      let key = args[1]
      [table.get(key)]
    }
    "rawset" => {
      // rawset(table, index, value) - Set table element without invoking metamethods
      if args.length() < 3 {
        raise VMError::InvalidOperation(message="rawset requires 3 arguments")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="rawset requires a table")
      }
      let key = args[1]
      let value = args[2]
      table.set(key, value)
      [args[0]]  // Returns the table
    }
    "rawequal" => {
      // rawequal(v1, v2) - Check equality without invoking metamethods
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="rawequal requires 2 arguments")
      }
      let v1 = args[0]
      let v2 = args[1]
      [@value.TValue::boolean(v1.equal(v2))]
    }
    "rawlen" => {
      // rawlen(v) - Get length without invoking metamethods
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="rawlen requires an argument")
      }
      let length = match args[0] {
        @value.TValue::String(s) => s.length()
        @value.TValue::Table(t) => t.length()
        _ => raise VMError::InvalidOperation(message="rawlen requires string or table")
      }
      [@value.TValue::number(length.to_double())]
    }
    // Math library functions
    "math.abs" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="abs requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="abs requires a number")
      }
      let result = if arg < 0.0 { -arg } else { arg }
      [@value.TValue::number(result)]
    }
    "math.floor" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="floor requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="floor requires a number")
      }
      [@value.TValue::number(@math.floor(arg))]
    }
    "math.ceil" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="ceil requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="ceil requires a number")
      }
      [@value.TValue::number(@math.ceil(arg))]
    }
    "math.min" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="min requires at least one argument")
      }
      let mut min_val = try {
        args[0].to_number()
      } catch {
        _ => raise VMError::InvalidOperation(message="min requires numbers")
      }
      for i = 1; i < args.length(); i = i + 1 {
        let val = try {
          args[i].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="min requires numbers")
        }
        if val < min_val {
          min_val = val
        }
      }
      [@value.TValue::number(min_val)]
    }
    "math.max" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="max requires at least one argument")
      }
      let mut max_val = try {
        args[0].to_number()
      } catch {
        _ => raise VMError::InvalidOperation(message="max requires numbers")
      }
      for i = 1; i < args.length(); i = i + 1 {
        let val = try {
          args[i].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="max requires numbers")
        }
        if val > max_val {
          max_val = val
        }
      }
      [@value.TValue::number(max_val)]
    }
    "math.sqrt" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="sqrt requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="sqrt requires a number")
      }
      [@value.TValue::number(@math.pow(arg, 0.5))]
    }
    "math.sin" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="sin requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="sin requires a number")
      }
      [@value.TValue::number(@math.sin(arg))]
    }
    "math.cos" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="cos requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="cos requires a number")
      }
      [@value.TValue::number(@math.cos(arg))]
    }
    "math.tan" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="tan requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="tan requires a number")
      }
      [@value.TValue::number(@math.tan(arg))]
    }
    "math.asin" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="asin requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="asin requires a number")
      }
      [@value.TValue::number(@math.asin(arg))]
    }
    "math.acos" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="acos requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="acos requires a number")
      }
      [@value.TValue::number(@math.acos(arg))]
    }
    "math.atan" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="atan requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="atan requires a number")
      }
      [@value.TValue::number(@math.atan(arg))]
    }
    "math.exp" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="exp requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="exp requires a number")
      }
      [@value.TValue::number(@math.exp(arg))]
    }
    "math.log" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="log requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="log requires a number")
      }
      [@value.TValue::number(@math.ln(arg))]
    }
    "math.deg" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="deg requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="deg requires a number")
      }
      let degrees = arg * (180.0 / 3.14159265358979323846)
      [@value.TValue::number(degrees)]
    }
    "math.rad" => {
      let arg = if args.length() > 0 {
        try {
          args[0].to_number()
        } catch {
          _ => raise VMError::InvalidOperation(message="rad requires a number")
        }
      } else {
        raise VMError::InvalidOperation(message="rad requires a number")
      }
      let radians = arg * (3.14159265358979323846 / 180.0)
      [@value.TValue::number(radians)]
    }
    // Table library functions
    "table.insert" => {
      // table.insert(table, [pos,] value)
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="table.insert requires a table argument")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="table.insert requires a table")
      }

      if args.length() == 2 {
        // table.insert(table, value) - append to end
        let value = args[1]
        let len = table.length()
        table.set_int(len + 1, value)
      } else if args.length() >= 3 {
        // table.insert(table, pos, value) - insert at position
        let pos = try {
          args[1].to_integer()
        } catch {
          _ => raise VMError::InvalidOperation(message="table.insert position must be a number")
        }
        let value = args[2]

        // Shift elements from pos onwards to the right
        let len = table.length()
        for i = len; i >= pos.to_int(); i = i - 1 {
          let val = table.get_int(i)
          table.set_int(i + 1, val)
        }
        // Insert the new value
        table.set_int(pos.to_int(), value)
      } else {
        raise VMError::InvalidOperation(message="table.insert requires at least 2 arguments")
      }
      []  // Returns nothing
    }
    "table.remove" => {
      // table.remove(table, [pos])
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="table.remove requires a table argument")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="table.remove requires a table")
      }

      let pos = if args.length() >= 2 {
        try {
          args[1].to_integer().to_int()
        } catch {
          _ => raise VMError::InvalidOperation(message="table.remove position must be a number")
        }
      } else {
        // Default: remove last element
        table.length()
      }

      let removed = table.get_int(pos)

      // Shift elements from pos+1 onwards to the left
      let len = table.length()
      for i = pos; i < len; i = i + 1 {
        let val = table.get_int(i + 1)
        table.set_int(i, val)
      }
      // Clear the last element
      table.set_int(len, @value.TValue::nil())

      [removed]
    }
    "table.concat" => {
      // table.concat(table, [sep, [i, [j]]])
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="table.concat requires a table argument")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="table.concat requires a table")
      }

      let sep = if args.length() >= 2 {
        match args[1] {
          @value.TValue::String(s) => s
          _ => ""
        }
      } else {
        ""
      }

      let start = if args.length() >= 3 {
        try {
          args[2].to_integer().to_int()
        } catch {
          _ => 1
        }
      } else {
        1
      }

      let end = if args.length() >= 4 {
        try {
          args[3].to_integer().to_int()
        } catch {
          _ => table.length()
        }
      } else {
        table.length()
      }

      let result = StringBuilder::new()
      for i = start; i <= end; i = i + 1 {
        if i > start {
          result.write_string(sep)
        }
        let val = table.get_int(i)
        result.write_string(val.to_string())
      }
      [@value.TValue::string(result.to_string())]
    }
    "table.sort" => {
      // table.sort(table, [comp]) - we'll implement simple ascending sort for now
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="table.sort requires a table argument")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="table.sort requires a table")
      }

      // Simple bubble sort implementation
      let len = table.length()
      for i = 1; i <= len; i = i + 1 {
        for j = 1; j < len; j = j + 1 {
          let a = table.get_int(j)
          let b = table.get_int(j + 1)

          // Compare values (numbers or strings)
          let should_swap = try {
            b.less_than(a)
          } catch {
            _ => false
          }

          if should_swap {
            table.set_int(j, b)
            table.set_int(j + 1, a)
          }
        }
      }
      []  // Returns nothing
    }
    "table.pack" => {
      // table.pack(...) - returns table with all arguments and field 'n'
      let result = @value.Table::new()
      for i = 0; i < args.length(); i = i + 1 {
        result.set_int(i + 1, args[i])
      }
      result.set_string("n", @value.TValue::integer(args.length().to_int64()))
      [@value.TValue::table(result)]
    }
    "table.unpack" => {
      // table.unpack(table, [i, [j]])
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="table.unpack requires a table argument")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="table.unpack requires a table")
      }

      let start = if args.length() >= 2 {
        try {
          args[1].to_integer().to_int()
        } catch {
          _ => 1
        }
      } else {
        1
      }

      let end = if args.length() >= 3 {
        try {
          args[2].to_integer().to_int()
        } catch {
          _ => table.length()
        }
      } else {
        table.length()
      }

      let result = Array::new()
      for i = start; i <= end; i = i + 1 {
        result.push(table.get_int(i))
      }
      result
    }
    // String library functions
    "string.len" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="string.len requires a string argument")
      }
      let s = match args[0] {
        @value.TValue::String(str) => str
        _ => raise VMError::InvalidOperation(message="string.len requires a string")
      }
      [@value.TValue::number(s.length().to_double())]
    }
    "string.sub" => {
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="string.sub requires at least 2 arguments")
      }
      let s = match args[0] {
        @value.TValue::String(str) => str
        _ => raise VMError::InvalidOperation(message="string.sub requires a string")
      }
      let i = try {
        args[1].to_integer().to_int()
      } catch {
        _ => raise VMError::InvalidOperation(message="string.sub index must be a number")
      }

      // Call stdlib function with or without j parameter
      let result = if args.length() >= 3 {
        let j = try {
          args[2].to_integer().to_int()
        } catch {
          _ => raise VMError::InvalidOperation(message="string.sub index must be a number")
        }
        try {
          @stdlib.string_sub(args[0], i, j=j)
        } catch {
          err => raise VMError::RuntimeError(message="string.sub failed: \{err}")
        }
      } else {
        try {
          @stdlib.string_sub(args[0], i)
        } catch {
          err => raise VMError::RuntimeError(message="string.sub failed: \{err}")
        }
      }
      [@value.TValue::string(result)]
    }
    "string.upper" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="string.upper requires a string argument")
      }
      let result = try {
        @stdlib.string_upper(args[0])
      } catch {
        err => raise VMError::RuntimeError(message="string.upper failed: \{err}")
      }
      [@value.TValue::string(result)]
    }
    "string.lower" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="string.lower requires a string argument")
      }
      let result = try {
        @stdlib.string_lower(args[0])
      } catch {
        err => raise VMError::RuntimeError(message="string.lower failed: \{err}")
      }
      [@value.TValue::string(result)]
    }
    "string.find" => {
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="string.find requires at least 2 arguments")
      }

      let (start, end) = if args.length() >= 3 {
        let init = try {
          args[2].to_integer().to_int()
        } catch {
          _ => raise VMError::InvalidOperation(message="string.find init must be a number")
        }
        try {
          @stdlib.string_find(args[0], args[1], init=init)
        } catch {
          err => raise VMError::RuntimeError(message="string.find failed: \{err}")
        }
      } else {
        try {
          @stdlib.string_find(args[0], args[1])
        } catch {
          err => raise VMError::RuntimeError(message="string.find failed: \{err}")
        }
      }

      if start == 0 {
        // Not found - return nil
        [@value.TValue::nil()]
      } else {
        // Found - return start and end positions
        [@value.TValue::integer(start.to_int64()), @value.TValue::integer(end.to_int64())]
      }
    }
    "string.gsub" => {
      if args.length() < 3 {
        raise VMError::InvalidOperation(message="string.gsub requires 3 arguments")
      }
      let (result, count) = try {
        @stdlib.string_gsub(args[0], args[1], args[2])
      } catch {
        err => raise VMError::RuntimeError(message="string.gsub failed: \{err}")
      }
      [@value.TValue::string(result), @value.TValue::integer(count.to_int64())]
    }
    "string.format" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="string.format requires a format string")
      }
      // Collect all arguments after the format string
      let format_args : Array[@value.TValue] = []
      for i = 1; i < args.length(); i = i + 1 {
        format_args.push(args[i])
      }
      let result = try {
        @stdlib.string_format(args[0], format_args)
      } catch {
        err => raise VMError::RuntimeError(message="string.format failed: \{err}")
      }
      [@value.TValue::string(result)]
    }
    _ => {
      // Ignore set_global for now - it's used during initialization
      ignore(state)
      raise VMError::RuntimeError(message="Unknown native function: \{name}")
    }
  }
}

///|
/// Execute function call
/// CALL A B C: Call function at R[A] with B arguments, expecting C results
/// Returns ExecutionResult::Call for bytecode functions, Continue for native functions
fn execute_call(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  base : Int,
) -> ExecutionResult raise VMError {
  let a = instr.get_a()
  let b = instr.get_b()
  let c = instr.get_c()

  // Get function from register
  let func_val = state.get(base + a + 1) catch {
    _ => raise VMError::RuntimeError(message="Cannot access function register")
  }

  match func_val {
    // Bytecode function - push new call frame
    @value.TValue::Function(func) => {
      // IMPORTANT: Advance caller's PC before pushing new frame
      // Otherwise, when we return, we'll execute the CALL again (infinite loop)
      let caller_frame = state.current_frame() catch {
        _ => raise VMError::RuntimeError(message="No caller frame for PC update")
      }
      state.update_pc(caller_frame.pc + 1) catch {
        _ => raise VMError::RuntimeError(message="Failed to advance caller PC")
      }

      // New frame starts right after the function (at R[A+1])
      let new_base = base + a + 1

      // Ensure stack space for new frame
      let max_register = calculate_max_register(func.code)
      while state.stack_size() <= new_base + max_register {
        state.push(@value.TValue::nil())
      }

      // Initialize missing parameters to nil
      // B = arg_count + 1, so actual arg_count = b - 1
      let arg_count = b - 1
      let param_count = func.param_count
      // Arguments are at new_base + 0, ..., new_base + (arg_count - 1)
      // Missing parameters are from new_base + arg_count to new_base + (param_count - 1)
      for i = arg_count; i < param_count; i = i + 1 {
        state.set(new_base + i + 1, @value.TValue::nil()) catch {
          _ => ()  // Ignore errors
        }
      }

      // Push new call frame
      state.push_frame(func, new_base, c) catch {
        _ => raise VMError::RuntimeError(message="Failed to push call frame")
      }
      ExecutionResult::Call
    }
    // Native function - call directly
    @value.TValue::NativeFunction(nfunc) => {
      execute_native_call(state, nfunc.name, a, b, c, base)
      ExecutionResult::Continue  // Native function executed inline, just continue
    }
    _ =>
      raise VMError::InvalidOperation(
        message="Attempt to call non-function value",
      )
  }
}

///|
/// Execute function return
/// RETURN A B: Return B values starting at stack[start]
fn execute_return(
  state : @state.LuaState,
  start : Int,
  count : Int,
) -> Unit raise VMError {
  // Pop current frame
  let frame = state.pop_frame() catch {
    _ => raise VMError::RuntimeError(message="Cannot return from main")
  }

  // If this is the last frame, we're returning from main - just return
  if state.call_depth() == 0 {
    return
  }

  // Get caller frame to know where to put results
  let caller_frame = state.current_frame() catch {
    _ => raise VMError::RuntimeError(message="No caller frame")
  }

  // Copy return values to caller's expected location
  // frame.base is the callee's base, which points to the function position in caller
  // Results should be placed starting at the function position

  // In Lua, a function always returns at least one value
  // If count=0 (no explicit return values), return nil
  let actual_count = if count == 0 { 1 } else { count }

  for i = 0; i < actual_count; i = i + 1 {
    let val = if i < count {
      // Explicit return value exists
      state.get(start + i + 1) catch {
        _ => @value.TValue::nil()
      }
    } else {
      // No more return values, use nil
      @value.TValue::nil()
    }
    // Results are placed starting at the function position in caller
    state.set(frame.base + i, val) catch {
      _ =>
        raise VMError::RuntimeError(message="Failed to write return value")
    }
  }
}
