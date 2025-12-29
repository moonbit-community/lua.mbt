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
      execute_binary_arith(
        state,
        instr,
        base,
        fn(a, b) {
          if b == 0.0 {
            raise VMError::DivisionByZero
          }
          a / b
        },
        "DIV",
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
        ExecutionResult::Jump(0)
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
        ExecutionResult::Jump(0)
      } else {
        ExecutionResult::Continue
      }
    }
    @opcodes.OpCode::Le => {
      // Le: if (R[B] <= R[C]) ~= k then PC++
      let should_skip = execute_comparison(
        state,
        instr,
        base,
        fn(a, b) {
          a.less_equal(b) catch {
            _ => raise VMError::InvalidOperation(message="LE comparison failed")
          }
        },
        "LE",
      )
      if should_skip {
        ExecutionResult::Jump(0)
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
      ExecutionResult::Call
    }
    @opcodes.OpCode::Return => {
      // Return: return R[A], ..., R[A+B-1]
      let a = instr.get_a()
      let b = instr.get_b()
      execute_return(state, base + a, b)
      ExecutionResult::Return
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
  // Skip next instruction if (comparison_result == k)
  comparison_result == k
}

///|
/// Execute function call
/// CALL A B C: Call function at R[A] with B arguments, expecting C results
fn execute_call(
  state : @state.LuaState,
  instr : @opcodes.Instruction,
  base : Int,
) -> Unit raise VMError {
  let a = instr.get_a()
  let b = instr.get_b()
  let c = instr.get_c()

  // Get function from register
  let func_val = state.get(base + a + 1) catch {
    _ => raise VMError::RuntimeError(message="Cannot access function register")
  }

  let func = match func_val {
    @value.TValue::Function(f) => f
    _ =>
      raise VMError::InvalidOperation(
        message="Attempt to call non-function value",
      )
  }

  // New frame starts right after the function (at R[A+1])
  let new_base = base + a + 1

  // Ensure stack space for new frame
  let max_register = calculate_max_register(func.code)
  while state.stack_size() <= new_base + max_register {
    state.push(@value.TValue::nil())
  }

  // Copy arguments (they're already in the right place at R[A+1], R[A+2], ...)
  // In a full implementation, we'd handle variable arguments here

  // Push new call frame
  state.push_frame(func, new_base, c) catch {
    _ => raise VMError::RuntimeError(message="Failed to push call frame")
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
  // Results go right after where the function was called
  // For now, simplified: copy B values from start position to after function call site
  for i = 0; i < count; i = i + 1 {
    let val = state.get(start + i + 1) catch {
      _ => @value.TValue::nil()
    }
    // Results are placed starting at the function position in caller
    state.set(frame.base + i, val) catch {
      _ =>
        raise VMError::RuntimeError(message="Failed to write return value")
    }
  }
}
