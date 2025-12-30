// Lua VM Opcodes Implementation
// Based on Lua 5.4's lopcodes.h
// Implements 32-bit instruction encoding and decoding

// Bit field positions and sizes (from Lua 5.4 lopcodes.h)

///|
let size_op : Int = 7

///|
let size_a : Int = 8

///|
let size_b : Int = 8

///|
let size_c : Int = 8

///|
let size_bx : Int = 17 // SIZE_C + SIZE_B + 1

///|
let size_ax : Int = 25 // SIZE_Bx + SIZE_A

///|
let size_sj : Int = 25 // SIZE_Bx + SIZE_A

///|
let pos_op : Int = 0

///|
let pos_a : Int = 7 // POS_OP + SIZE_OP

///|
let pos_k : Int = 15 // POS_A + SIZE_A

///|
let pos_b : Int = 16 // POS_k + 1

///|
let pos_c : Int = 24 // POS_B + SIZE_B

///|
let pos_bx : Int = 15 // POS_k

///|
let pos_ax : Int = 7 // POS_A

///|
let pos_sj : Int = 7 // POS_A

// Offsets for signed arguments (excess K encoding)

///|
let offset_sbx : Int = 65535 // ((1 << 17) - 1) >> 1

///|
let offset_sj : Int = 16777215 // ((1 << 25) - 1) >> 1

///|
/// 32-bit instruction representation
pub struct Instruction {
  bits : UInt
} derive(Eq, Show)

///|
/// Helper: Create a bitmask with n 1-bits starting at position p
fn mask(n : Int, p : Int) -> UInt {
  let one = (1).reinterpret_as_uint()
  ((one << n) - one) << p
}

///|
/// Helper: Set a field in the instruction
fn set_field(bits : UInt, value : Int, pos : Int, size : Int) -> UInt {
  let m = mask(size, pos)
  (bits & m.lnot()) | ((value.reinterpret_as_uint() << pos) & m)
}

///|
/// Helper: Get a field from the instruction
fn get_field(bits : UInt, pos : Int, size : Int) -> Int {
  ((bits >> pos) & mask(size, 0)).reinterpret_as_int()
}

///|
/// Helper: Map OpCode to integer
pub fn opcode_to_int(op : OpCode) -> Int {
  match op {
    Move => 0
    LoadK => 1
    LoadKX => 2
    LoadFalse => 3
    LoadTrue => 4
    LoadNil => 5
    Add => 6
    Sub => 7
    Mul => 8
    Div => 9
    Mod => 10
    Pow => 11
    Unm => 12
    BNot => 13
    BAnd => 14
    BOr => 15
    BXor => 16
    Shl => 17
    Shr => 18
    Eq => 19
    Lt => 20
    Le => 21
    Not => 22
    Jmp => 23
    Return => 24
    Call => 25
    NewTable => 26
    GetTable => 27
    SetTable => 28
    Closure => 29
    GetUpval => 30
    SetUpval => 31
    GetGlobal => 32
    SetGlobal => 33
  }
}

///|
/// Helper: Map integer to OpCode
fn int_to_opcode(i : Int) -> OpCode {
  match i {
    0 => OpCode::Move
    1 => OpCode::LoadK
    2 => OpCode::LoadKX
    3 => OpCode::LoadFalse
    4 => OpCode::LoadTrue
    5 => OpCode::LoadNil
    6 => OpCode::Add
    7 => OpCode::Sub
    8 => OpCode::Mul
    9 => OpCode::Div
    10 => OpCode::Mod
    11 => OpCode::Pow
    12 => OpCode::Unm
    13 => OpCode::BNot
    14 => OpCode::BAnd
    15 => OpCode::BOr
    16 => OpCode::BXor
    17 => OpCode::Shl
    18 => OpCode::Shr
    19 => OpCode::Eq
    20 => OpCode::Lt
    21 => OpCode::Le
    22 => OpCode::Not
    23 => OpCode::Jmp
    24 => OpCode::Return
    25 => OpCode::Call
    26 => OpCode::NewTable
    27 => OpCode::GetTable
    28 => OpCode::SetTable
    29 => OpCode::Closure
    30 => OpCode::GetUpval
    31 => OpCode::SetUpval
    32 => OpCode::GetGlobal
    33 => OpCode::SetGlobal
    _ => OpCode::Move // Default fallback
  }
}

