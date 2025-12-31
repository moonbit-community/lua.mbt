// Basic tests for Lua VM execution

///|
test "execute simple MOVE instruction" {
  let state = @state.LuaState::new()
  state.push(@value.TValue::integer(42L))
  state.push(@value.TValue::nil())
  let instr = @opcodes.Instruction::abc(@opcodes.OpCode::Move, 1, 0, 0, false)
  ignore(try! execute_instruction(state, instr, [], 0))
  let val = try! state.get(2)
  inspect(try? val.to_integer(), content="Ok(42)")
}

///|
test "execute LOADK instruction" {
  let state = @state.LuaState::new()
  let constants = [@value.TValue::integer(100L)]

  // Push a placeholder on stack for register 0
  state.push(@value.TValue::nil())
  let instr = @opcodes.Instruction::abx(@opcodes.OpCode::LoadK, 0, 0)
  ignore(try! execute_instruction(state, instr, constants, 0))
  let val = try! state.get(1)
  inspect(try? val.to_integer(), content="Ok(100)")
}

///|
test "execute ADD instruction" {
  let state = @state.LuaState::new()
  state.push(@value.TValue::integer(10L)) // R[0]
  state.push(@value.TValue::integer(20L)) // R[1]
  state.push(@value.TValue::nil()) // R[2] - result
  let instr = @opcodes.Instruction::abc(@opcodes.OpCode::Add, 2, 0, 1, false)
  ignore(try! execute_instruction(state, instr, [], 0))
  let result = try! state.get(3)
  inspect(try? result.to_integer(), content="Ok(30)")
}

///|
test "execute bytecode function" {
  let code = [
    @opcodes.Instruction::abx(@opcodes.OpCode::LoadK, 0, 0),
    @opcodes.Instruction::abx(@opcodes.OpCode::LoadK, 1, 1),
    @opcodes.Instruction::abc(@opcodes.OpCode::Add, 2, 0, 1, false),
  ]
  let constants = [@value.TValue::integer(5L), @value.TValue::integer(3L)]
  let proto = Proto::new(code, constants, [])
  let state = @state.LuaState::new()
  try! execute(state, proto)

  // Result should be in register 2
  assert_true(state.stack_size() >= 3)
}
