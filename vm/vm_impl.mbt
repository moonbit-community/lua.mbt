// Lua VM Execution Implementation
// Based on Lua 5.4's lvm.c
// Register-based virtual machine

///|
/// Function prototype containing bytecode and constants
pub struct Proto {
  code : Array[@opcodes.Instruction]
  constants : Array[@value.TValue]
} derive(Show)

///|
/// Create a new function prototype
pub fn Proto::new(
  code : Array[@opcodes.Instruction],
  constants : Array[@value.TValue],
) -> Proto {
  Proto::{ code, constants }
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
/// Execute bytecode on a Lua state
pub fn execute(state : @state.LuaState, proto : Proto) -> Unit raise VMError {
  // Ensure we have enough stack space for registers
  // Initialize registers to nil if needed
  let max_register = calculate_max_register(proto.code)
  while state.stack_size() <= max_register {
    state.push(@value.TValue::nil())
  }

  // Execute each instruction in sequence
  for instr in proto.code {
    execute_instruction(state, instr, proto.constants)
  }
}

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
pub fn execute_instruction(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  constants : Array[@value.TValue],
) -> Unit raise VMError {
  let opcode = instr.get_opcode()
  match opcode {
    @opcodes.OpCode::Move => {
      // Move: R[A] := R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let value = state.get(b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in MOVE")
      }
      state.set(a + 1, value) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in MOVE")
      }
    }
    @opcodes.OpCode::LoadK => {
      // LoadK: R[A] := K[Bx]
      let a = instr.get_a()
      let bx = instr.get_bx()
      if bx < 0 || bx >= constants.length() {
        raise VMError::RuntimeError(message="Invalid constant index in LOADK")
      }
      let value = constants[bx]
      state.set(a + 1, value) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in LOADK")
      }
    }
    @opcodes.OpCode::LoadFalse => {
      // LoadFalse: R[A] := false
      let a = instr.get_a()
      state.set(a + 1, @value.TValue::boolean(false)) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in LOADFALSE",
          )
      }
    }
    @opcodes.OpCode::LoadTrue => {
      // LoadTrue: R[A] := true
      let a = instr.get_a()
      state.set(a + 1, @value.TValue::boolean(true)) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in LOADTRUE",
          )
      }
    }
    @opcodes.OpCode::LoadNil => {
      // LoadNil: R[A] := nil
      let a = instr.get_a()
      state.set(a + 1, @value.TValue::nil()) catch {
        _ =>
          raise VMError::RuntimeError(
            message="Invalid register write in LOADNIL",
          )
      }
    }
    @opcodes.OpCode::Add =>
      // Add: R[A] := R[B] + R[C]
      execute_binary_arith(state, instr, fn(a, b) { a + b }, "ADD")
    @opcodes.OpCode::Sub =>
      // Sub: R[A] := R[B] - R[C]
      execute_binary_arith(state, instr, fn(a, b) { a - b }, "SUB")
    @opcodes.OpCode::Mul =>
      // Mul: R[A] := R[B] * R[C]
      execute_binary_arith(state, instr, fn(a, b) { a * b }, "MUL")
    @opcodes.OpCode::Div =>
      // Div: R[A] := R[B] / R[C]
      execute_binary_arith(
        state,
        instr,
        fn(a, b) {
          if b == 0.0 {
            raise VMError::DivisionByZero
          }
          a / b
        },
        "DIV",
      )
    @opcodes.OpCode::Mod =>
      // Mod: R[A] := R[B] % R[C]
      execute_binary_arith(
        state,
        instr,
        fn(a, b) {
          if b == 0.0 {
            raise VMError::DivisionByZero
          }
          a % b
        },
        "MOD",
      )
    @opcodes.OpCode::Pow =>
      // Pow: R[A] := R[B] ^ R[C]
      execute_binary_arith(state, instr, fn(a, b) { a.pow(b) }, "POW")
    @opcodes.OpCode::Unm => {
      // Unm: R[A] := -R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in UNM")
      }
      let num = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="UNM requires number")
      }
      state.set(a + 1, @value.TValue::number(-num)) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in UNM")
      }
    }
    @opcodes.OpCode::Not => {
      // Not: R[A] := not R[B]
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in NOT")
      }
      let result = !val_b.to_boolean()
      state.set(a + 1, @value.TValue::boolean(result)) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in NOT")
      }
    }
    @opcodes.OpCode::Eq =>
      // Eq: if (R[B] == R[C]) ~= k then PC++
      execute_comparison(state, instr, fn(a, b) { a.equal(b) }, "EQ")
    @opcodes.OpCode::Lt =>
      // Lt: if (R[B] < R[C]) ~= k then PC++
      execute_comparison(
        state,
        instr,
        fn(a, b) {
          a.less_than(b) catch {
            _ => raise VMError::InvalidOperation(message="LT comparison failed")
          }
        },
        "LT",
      )
    @opcodes.OpCode::Le =>
      // Le: if (R[B] <= R[C]) ~= k then PC++
      execute_comparison(
        state,
        instr,
        fn(a, b) {
          a.less_equal(b) catch {
            _ => raise VMError::InvalidOperation(message="LE comparison failed")
          }
        },
        "LE",
      )
    _ => raise VMError::InvalidOpcode(op=@opcodes.opcode_to_int(opcode))
  }
}

///|
/// Helper: Execute binary arithmetic operation
fn execute_binary_arith(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  op : (Double, Double) -> Double raise VMError,
  name : String,
) -> Unit raise VMError {
  let a = instr.get_a()
  let b = instr.get_b()
  let c = instr.get_c()
  let val_b = state.get(b + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (B)",
      )
  }
  let val_c = state.get(c + 1) catch {
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
  state.set(a + 1, result_val) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register write in \{name} (A)",
      )
  }
}

///|
/// Helper: Execute comparison operation (for now, just evaluate, don't jump)
fn execute_comparison(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  op : (@value.TValue, @value.TValue) -> Bool raise VMError,
  name : String,
) -> Unit raise VMError {
  let b = instr.get_b()
  let c = instr.get_c()
  let val_b = state.get(b + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (B)",
      )
  }
  let val_c = state.get(c + 1) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register access in \{name} (C)",
      )
  }

  // Just evaluate the comparison for now
  // In a full implementation, this would affect control flow
  ignore(op(val_b, val_c))
}
