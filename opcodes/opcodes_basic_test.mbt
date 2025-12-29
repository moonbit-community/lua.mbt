// Basic tests for Lua opcodes and instruction encoding

///|
test "create ABC instruction" {
  let instr = Instruction::abc(OpCode::Add, 1, 2, 3, false)
  @json.inspect(instr.get_opcode(), content="Add")
  inspect(instr.get_a(), content="1")
  inspect(instr.get_b(), content="2")
  inspect(instr.get_c(), content="3")
  assert_false(instr.get_k())
}

///|
test "create ABx instruction" {
  let instr = Instruction::abx(OpCode::LoadK, 0, 100)
  @json.inspect(instr.get_opcode(), content="LoadK")
  inspect(instr.get_a(), content="0")
  inspect(instr.get_bx(), content="100")
}

///|
test "create AsBx instruction" {
  let instr = Instruction::asbx(OpCode::LoadK, 1, -50)
  @json.inspect(instr.get_opcode(), content="LoadK")
  inspect(instr.get_a(), content="1")
  inspect(instr.get_sbx(), content="-50")
}

///|
test "create sJ instruction for jumps" {
  let instr = Instruction::sj(OpCode::Jmp, 100)
  @json.inspect(instr.get_opcode(), content="Jmp")
  inspect(instr.get_sj(), content="100")
}

///|
test "opcode modes" {
  @json.inspect(op_mode(OpCode::Add), content="ABC")
  @json.inspect(op_mode(OpCode::LoadK), content="ABx")
  @json.inspect(op_mode(OpCode::Jmp), content="SJ")
}
