// Lua VM Execution Implementation
// Based on Lua 5.4's lvm.c
// Register-based virtual machine

///| /// Execute bytecode on a Lua state
/// Now supports function calls via call stack
pub fn execute(state : @state.LuaState, proto : @proto.Proto[@value.TValue]) -> Unit raise VMError {
  // Convert proto to FunctionValue and push initial frame
  let func = @value.FunctionValue::new_with_protos(
    proto.code,
    proto.constants,
    proto.protos,
    [],  // No upvalues for top-level chunk
    0,   // No parameters for top-level chunk
    false,  // Top-level chunk is not vararg
  )
  let base = state.stack_size()

  // Ensure we have enough stack space for registers
  let max_register = calculate_max_register(proto.code)
  while state.stack_size() <= base + max_register + 1 {
    state.push(@value.TValue::nil())
  }

  // Push initial call frame
  state.push_frame(func, base, 0, 0) catch {
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
      // Use count=1 to return nil (not count=0 which means "all values to top")
      execute_return(state, 0, 1)
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
      let target_index = base + a + 1

      // Ensure stack is large enough for this write (like LoadK does)
      while state.stack_size() < target_index {
        state.push(@value.TValue::nil())
      }

      state.set(target_index, value) catch {
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
      let target_index = base + a + 1

      // Ensure stack is large enough for this write
      while state.stack_size() < target_index {
        state.push(@value.TValue::nil())
      }

      state.set(target_index, value) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in LOADK: base=\{base}, a=\{a}, target_index=\{target_index}, stack_size=\{state.stack_size()}")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Closure => {
      // Closure: R[A] := closure(KPROTO[Bx])
      // Create a closure from a proto, capturing upvalues
      let a = instr.get_a()
      let bx = instr.get_bx()

      // Get current frame to access function's protos
      let frame = state.current_frame() catch {
        _ => raise VMError::RuntimeError(message="No active frame for Closure")
      }

      // Get the proto from the current function's proto pool
      if bx < 0 || bx >= frame.func.protos.length() {
        raise VMError::RuntimeError(message="Invalid proto index in CLOSURE: bx=\{bx}, protos.length=\{frame.func.protos.length()}")
      }
      let proto = frame.func.protos[bx]

      // Capture upvalues based on descriptors
      let captured_upvalues : Array[@value.Upvalue] = []
      for desc in proto.upvalue_descs {
        let upvalue = if desc.in_stack {
          // Capture from current frame's stack - get or create Open upvalue
          // desc.index is the local variable's register index (0-based)
          // Stack index = base + desc.index + 1 (Lua 1-based indexing)
          state.find_or_create_upvalue(base + desc.index + 1)
        } else {
          // Capture from current function's upvalues - reuse the parent's upvalue
          if desc.index < 0 || desc.index >= frame.func.upvalues.length() {
            raise VMError::RuntimeError(message="Invalid upvalue index in CLOSURE: index=\{desc.index}, upvalues.length=\{frame.func.upvalues.length()}")
          }
          frame.func.upvalues[desc.index]
        }
        captured_upvalues.push(upvalue)
      }

      // Create the closure with captured upvalues
      let closure = @value.FunctionValue::new_with_protos(
        proto.code,
        proto.constants,
        proto.protos,
        captured_upvalues,
        proto.param_count,
        proto.is_vararg,
      )

      // Store closure in destination register
      let target_index = base + a + 1
      while state.stack_size() < target_index {
        state.push(@value.TValue::nil())
      }
      state.set(target_index, @value.TValue::function(closure)) catch {
        _ => raise VMError::RuntimeError(message="Invalid register write in CLOSURE")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::GetUpval => {
      // GetUpval: R[A] := UpValue[B]
      // Read upvalue B from current function and store in register A
      let a = instr.get_a()
      let b = instr.get_b()

      // Get current frame to access function's upvalues
      let frame = state.current_frame() catch {
        _ => raise VMError::RuntimeError(message="No active frame for GetUpval")
      }

      // Check upvalue index bounds
      if b < 0 || b >= frame.func.upvalues.length() {
        raise VMError::RuntimeError(message="Invalid upvalue index in GETUPVAL: b=\{b}, upvalues.length=\{frame.func.upvalues.length()}")
      }

      // Get the upvalue
      let upvalue = frame.func.upvalues[b]

      // Read value from upvalue (check if Open or Closed)
      let value = match upvalue.val.kind {
        @value.UpvalueKind::Open(stack_index) => {
          // Open upvalue - read from stack
          state.get(stack_index) catch {
            _ => @value.TValue::nil()
          }
        }
        @value.UpvalueKind::Closed(ref) => {
          // Closed upvalue - read from captured value
          ref.val
        }
      }

      // Store in destination register
      let target_index = base + a + 1
      while state.stack_size() < target_index {
        state.push(@value.TValue::nil())
      }
      state.set(target_index, value) catch {
        _ => raise VMError::RuntimeError(message="Invalid register write in GETUPVAL")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::SetUpval => {
      // SetUpval: UpValue[B] := R[A]
      // Write value from register A to upvalue B of current function
      let a = instr.get_a()
      let b = instr.get_b()

      // Get current frame to access function's upvalues
      let frame = state.current_frame() catch {
        _ => raise VMError::RuntimeError(message="No active frame for SetUpval")
      }

      // Check upvalue index bounds
      if b < 0 || b >= frame.func.upvalues.length() {
        raise VMError::RuntimeError(message="Invalid upvalue index in SETUPVAL: b=\{b}, upvalues.length=\{frame.func.upvalues.length()}")
      }

      // Get value from register
      let value = state.get(base + a + 1) catch {
        _ => raise VMError::RuntimeError(message="Invalid register access in SETUPVAL")
      }

      // Get the upvalue
      let upvalue = frame.func.upvalues[b]

      // Write value to upvalue (check if Open or Closed)
      match upvalue.val.kind {
        @value.UpvalueKind::Open(stack_index) => {
          // Open upvalue - write to stack
          state.set(stack_index, value) catch {
            _ => raise VMError::RuntimeError(message="Failed to write to open upvalue")
          }
        }
        @value.UpvalueKind::Closed(ref) => {
          // Closed upvalue - write to captured value
          ref.val = value
        }
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
      // With __unm metamethod support
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in UNM")
      }

      // Check for __unm metamethod
      let metamethod_opt = get_value_metamethod(val_b, "__unm")

      let result_val = match metamethod_opt {
        Some(@value.TValue::NativeFunction(nfunc)) => {
          // Call the native __unm metamethod
          let results = call_native_function(state, nfunc.name, [val_b])
          match results.length() {
            0 => @value.TValue::nil()
            _ => results[0]
          }
        }
        Some(@value.TValue::Function(func)) => {
          // Call the bytecode __unm metamethod
          let results = call_bytecode_function(state, func, [val_b])
          match results.length() {
            0 => @value.TValue::nil()
            _ => results[0]
          }
        }
        _ => {
          // No metamethod, perform default numeric negation
          let num = val_b.to_number() catch {
            _ => raise VMError::InvalidOperation(message="UNM requires number")
          }
          @value.TValue::number(-num)
        }
      }

      state.set(base + a + 1, result_val) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in UNM")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Concat => {
      // Concat: R[A] := R[B].. ... ..R[C]
      // With __concat metamethod support
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()

      // Build result by concatenating values from R[B] to R[C]
      // Each concatenation checks for __concat metamethod
      let mut result_val = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in CONCAT")
      }

      for i = b + 1; i <= c; i = i + 1 {
        let next_val = state.get(base + i + 1) catch {
          _ =>
            raise VMError::RuntimeError(message="Invalid register access in CONCAT")
        }

        // Check for __concat metamethod
        let metamethod = match get_value_metamethod(result_val, "__concat") {
          Some(mm) => Some(mm)
          None => get_value_metamethod(next_val, "__concat")
        }

        result_val = match metamethod {
          Some(@value.TValue::NativeFunction(nfunc)) => {
            // Call the native __concat metamethod
            let results = call_native_function(state, nfunc.name, [result_val, next_val])
            match results.length() {
              0 => @value.TValue::string("")  // No result, use empty string
              _ => results[0]  // Use first result
            }
          }
          Some(@value.TValue::Function(func)) => {
            // Call the bytecode __concat metamethod
            let results = call_bytecode_function(state, func, [result_val, next_val])
            match results.length() {
              0 => @value.TValue::string("")  // No result, use empty string
              _ => results[0]  // Use first result
            }
          }
          _ => {
            // No metamethod, perform default string concatenation
            @value.TValue::string(result_val.to_string() + next_val.to_string())
          }
        }
      }

      state.set(base + a + 1, result_val) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in CONCAT")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::Len => {
      // Len: R[A] := #R[B]
      // With __len metamethod support
      let a = instr.get_a()
      let b = instr.get_b()
      let val_b = state.get(base + b + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in LEN")
      }

      // Get length based on type
      let length = match val_b {
        @value.TValue::String(s) => s.length()
        @value.TValue::Table(t) => {
          // Check for __len metamethod
          match get_metamethod(t, "__len") {
            Some(@value.TValue::NativeFunction(nfunc)) => {
              // Call the native __len function with the table as argument
              let results = call_native_function(state, nfunc.name, [val_b])
              // Extract the length from the result
              match results.length() {
                0 => t.length()  // No result, use default
                _ => {
                  match results[0] {
                    @value.TValue::Integer(i) => i.to_int()
                    @value.TValue::Number(n) => n.to_int()
                    _ => t.length()  // Invalid result, use default
                  }
                }
              }
            }
            Some(@value.TValue::Function(func)) => {
              // Call the bytecode __len function with the table as argument
              let results = call_bytecode_function(state, func, [val_b])
              // Extract the length from the result
              match results.length() {
                0 => t.length()  // No result, use default
                _ => {
                  match results[0] {
                    @value.TValue::Integer(i) => i.to_int()
                    @value.TValue::Number(n) => n.to_int()
                    _ => t.length()  // Invalid result, use default
                  }
                }
              }
            }
            _ => t.length()  // No __len, use default
          }
        }
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
      // With __index metamethod support
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
        @value.TValue::Table(table) => {
          // First try direct access
          let value = table.get(key_val)

          // If nil, check for __index metamethod
          match value {
            @value.TValue::Nil => {
              match get_metamethod(table, "__index") {
                Some(index_mm) => {
                  match index_mm {
                    @value.TValue::Table(index_table) => {
                      // __index is a table, get value from it
                      index_table.get(key_val)
                    }
                    @value.TValue::NativeFunction(nfunc) => {
                      // __index is a native function, call it with (table, key)
                      let results = call_native_function(state, nfunc.name, [table_val, key_val])
                      match results.length() {
                        0 => @value.TValue::nil()
                        _ => results[0]
                      }
                    }
                    @value.TValue::Function(func) => {
                      // __index is a bytecode function, call it with (table, key)
                      let results = call_bytecode_function(state, func, [table_val, key_val])
                      match results.length() {
                        0 => @value.TValue::nil()
                        _ => results[0]
                      }
                    }
                    _ => @value.TValue::nil()
                  }
                }
                None => @value.TValue::nil()
              }
            }
            _ => value  // Non-nil value found, return it
          }
        }
        _ =>
          raise VMError::InvalidOperation(
            message="Attempt to index non-table value",
          )
      }

      let target_index = base + a + 1

      // Ensure stack is large enough for this write
      while state.stack_size() < target_index {
        state.push(@value.TValue::nil())
      }

      state.set(target_index, result) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register write in GETTABLE")
      }
      ExecutionResult::Continue
    }
    @opcodes.OpCode::SetTable => {
      // SetTable: R[A][R[B]] := R[C]
      // With __newindex metamethod support
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
        @value.TValue::Table(table) => {
          // Check if the key already exists
          let existing_value = table.get(key_val)

          match existing_value {
            @value.TValue::Nil => {
              // Key doesn't exist, check for __newindex metamethod
              match get_metamethod(table, "__newindex") {
                Some(newindex_mm) => {
                  match newindex_mm {
                    @value.TValue::Table(newindex_table) => {
                      // __newindex is a table, set value in it
                      newindex_table.set(key_val, value_val)
                    }
                    @value.TValue::NativeFunction(nfunc) => {
                      // __newindex is a native function, call it with (table, key, value)
                      ignore(call_native_function(state, nfunc.name, [table_val, key_val, value_val]))
                      // Function called for side effects, don't store result
                    }
                    @value.TValue::Function(func) => {
                      // __newindex is a bytecode function, call it with (table, key, value)
                      ignore(call_bytecode_function(state, func, [table_val, key_val, value_val]))
                      // Function called for side effects, don't store result
                    }
                    _ => {
                      // Invalid __newindex, use direct set
                      table.set(key_val, value_val)
                    }
                  }
                }
                None => {
                  // No __newindex metamethod, set directly
                  table.set(key_val, value_val)
                }
              }
            }
            _ => {
              // Key exists, set directly (don't invoke __newindex)
              table.set(key_val, value_val)
            }
          }
        }
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
      let target_index = base + a + 1

      // Ensure stack is large enough for this write
      while state.stack_size() < target_index {
        state.push(@value.TValue::nil())
      }

      state.set(target_index, value) catch {
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
    @opcodes.OpCode::Vararg => {
      // VARARG A B C: R[A], R[A+1], ..., R[A+C-2] = vararg
      // Copy vararg values to destination registers
      let a = instr.get_a()
      let c = instr.get_c()

      // Get current frame to access varargs
      let frame = state.current_frame() catch {
        _ => raise VMError::RuntimeError(message="No frame for VARARG")
      }

      // Calculate how many varargs are available
      // Varargs start after named parameters
      let param_count = frame.func.param_count
      let arg_count = frame.arg_count
      let num_available_varargs = if arg_count > param_count {
        arg_count - param_count
      } else {
        0  // No varargs passed
      }

      // Determine how many varargs to copy
      let num_to_copy = if c == 0 {
        // C=0 means copy all available varargs
        num_available_varargs
      } else {
        // C encodes count + 1, so actual count is c - 1
        c - 1
      }

      // Ensure stack has enough space for destination registers
      // We need space up to base + a + num_to_copy
      let max_dest_index = base + a + num_to_copy
      while state.stack_size() <= max_dest_index {
        state.push(@value.TValue::nil())
      }

      // Copy varargs to destination registers
      for i = 0; i < num_to_copy; i = i + 1 {
        let val = if i < num_available_varargs {
          // With special vararg layout (new_base after args), ALL arguments are BEFORE frame base
          // Arguments: base - arg_count, base - arg_count + 1, ..., base - 1
          // Named params: base - arg_count + 0, ..., base - arg_count + (param_count - 1)
          // Varargs start at: base - arg_count + param_count
          let source_index = base - arg_count + param_count + i + 1
          let fetched_val = state.get(source_index) catch {
            _ => @value.TValue::nil()
          }
          fetched_val
        } else {
          // Not enough varargs, use nil
          @value.TValue::nil()
        }
        let write_index = base + a + i + 1
        state.set(write_index, val) catch {
          _ => raise VMError::RuntimeError(message="Failed to write vararg at index \{write_index}, stack size \{state.stack_size()}")
        }
      }

      // NOTE: Don't shrink stack here! The stack was allocated based on max_register
      // for the entire function. Shrinking it breaks code that uses higher registers
      // later in the function (like comparisons in for loops).

      ExecutionResult::Continue
    }
    @opcodes.OpCode::SetList => {
      // SetList: R[A][C+i] := R[A+i], 1 <= i <= B
      // Set B consecutive table elements starting at index C
      let a = instr.get_a()
      let b = instr.get_b()
      let c = instr.get_c()

      // Get table from R[A]
      let table_val = state.get(base + a + 1) catch {
        _ =>
          raise VMError::RuntimeError(message="Invalid register access in SETLIST")
      }

      let table = match table_val {
        @value.TValue::Table(t) => t
        _ =>
          raise VMError::InvalidOperation(
            message="Attempt to use SetList on non-table value",
          )
      }

      // Determine how many elements to set
      // B=0 means all values from R[A+1] to top of stack
      let num_elements = if b == 0 {
        // All values from R[A+1] to stack top
        let stack_top = state.stack_size()
        let start_pos = base + a + 1
        if stack_top > start_pos {
          stack_top - start_pos
        } else {
          0
        }
      } else {
        b
      }

      // Set elements in table
      for i = 1; i <= num_elements; i = i + 1 {
        // Read value from R[A+i]
        let val = state.get(base + a + i + 1) catch {
          _ => @value.TValue::nil()
        }
        // Set in table at index C+i
        table.set_int(c + i, val)
      }

      ExecutionResult::Continue
    }
    _ => raise VMError::InvalidOpcode(op=@opcodes.opcode_to_int(opcode))
  }
}

///|
/// Helper: Execute binary arithmetic operation with metamethod support
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

  // Map operation name to metamethod name
  let metamethod_name = match name {
    "ADD" => "__add"
    "SUB" => "__sub"
    "MUL" => "__mul"
    "DIV" => "__div"
    "IDIV" => "__idiv"
    "MOD" => "__mod"
    "POW" => "__pow"
    _ => ""
  }

  // Check for metamethod (try left operand first, then right)
  let metamethod = match get_value_metamethod(val_b, metamethod_name) {
    Some(mm) => Some(mm)
    None => get_value_metamethod(val_c, metamethod_name)
  }

  let result_val = match metamethod {
    Some(@value.TValue::NativeFunction(nfunc)) => {
      // Call the native metamethod function with both operands
      let results = call_native_function(state, nfunc.name, [val_b, val_c])
      match results.length() {
        0 => @value.TValue::nil()  // No result, use nil
        _ => results[0]  // Use first result
      }
    }
    Some(@value.TValue::Function(func)) => {
      // Call the bytecode metamethod function with both operands
      let results = call_bytecode_function(state, func, [val_b, val_c])
      match results.length() {
        0 => @value.TValue::nil()  // No result, use nil
        _ => results[0]  // Use first result
      }
    }
    _ => {
      // No metamethod, perform default numeric operation
      let num_b = val_b.to_number() catch {
        _ => raise VMError::InvalidOperation(message="\{name} requires numbers")
      }
      let num_c = val_c.to_number() catch {
        _ => raise VMError::InvalidOperation(message="\{name} requires numbers")
      }
      let result = op(num_b, num_c)
      if result == result.to_int64().to_double() {
        @value.TValue::integer(result.to_int64())
      } else {
        @value.TValue::number(result)
      }
    }
  }

  state.set(base + a + 1, result_val) catch {
    _ =>
      raise VMError::RuntimeError(
        message="Invalid register write in \{name} (A)",
      )
  }
}

///|
/// Helper: Execute comparison operation with metamethod support
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

  // Map operation name to metamethod name
  let metamethod_name = match name {
    "EQ" => "__eq"
    "LT" => "__lt"
    "LE" => "__le"
    _ => ""
  }

  // Check for metamethod (try left operand first, then right)
  let metamethod = match get_value_metamethod(val_b, metamethod_name) {
    Some(mm) => Some(mm)
    None => get_value_metamethod(val_c, metamethod_name)
  }

  let comparison_result = match metamethod {
    Some(@value.TValue::NativeFunction(nfunc)) => {
      // Call the native metamethod function with both operands
      let results = call_native_function(state, nfunc.name, [val_b, val_c])
      match results.length() {
        0 => false  // No result, treat as false
        _ => results[0].to_boolean()  // Convert result to boolean
      }
    }
    Some(@value.TValue::Function(func)) => {
      // Call the bytecode metamethod function with both operands
      let results = call_bytecode_function(state, func, [val_b, val_c])
      match results.length() {
        0 => false  // No result, treat as false
        _ => results[0].to_boolean()  // Convert result to boolean
      }
    }
    _ => {
      // No metamethod, perform default comparison
      op(val_b, val_c)
    }
  }

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
    // Function is at base + a + 1 (Lua index)
    // Arguments start at base + a + 2 (Lua index)
    // Stack top is at stack_size
    // Number of args = stack_size - (base + a + 2) + 1
    state.stack_size() - base - a - 1
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

      // Check for __tostring metamethod on tables
      let str = match arg {
        @value.TValue::Table(t) => {
          match get_metamethod(t, "__tostring") {
            Some(@value.TValue::NativeFunction(nfunc)) => {
              // Call the native __tostring metamethod
              let results = call_native_function(state, nfunc.name, [arg])
              match results.length() {
                0 => @stdlib.tostring(arg)  // No result, use default
                _ => results[0].to_string()  // Convert result to string
              }
            }
            Some(@value.TValue::Function(func)) => {
              // Call the bytecode __tostring metamethod
              let results = call_bytecode_function(state, func, [arg])
              match results.length() {
                0 => @stdlib.tostring(arg)  // No result, use default
                _ => results[0].to_string()  // Convert result to string
              }
            }
            _ => @stdlib.tostring(arg)
          }
        }
        _ => @stdlib.tostring(arg)
      }

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
    "select" => {
      // select(index, ...) - Returns all arguments after index
      // select("#", ...) - Returns count of arguments (excluding the "#")
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="select requires at least 1 argument")
      }

      match args[0] {
        @value.TValue::String(s) => {
          if s == "#" {
            // Return count of remaining arguments
            [@value.TValue::integer((args.length() - 1).to_int64())]
          } else {
            raise VMError::InvalidOperation(message="select: string index must be '#'")
          }
        }
        @value.TValue::Integer(_) | @value.TValue::Number(_) => {
          // Get the index as integer
          let idx = match args[0] {
            @value.TValue::Integer(i) => i.to_int()
            @value.TValue::Number(num) => num.to_int()
            _ => 1  // Shouldn't happen
          }

          // Lua allows negative indices: -1 is the last arg, -2 is second-to-last, etc.
          let actual_idx = if idx < 0 {
            // Negative index: count from the end
            // Total args (excluding select's first arg) = args.length() - 1
            // -1 should point to last arg, which is at position args.length() - 1
            args.length() + idx
          } else {
            idx
          }

          // Check bounds
          if actual_idx < 1 || actual_idx > args.length() - 1 {
            raise VMError::InvalidOperation(message="select: index out of range")
          }

          // Return all arguments from actual_idx onwards
          let result : Array[@value.TValue] = []
          for i = actual_idx; i < args.length(); i = i + 1 {
            result.push(args[i])
          }
          result
        }
        _ => raise VMError::InvalidOperation(message="select: index must be a number or '#'")
      }
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
    // Metatable functions
    "setmetatable" => {
      // setmetatable(table, metatable) - Set metatable for a table
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="setmetatable requires 2 arguments")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="setmetatable: first argument must be a table")
      }

      // Metatable must be nil or a table
      let metatable = args[1]
      match metatable {
        @value.TValue::Nil | @value.TValue::Table(_) => {
          table.set_metatable(metatable)
          [args[0]]  // Returns the table
        }
        _ => raise VMError::InvalidOperation(message="setmetatable: second argument must be nil or a table")
      }
    }
    "getmetatable" => {
      // getmetatable(object) - Get metatable of an object
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="getmetatable requires an argument")
      }

      match args[0] {
        @value.TValue::Table(t) => [t.get_metatable()]
        _ => [@value.TValue::nil()]  // Non-tables return nil (for now)
      }
    }
    // Iteration functions
    "next" => {
      // next(table, index) - Get next key-value pair
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="next requires a table argument")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="next requires a table")
      }

      let start_key = if args.length() >= 2 { args[1] } else { @value.TValue::nil() }

      // Simplified implementation: iterate through array part first, then we're done
      // Full implementation would also iterate through hash part
      match start_key {
        @value.TValue::Nil => {
          // Start from beginning - try index 1
          let val = table.get_int(1)
          if !val.is_nil() {
            [@value.TValue::integer(1L), val]
          } else {
            // Array is empty, return nil (hash iteration not implemented)
            [@value.TValue::nil()]
          }
        }
        @value.TValue::Integer(i) => {
          // Try next integer index
          let next_idx = i.to_int() + 1
          let val = table.get_int(next_idx)
          if !val.is_nil() {
            [@value.TValue::integer(next_idx.to_int64()), val]
          } else {
            // No more array elements (hash iteration not implemented)
            [@value.TValue::nil()]
          }
        }
        _ => {
          // Non-integer key (hash part not implemented for iteration)
          [@value.TValue::nil()]
        }
      }
    }
    "pairs" => {
      // pairs(table) - Returns iterator function, table, nil
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="pairs requires a table argument")
      }
      match args[0] {
        @value.TValue::Table(_) => {
          // Return: next function, table, nil (starting key)
          [
            @value.TValue::native_function("next"),
            args[0],
            @value.TValue::nil()
          ]
        }
        _ => raise VMError::InvalidOperation(message="pairs requires a table")
      }
    }
    "ipairs" => {
      // ipairs(table) - Returns iterator function, table, 0
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="ipairs requires a table argument")
      }
      match args[0] {
        @value.TValue::Table(_) => {
          // Return: iterator function (ipairs_iter), table, 0 (starting index)
          [
            @value.TValue::native_function("ipairs_iter"),
            args[0],
            @value.TValue::integer(0L)
          ]
        }
        _ => raise VMError::InvalidOperation(message="ipairs requires a table")
      }
    }
    "ipairs_iter" => {
      // Internal iterator for ipairs: (table, i) -> (i+1, table[i+1])
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="ipairs_iter requires table and index")
      }
      let table = match args[0] {
        @value.TValue::Table(t) => t
        _ => raise VMError::InvalidOperation(message="ipairs_iter requires a table")
      }
      let i = match args[1] {
        @value.TValue::Integer(idx) => idx.to_int()
        @value.TValue::Number(n) => n.to_int()
        _ => raise VMError::InvalidOperation(message="ipairs_iter requires numeric index")
      }

      let next_i = i + 1
      let val = table.get_int(next_i)
      if !val.is_nil() {
        [@value.TValue::integer(next_i.to_int64()), val]
      } else {
        [@value.TValue::nil()]
      }
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
    "string.rep" => {
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="string.rep requires 2 arguments")
      }
      let n = try {
        args[1].to_integer().to_int()
      } catch {
        _ => raise VMError::InvalidOperation(message="string.rep repetition count must be a number")
      }
      let result = try {
        @stdlib.string_rep(args[0], n)
      } catch {
        err => raise VMError::RuntimeError(message="string.rep failed: \{err}")
      }
      [@value.TValue::string(result)]
    }
    "string.reverse" => {
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="string.reverse requires a string argument")
      }
      let result = try {
        @stdlib.string_reverse(args[0])
      } catch {
        err => raise VMError::RuntimeError(message="string.reverse failed: \{err}")
      }
      [@value.TValue::string(result)]
    }
    "pcall" => {
      // pcall(f, ...) - Protected call
      // Returns (true, results...) on success or (false, error_message) on error
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="pcall requires at least one argument")
      }

      let func_val = args[0]
      let call_args : Array[@value.TValue] = []
      for i = 1; i < args.length(); i = i + 1 {
        call_args.push(args[i])
      }

      // Save initial call depth for cleanup on error
      let initial_depth = state.call_depth()

      // Try to call the function
      try {
        let results = match func_val {
          @value.TValue::NativeFunction(nfunc) => {
            call_native_function(state, nfunc.name, call_args)
          }
          @value.TValue::Function(func) => {
            call_bytecode_function(state, func, call_args)
          }
          _ => raise VMError::InvalidOperation(message="pcall: first argument must be a function")
        }

        // Success: return (true, results...)
        let result_array : Array[@value.TValue] = [@value.TValue::boolean(true)]
        for r in results {
          result_array.push(r)
        }
        result_array
      } catch {
        err => {
          // Clean up any call frames that were pushed
          while state.call_depth() > initial_depth {
            ignore(state.pop_frame() catch { _ => raise VMError::RuntimeError(message="cleanup failed") })
          }

          // Error: return (false, error_message)
          let error_msg = match err {
            VMError::InvalidOpcode(op=op) => "Invalid opcode: \{op}"
            VMError::DivisionByZero => "Division by zero"
            VMError::InvalidOperation(message=msg) => msg
            VMError::RuntimeError(message=msg) => msg
          }
          [@value.TValue::boolean(false), @value.TValue::string(error_msg)]
        }
      }
    }
    "xpcall" => {
      // xpcall(f, err_handler, ...) - Extended protected call
      // Returns (true, results...) on success or (false, handler_result) on error
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="xpcall requires at least two arguments")
      }

      let func_val = args[0]
      let err_handler = args[1]
      let call_args : Array[@value.TValue] = []
      for i = 2; i < args.length(); i = i + 1 {
        call_args.push(args[i])
      }

      // Save initial call depth for cleanup on error
      let initial_depth = state.call_depth()

      // Try to call the function
      try {
        let results = match func_val {
          @value.TValue::NativeFunction(nfunc) => {
            call_native_function(state, nfunc.name, call_args)
          }
          @value.TValue::Function(func) => {
            call_bytecode_function(state, func, call_args)
          }
          _ => raise VMError::InvalidOperation(message="xpcall: first argument must be a function")
        }

        // Success: return (true, results...)
        let result_array : Array[@value.TValue] = [@value.TValue::boolean(true)]
        for r in results {
          result_array.push(r)
        }
        result_array
      } catch {
        err => {
          // Clean up any call frames that were pushed
          while state.call_depth() > initial_depth {
            ignore(state.pop_frame() catch { _ => raise VMError::RuntimeError(message="cleanup failed") })
          }

          // Error: call error handler with error message
          let error_msg_str = match err {
            VMError::InvalidOpcode(op=op) => "Invalid opcode: \{op}"
            VMError::DivisionByZero => "Division by zero"
            VMError::InvalidOperation(message=msg) => msg
            VMError::RuntimeError(message=msg) => msg
          }
          let error_msg = @value.TValue::string(error_msg_str)

          // Call error handler
          let handler_results = try {
            match err_handler {
              @value.TValue::NativeFunction(nfunc) => {
                call_native_function(state, nfunc.name, [error_msg])
              }
              @value.TValue::Function(func) => {
                call_bytecode_function(state, func, [error_msg])
              }
              _ => [error_msg]  // If handler is not a function, just use the error message
            }
          } catch {
            _ => [error_msg]  // If handler fails, use original error message
          }

          // Return (false, handler_result)
          let result_array : Array[@value.TValue] = [@value.TValue::boolean(false)]
          if handler_results.length() > 0 {
            result_array.push(handler_results[0])
          } else {
            result_array.push(error_msg)
          }
          result_array
        }
      }
    }
    "load" => {
      // load(chunk, [chunkname], [mode], [env])
      // Loads a chunk as a function
      // For simplicity, we only support string chunks (not reader functions)
      // Returns either (function) on success or (nil, error_message) on error
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="load requires at least one argument")
      }

      let code_str = match args[0] {
        @value.TValue::String(s) => s
        @value.TValue::Nil =>
          return [@value.TValue::nil(), @value.TValue::string("load: chunk must be a string")]
        _ =>
          return [@value.TValue::nil(), @value.TValue::string("load: chunk must be a string")]
      }

      // Try to compile the code using the registered compiler
      let func = state.compile_string(code_str) catch {
        @state.StateError::RuntimeError(message~) => {
          // Return nil and error message
          return [@value.TValue::nil(), @value.TValue::string(message)]
        }
        _ => {
          // Other state errors
          return [@value.TValue::nil(), @value.TValue::string("load: compilation failed")]
        }
      }

      // Return the compiled function
      [func]
    }
    "_G__index" => {
      // __index metamethod for _G table
      // _G[key] should return global variable with that name
      if args.length() < 2 {
        raise VMError::InvalidOperation(message="_G__index requires 2 arguments")
      }
      let key = match args[1] {
        @value.TValue::String(s) => s
        _ => return [@value.TValue::nil()]
      }
      // Get global variable
      let value = state.get_global(key) catch {
        _ => @value.TValue::nil()
      }
      [value]
    }
    "_G__newindex" => {
      // __newindex metamethod for _G table
      // _G[key] = value should set global variable
      if args.length() < 3 {
        raise VMError::InvalidOperation(message="_G__newindex requires 3 arguments")
      }
      let key = match args[1] {
        @value.TValue::String(s) => s
        _ => return []
      }
      let value = args[2]
      // Set global variable
      state.set_global(key, value)
      []
    }
    "require" => {
      // require(modname)
      // Load a module if not already loaded, return the module value
      if args.length() == 0 {
        raise VMError::InvalidOperation(message="require requires a module name")
      }

      let modname = match args[0] {
        @value.TValue::String(s) => s
        _ => raise VMError::InvalidOperation(message="require: module name must be a string")
      }

      // Get package table
      let package_val = state.get_global("package") catch {
        _ => raise VMError::InvalidOperation(message="require: package table not found")
      }
      let package_table = match package_val {
        @value.TValue::Table(pkg_tbl) => pkg_tbl
        _ => raise VMError::InvalidOperation(message="require: package is not a table")
      }

      // Get package.loaded table
      let loaded_table = match package_table.get_string("loaded") {
        @value.TValue::Table(tbl) => tbl
        _ => raise VMError::InvalidOperation(message="require: package.loaded is not a table")
      }

      // Check if module is already loaded
      let existing = loaded_table.get_string(modname)
      if !existing.is_nil() {
        return [existing]
      }

      // Build error message listing all attempted locations
      let error_parts : Array[String] = []
      error_parts.push("module '\{modname}' not found:")

      // Check package.preload
      let preload_table = match package_table.get_string("preload") {
        @value.TValue::Table(tbl) => tbl
        _ => @value.Table::new()
      }
      let preload_func = preload_table.get_string(modname)
      if preload_func.is_nil() {
        error_parts.push("\tno field package.preload['\{modname}']")
      }

      // Search using package.path (Lua files)
      let path_str = match package_table.get_string("path") {
        @value.TValue::String(s) => s
        _ => {
          // package.path is not a string - raise error
          raise VMError::RuntimeError(
            message="error loading module (package.path is not a string)"
          )
        }
      }
      if path_str.length() > 0 {
        // Use package.searchpath to get formatted error message
        let searchpath_result = call_native_function(
          state,
          "package.searchpath",
          [@value.TValue::string(modname), @value.TValue::string(path_str)]
        )
        // searchpath returns [nil, error_message] when not found
        if searchpath_result.length() >= 2 {
          match searchpath_result[1] {
            @value.TValue::String(err_msg) => {
              // Extract just the file paths from searchpath error
              // Skip first line by finding first newline
              let mut start = 0
              while start < err_msg.length() && err_msg[start] != '\n' {
                start = start + 1
              }
              // Skip the newline itself
              start = start + 1
              // Add rest of message (all the "\tno file" lines)
              if start < err_msg.length() {
                let remaining = try {
                  err_msg[start:err_msg.length()].to_string()
                } catch {
                  _ => ""
                }
                error_parts.push(remaining)
              }
            }
            _ => ()
          }
        }
      }

      // Search using package.cpath (C files)
      let cpath_str = match package_table.get_string("cpath") {
        @value.TValue::String(s) => s
        _ => ""
      }
      if cpath_str.length() > 0 {
        // Use package.searchpath to get formatted error message
        let searchpath_result = call_native_function(
          state,
          "package.searchpath",
          [@value.TValue::string(modname), @value.TValue::string(cpath_str)]
        )
        // searchpath returns [nil, error_message] when not found
        if searchpath_result.length() >= 2 {
          match searchpath_result[1] {
            @value.TValue::String(err_msg) => {
              // Extract just the file paths from searchpath error
              // Skip first line by finding first newline
              let mut start = 0
              while start < err_msg.length() && err_msg[start] != '\n' {
                start = start + 1
              }
              // Skip the newline itself
              start = start + 1
              // Add rest of message (all the "\tno file" lines)
              if start < err_msg.length() {
                let remaining = try {
                  err_msg[start:err_msg.length()].to_string()
                } catch {
                  _ => ""
                }
                error_parts.push(remaining)
              }
            }
            _ => ()
          }
        }
      }

      // Join all error parts and raise error
      let full_error = error_parts.join("\n")
      raise VMError::RuntimeError(message=full_error)
    }
    "package.searchpath" => {
      // package.searchpath(name, path, [sep], [rep])
      // Searches for a file in the given path
      // Returns nil + error message listing all attempted paths
      if args.length() < 2 {
        raise VMError::InvalidOperation(
          message="package.searchpath requires at least 2 arguments",
        )
      }

      let name = match args[0] {
        @value.TValue::String(s) => s
        _ =>
          raise VMError::InvalidOperation(
            message="package.searchpath: name must be a string",
          )
      }

      let path = match args[1] {
        @value.TValue::String(s) => s
        _ =>
          raise VMError::InvalidOperation(
            message="package.searchpath: path must be a string",
          )
      }

      // For simplicity, we don't actually search files - just return error
      // Build error message with attempted paths
      // Manual split by ";"
      let templates : Array[String] = []
      let mut current = ""
      for i = 0; i < path.length(); i = i + 1 {
        if path[i] == ';' {
          templates.push(current)
          current = ""
        } else {
          current = current + path[i].to_int().unsafe_to_char().to_string()
        }
      }
      if current.length() > 0 {
        templates.push(current)
      }

      let error_lines : Array[String] = []
      for template in templates {
        // Replace ? with module name
        let mut filepath = ""
        for i = 0; i < template.length(); i = i + 1 {
          if template[i] == '?' {
            filepath = filepath + name
          } else {
            filepath = filepath + template[i].to_int().unsafe_to_char().to_string()
          }
        }
        error_lines.push("\tno file '\{filepath}'")
      }
      let joined_lines = error_lines.join("\n")
      let error_msg = "module '\{name}' not found:\n" + joined_lines

      [
        @value.TValue::nil(),
        @value.TValue::string(error_msg),
      ]
    }
    _ => {
      // Ignore set_global for now - it's used during initialization
      ignore(state)
      raise VMError::RuntimeError(message="Unknown native function: \{name}")
    }
  }
}

