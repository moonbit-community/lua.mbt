// Lua VM Opcodes Specification
// Based on Lua 5.4's lopcodes.h
// Instructions are 32-bit unsigned integers with various encoding formats

///|
/// Instruction encoding formats
pub(all) enum OpMode {
  ABC // A(8) | k(1) | B(8) | C(8) | Op(7)
  VABC // A(8) | k(1) | vB(6) | vC(10) | Op(7)
  ABx // A(8) | Bx(17) | Op(7)
  AsBx // A(8) | sBx(17 signed) | Op(7)
  Ax // Ax(25) | Op(7)
  SJ // sJ(25 signed) | Op(7)
} derive(Eq, Show, ToJson)

///|
/// Lua VM opcodes (subset for initial implementation)
pub(all) enum OpCode {
  // Load/Store
  Move // R[A] := R[B]
  LoadK // R[A] := K[Bx]
  LoadKX // R[A] := K[extra arg]
  LoadFalse // R[A] := false
  LoadTrue // R[A] := true
  LoadNil // R[A], R[A+1], ..., R[A+B] := nil

  // Arithmetic
  Add // R[A] := R[B] + R[C]
  Sub // R[A] := R[B] - R[C]
  Mul // R[A] := R[B] * R[C]
  Div // R[A] := R[B] / R[C]
  Mod // R[A] := R[B] % R[C]
  Pow // R[A] := R[B] ^ R[C]
  Unm // R[A] := -R[B]

  // Bitwise
  BNot // R[A] := ~R[B]
  BAnd // R[A] := R[B] & R[C]
  BOr // R[A] := R[B] | R[C]
  BXor // R[A] := R[B] ~ R[C]
  Shl // R[A] := R[B] << R[C]
  Shr // R[A] := R[B] >> R[C]

  // Comparison/Logic
  Eq // if (R[A] == R[B]) != k then pc++
  Lt // if (R[A] < R[B]) != k then pc++
  Le // if (R[A] <= R[B]) != k then pc++
  Not // R[A] := not R[B]

  // Control flow
  Jmp // pc += sJ
  Return // return R[A], ..., R[A+B-1]
  Call // R[A], ..., R[A+C-2] := R[A](R[A+1], ..., R[A+B-1])

  // Tables
  NewTable // R[A] := {}
  GetTable // R[A] := R[B][R[C]]
  SetTable // R[A][R[B]] := R[C]

  // Closure/Upvalues
  Closure // R[A] := closure(KPROTO[Bx])
  GetUpval // R[A] := UpValue[B]
  SetUpval // UpValue[B] := R[A]

  // Globals
  GetGlobal // R[A] := Globals[K[Bx]]
  SetGlobal // Globals[K[Bx]] := R[A]
} derive(Eq, Show, ToJson)

///|
/// 32-bit instruction type
#declaration_only
pub type Instruction

///|
/// Create an ABC format instruction
#declaration_only
pub fn Instruction::abc(
  op : OpCode,
  a : Int,
  b : Int,
  c : Int,
  k : Bool,
) -> Instruction {
  ...
}

///|
/// Create an ABx format instruction
#declaration_only
pub fn Instruction::abx(op : OpCode, a : Int, bx : Int) -> Instruction {
  ...
}

///|
/// Create an AsBx format instruction
#declaration_only
pub fn Instruction::asbx(op : OpCode, a : Int, sbx : Int) -> Instruction {
  ...
}

///|
/// Create an Ax format instruction
#declaration_only
pub fn Instruction::ax(op : OpCode, ax : Int) -> Instruction {
  ...
}

///|
/// Create an sJ format instruction
#declaration_only
pub fn Instruction::sj(op : OpCode, sj : Int) -> Instruction {
  ...
}

///|
/// Extract opcode from instruction
#declaration_only
pub fn Instruction::get_opcode(self : Instruction) -> OpCode {
  ...
}

///|
/// Extract A field from instruction
#declaration_only
pub fn Instruction::get_a(self : Instruction) -> Int {
  ...
}

///|
/// Extract B field from ABC instruction
#declaration_only
pub fn Instruction::get_b(self : Instruction) -> Int {
  ...
}

///|
/// Extract C field from ABC instruction
#declaration_only
pub fn Instruction::get_c(self : Instruction) -> Int {
  ...
}

///|
/// Extract k (constant) flag from instruction
#declaration_only
pub fn Instruction::get_k(self : Instruction) -> Bool {
  ...
}

///|
/// Extract Bx field from ABx instruction
#declaration_only
pub fn Instruction::get_bx(self : Instruction) -> Int {
  ...
}

///|
/// Extract sBx field from AsBx instruction
#declaration_only
pub fn Instruction::get_sbx(self : Instruction) -> Int {
  ...
}

///|
/// Extract Ax field from Ax instruction
#declaration_only
pub fn Instruction::get_ax(self : Instruction) -> Int {
  ...
}

///|
/// Extract sJ field from sJ instruction
#declaration_only
pub fn Instruction::get_sj(self : Instruction) -> Int {
  ...
}

///|
/// Get the encoding format of an opcode
#declaration_only
pub fn op_mode(op : OpCode) -> OpMode {
  ...
}