///|
/// Create an ABC format instruction
pub fn Instruction::abc(
  op : OpCode,
  a : Int,
  b : Int,
  c : Int,
  k : Bool,
) -> Instruction {
  let zero = (0).reinterpret_as_uint()
  let mut bits = zero
  bits = set_field(bits, opcode_to_int(op), pos_op, size_op)
  bits = set_field(bits, a, pos_a, size_a)
  bits = set_field(bits, if k { 1 } else { 0 }, pos_k, 1)
  bits = set_field(bits, b, pos_b, size_b)
  bits = set_field(bits, c, pos_c, size_c)
  Instruction::{ bits, }
}

///|
/// Create an ABx format instruction
pub fn Instruction::abx(op : OpCode, a : Int, bx : Int) -> Instruction {
  let zero = (0).reinterpret_as_uint()
  let mut bits = zero
  bits = set_field(bits, opcode_to_int(op), pos_op, size_op)
  bits = set_field(bits, a, pos_a, size_a)
  bits = set_field(bits, bx, pos_bx, size_bx)
  Instruction::{ bits, }
}

///|
/// Create an AsBx format instruction
pub fn Instruction::asbx(op : OpCode, a : Int, sbx : Int) -> Instruction {
  let zero = (0).reinterpret_as_uint()
  let mut bits = zero
  bits = set_field(bits, opcode_to_int(op), pos_op, size_op)
  bits = set_field(bits, a, pos_a, size_a)
  bits = set_field(bits, sbx + offset_sbx, pos_bx, size_bx)
  Instruction::{ bits, }
}

///|
/// Create an Ax format instruction
pub fn Instruction::ax(op : OpCode, ax : Int) -> Instruction {
  let zero = (0).reinterpret_as_uint()
  let mut bits = zero
  bits = set_field(bits, opcode_to_int(op), pos_op, size_op)
  bits = set_field(bits, ax, pos_ax, size_ax)
  Instruction::{ bits, }
}

///|
/// Create an sJ format instruction
pub fn Instruction::sj(op : OpCode, sj : Int) -> Instruction {
  let zero = (0).reinterpret_as_uint()
  let mut bits = zero
  bits = set_field(bits, opcode_to_int(op), pos_op, size_op)
  bits = set_field(bits, sj + offset_sj, pos_sj, size_sj)
  Instruction::{ bits, }
}

///|
/// Extract opcode from instruction
pub fn Instruction::get_opcode(self : Instruction) -> OpCode {
  let op = get_field(self.bits, pos_op, size_op)
  int_to_opcode(op)
}

///|
/// Extract A field from instruction
pub fn Instruction::get_a(self : Instruction) -> Int {
  get_field(self.bits, pos_a, size_a)
}

///|
/// Extract B field from ABC instruction
pub fn Instruction::get_b(self : Instruction) -> Int {
  get_field(self.bits, pos_b, size_b)
}

///|
/// Extract C field from ABC instruction
pub fn Instruction::get_c(self : Instruction) -> Int {
  get_field(self.bits, pos_c, size_c)
}

///|
/// Extract k (constant) flag from instruction
pub fn Instruction::get_k(self : Instruction) -> Bool {
  get_field(self.bits, pos_k, 1) != 0
}

///|
/// Extract Bx field from ABx instruction
pub fn Instruction::get_bx(self : Instruction) -> Int {
  get_field(self.bits, pos_bx, size_bx)
}

///|
/// Extract sBx field from AsBx instruction
pub fn Instruction::get_sbx(self : Instruction) -> Int {
  get_field(self.bits, pos_bx, size_bx) - offset_sbx
}

///|
/// Extract Ax field from Ax instruction
pub fn Instruction::get_ax(self : Instruction) -> Int {
  get_field(self.bits, pos_ax, size_ax)
}

///|
/// Extract sJ field from sJ instruction
pub fn Instruction::get_sj(self : Instruction) -> Int {
  get_field(self.bits, pos_sj, size_sj) - offset_sj
}

///|
/// Get the encoding format of an opcode
pub fn op_mode(op : OpCode) -> OpMode {
  match op {
    // ABC format
    Move
    | Add
    | Sub
    | Mul
    | Div
    | Mod
    | Pow
    | Unm
    | BNot
    | BAnd
    | BOr
    | BXor
    | Shl
    | Shr
    | Eq
    | Lt
    | Le
    | Not
    | Call
    | GetTable
    | SetTable
    | GetUpval
    | SetUpval => OpMode::ABC
    // ABx format
    LoadK | Closure => OpMode::ABx
    // AsBx format (currently using ABx for LoadK, but could have AsBx ops)
    _ if op == OpCode::LoadKX ||
      op == OpCode::LoadFalse ||
      op == OpCode::LoadTrue ||
      op == OpCode::LoadNil ||
      op == OpCode::NewTable => OpMode::ABC
    // sJ format
    Jmp | Return => OpMode::SJ
    // Default to ABC
    _ => OpMode::ABC
  }
}