///|
/// Call a bytecode function with given arguments
/// This is used for metamethods which need synchronous function calls
/// Returns an array of result values
fn call_bytecode_function(
  state : @state.LuaState,
  func : @value.FunctionValue,
  args : Array[@value.TValue],
) -> Array[@value.TValue] raise VMError {
  // Save current call depth to know when the function returns
  let initial_depth = state.call_depth()

  // Save current stack size to know where to place function and args
  let call_base = state.stack_size()

  // Push function onto stack
  state.push(@value.TValue::function(func))

  // Push arguments onto stack
  for arg in args {
    state.push(arg)
  }

  let arg_count = args.length()
  let param_count = func.param_count

  // Calculate new_base for the function
  // For vararg functions: registers start after all arguments
  // For normal functions: registers start after the function
  let new_base = if func.is_vararg {
    call_base + 1 + arg_count
  } else {
    call_base + 1
  }

  // Ensure stack space for new frame
  let max_register = calculate_max_register(func.code)
  while state.stack_size() <= new_base + max_register + 1 {
    state.push(@value.TValue::nil())
  }

  // For vararg functions: copy named parameters to register positions
  if func.is_vararg {
    for i = 0; i < param_count && i < arg_count; i = i + 1 {
      let arg_pos = call_base + 1 + i
      let reg_pos = new_base + i + 1
      let val = state.get(arg_pos + 1) catch { _ => @value.TValue::nil() }
      state.set(reg_pos, val) catch { _ => () }
    }
  }

  // Initialize missing parameters to nil
  for i = arg_count; i < param_count; i = i + 1 {
    state.set(new_base + i + 1, @value.TValue::nil()) catch {
      _ => ()
    }
  }

  // Push new call frame
  state.push_frame(func, new_base, 0, arg_count) catch {
    _ => raise VMError::RuntimeError(message="Failed to push metamethod call frame")
  }

  // Execute instructions until the function returns
  // This is a mini-execution loop similar to the main execute() function
  let mut instruction_count = 0
  while state.call_depth() > initial_depth {
    instruction_count = instruction_count + 1
    if instruction_count > 100 {
      raise VMError::RuntimeError(message="Too many instructions in metamethod (possible infinite loop)")
    }

    let frame = state.current_frame() catch {
      _ => raise VMError::RuntimeError(message="No active frame in metamethod call")
    }

    // Check if we've finished executing this frame
    if frame.pc >= frame.func.code.length() {
      // Implicit return at end of function
      execute_return(state, frame.base, 1)
      continue
    }

    let instr = frame.func.code[frame.pc]
    let constants = frame.func.constants

    // Execute instruction
    let result = execute_instruction(state, instr, constants, frame.base)

    // Update PC based on execution result
    match result {
      ExecutionResult::Continue =>
        state.update_pc(frame.pc + 1) catch {
          _ => raise VMError::RuntimeError(message="Failed to update PC in metamethod")
        }
      ExecutionResult::Jump(offset) =>
        state.update_pc(frame.pc + 1 + offset) catch {
          _ => raise VMError::RuntimeError(message="Failed to jump in metamethod")
        }
      ExecutionResult::Call => {
        // Nested call - just continue with the new frame
        ()
      }
      ExecutionResult::Return => {
        // Return handled, will exit loop if back to initial depth
        ()
      }
    }
  }

  // Collect results from the stack
  // Results should be at call_base + 1 onwards
  let results : Array[@value.TValue] = []

  // Try to get at least one result, more if available
  // We'll collect all non-nil results starting from call_base + 1
  for i = 0; i < 10; i = i + 1 {  // Arbitrary limit of 10 results
    let val = state.get(call_base + 1 + i) catch {
      _ => break  // Can't read more results
    }
    // Stop at first nil (unless it's the only result)
    if val.is_nil() && i > 0 {
      break
    }
    results.push(val)
    if val.is_nil() {
      break  // Stop after first nil
    }
  }

  // Clean up stack - remove function, args, and results
  // Reset stack to where it was before the call
  while state.stack_size() > call_base {
    ignore(state.pop() catch { _ => @value.TValue::nil() })
  }

  results
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

      // Calculate argument count
      // B=0 means variable arguments (use all values from R[A+1] to stack top)
      // B>0 means B-1 arguments
      let arg_count = if b == 0 {
        // Variable arguments: count from R[A+1] to stack top
        // Function is at base + a (stack position), Lua index base + a + 1
        // Arguments start at Lua index base + a + 2
        // Stack top is at Lua index stack_size
        // Number of arguments = stack_size - (base + a + 2) + 1 = stack_size - base - a - 1
        state.stack_size() - base - a - 1
      } else {
        b - 1
      }
      let param_count = func.param_count

      // For vararg functions: registers start after all arguments to prevent overwriting
      // For normal functions: registers start after the function
      let new_base = if func.is_vararg {
        base + a + 1 + arg_count
      } else {
        base + a + 1
      }

      // Ensure stack space for new frame
      let max_register = calculate_max_register(func.code)
      // Need stack_size > base + max_register + 1 for register writes
      // Since base == new_base, allocate to new_base + max_register + 2
      while state.stack_size() <= new_base + max_register + 1 {
        state.push(@value.TValue::nil())
      }

      // For vararg functions with special layout (new_base after args):
      // Copy named parameters from argument positions to register positions
      if func.is_vararg {
        // Arguments are at base + a + 1 + i, but registers are at new_base + i + 1
        // Copy named parameters to their register positions
        for i = 0; i < param_count && i < arg_count; i = i + 1 {
          let arg_pos = base + a + 1 + i
          let reg_pos = new_base + i + 1
          let val = state.get(arg_pos + 1) catch { _ => @value.TValue::nil() }
          state.set(reg_pos, val) catch { _ => () }
        }
      }

      // Initialize missing parameters to nil
      for i = arg_count; i < param_count; i = i + 1 {
        state.set(new_base + i + 1, @value.TValue::nil()) catch {
          _ => ()  // Ignore errors
        }
      }

      // Push new call frame
      state.push_frame(func, new_base, c, arg_count) catch {
        _ => raise VMError::RuntimeError(message="Failed to push call frame")
      }
      ExecutionResult::Call
    }
    // Native function - call directly
    @value.TValue::NativeFunction(nfunc) => {
      execute_native_call(state, nfunc.name, a, b, c, base)
      ExecutionResult::Continue  // Native function executed inline, just continue
    }
    _ => {
      // Check for __call metamethod
      match get_value_metamethod(func_val, "__call") {
        Some(@value.TValue::NativeFunction(nfunc)) => {
          // Call the native __call metamethod
          // __call receives the object as first argument, followed by call arguments
          // So we need to insert func_val as first argument

          // Calculate argument count
          let arg_count = if b == 0 {
            state.stack_size() - base - a - 1
          } else {
            b - 1
          }

          // Collect arguments including the object itself
          let call_args : Array[@value.TValue] = [func_val]  // Object is first arg
          for i = 0; i < arg_count; i = i + 1 {
            let arg = state.get(base + a + 2 + i) catch {
              _ => @value.TValue::nil()
            }
            call_args.push(arg)
          }

          // Call the metamethod
          let results = call_native_function(state, nfunc.name, call_args)

          // Store results starting at R[A]
          for i = 0; i < results.length(); i = i + 1 {
            state.set(base + a + 1 + i, results[i]) catch {
              _ => ()
            }
          }

          ExecutionResult::Continue
        }
        Some(@value.TValue::Function(func)) => {
          // Call the bytecode __call metamethod
          // __call receives the object as first argument, followed by call arguments

          // Calculate argument count
          let arg_count = if b == 0 {
            state.stack_size() - base - a - 1
          } else {
            b - 1
          }

          // Collect arguments including the object itself
          let call_args : Array[@value.TValue] = [func_val]  // Object is first arg
          for i = 0; i < arg_count; i = i + 1 {
            let arg = state.get(base + a + 2 + i) catch {
              _ => @value.TValue::nil()
            }
            call_args.push(arg)
          }

          // Call the metamethod
          let results = call_bytecode_function(state, func, call_args)

          // Store results starting at R[A]
          for i = 0; i < results.length(); i = i + 1 {
            state.set(base + a + 1 + i, results[i]) catch {
              _ => ()
            }
          }

          ExecutionResult::Continue
        }
        _ => {
          // No __call metamethod, raise error
          raise VMError::InvalidOperation(
            message="Attempt to call non-function value",
          )
        }
      }
    }
  }
}

///|
/// Get a metamethod from a table's metatable
/// Returns Some(metamethod) if found, None otherwise
fn get_metamethod(table : @value.Table, method_name : String) -> @value.TValue? {
  let metatable = table.get_metatable()
  match metatable {
    @value.TValue::Table(mt) => {
      let method = mt.get_string(method_name)
      match method {
        @value.TValue::Nil => None
        _ => Some(method)
      }
    }
    _ => None
  }
}

///|
/// Get a metamethod from any value's metatable
/// Returns Some(metamethod) if found, None otherwise
fn get_value_metamethod(value : @value.TValue, method_name : String) -> @value.TValue? {
  match value {
    @value.TValue::Table(t) => get_metamethod(t, method_name)
    _ => None  // Other types don't support metatables yet
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

  // Close any open upvalues for this frame's stack
  // This captures local variables that are being closed over
  state.close_upvalues(frame.base) catch {
    _ => ()  // Ignore errors during upvalue closing
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
  // Calculate where the function was in the caller (where to write return values)
  // Result should be a Lua index (1-based) for use with state.set()
  // For vararg functions: base is AFTER arguments, so function Lua index = base - arg_count
  // For non-vararg functions: base is AT function + 1, so function Lua index = base
  let return_pos = if frame.func.is_vararg {
    frame.base - frame.arg_count
  } else {
    frame.base
  }

  // In Lua, B=0 in RETURN means "return all values from R[A] to top of stack"
  // B>0 means return B values
  let actual_count = if count == 0 {
    // B=0: Return all values from start to top of stack
    // Stack positions are 1-indexed in our get/set, so calculate count
    let stack_top = state.stack_size()
    if stack_top > start {
      stack_top - start
    } else {
      1  // At least return nil
    }
  } else {
    count
  }

  for i = 0; i < actual_count; i = i + 1 {
    let val = if count == 0 || i < count {
      // B=0 means return all values, or i is within explicit count
      state.get(start + i + 1) catch {
        _ => @value.TValue::nil()
      }
    } else {
      // i >= count (only happens when count > 0 and we need to pad with nils)
      @value.TValue::nil()
    }
    // Results are placed starting at the function position in caller
    state.set(return_pos + i, val) catch {
      _ =>
        raise VMError::RuntimeError(message="Failed to write return value at index \{return_pos + i}, stack_size=\{state.stack_size()}, return_pos=\{return_pos}, i=\{i}")
    }
  }
}
