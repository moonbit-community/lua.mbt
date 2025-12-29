// Lua Bytecode Compiler Implementation
// Based on Lua 5.4's lcode.c
// Compiles AST to bytecode

///|
/// Local variable information
struct LocalVar {
  name : String
  register : Int
} derive(Show)

///|
/// Compiler state
pub struct Compiler {
  // Generated instructions
  code : Array[@opcodes.Instruction]

  // Constant pool
  constants : Array[@value.TValue]

  // Local variables (name -> register)
  locals : Array[LocalVar]

  // Next free register
  mut next_register : Int
} derive(Show)

///|
/// Create a new compiler
pub fn Compiler::new() -> Compiler {
  Compiler::{ code: [], constants: [], locals: [], next_register: 0 }
}

///|
/// Allocate a new register
fn Compiler::alloc_register(self : Compiler) -> Int {
  let reg = self.next_register
  self.next_register = self.next_register + 1
  reg
}

///|
/// Free the last allocated register
fn Compiler::free_register(self : Compiler) -> Unit {
  if self.next_register > 0 {
    self.next_register = self.next_register - 1
  }
}

///|
/// Add a constant to the pool and return its index
fn Compiler::add_constant(
  self : Compiler,
  value : @value.TValue,
) -> Int raise CompileError {
  // Check if constant already exists
  for i, c in self.constants {
    if c.equal(value) {
      return i
    }
  }

  // Add new constant
  let index = self.constants.length()
  if index > 65535 {
    raise CompileError::TooManyConstants(line=0)
  }
  self.constants.push(value)
  index
}

///|
/// Look up a local variable by name
fn Compiler::find_local(self : Compiler, name : String) -> Int? {
  for loc in self.locals {
    if loc.name == name {
      return Some(loc.register)
    }
  }
  None
}

///|
/// Register a new local variable
fn Compiler::add_local(
  self : Compiler,
  name : String,
) -> Int raise CompileError {
  let reg = self.alloc_register()
  if reg > 255 {
    raise CompileError::TooManyLocals(line=0)
  }
  self.locals.push(LocalVar::{ name, register: reg })
  reg
}

///|
/// Emit an instruction
fn Compiler::emit(self : Compiler, instr : @opcodes.Instruction) -> Unit {
  self.code.push(instr)
}

///|
/// Compile a statement into bytecode
pub fn Compiler::compile_stmt(
  self : Compiler,
  stmt : @parse.Stmt,
) -> Unit raise CompileError {
  match stmt {
    @parse.Stmt::Block(stmts) =>
      for s in stmts {
        self.compile_stmt(s)
      }
    @parse.Stmt::LocalDecl(names, values) => {
      // Compile values first
      let value_regs : Array[Int] = []
      for value in values {
        let reg = self.compile_expr(value)
        value_regs.push(reg)
      }

      // Register locals and move values
      for i, name in names {
        let local_reg = self.add_local(name)
        if i < value_regs.length() {
          // Move value to local register
          let value_reg = value_regs[i]
          if value_reg != local_reg {
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::Move,
                local_reg,
                value_reg,
                0,
                false,
              ),
            )
          }
        } else {
          // Initialize to nil
          self.emit(
            @opcodes.Instruction::abc(
              @opcodes.OpCode::LoadNil,
              local_reg,
              0,
              0,
              false,
            ),
          )
        }
      }
    }
    @parse.Stmt::Assign(lvals, rvals) =>
      // Simplified: only handle single assignment to local variable
      if lvals.length() == 1 && rvals.length() == 1 {
        match lvals[0] {
          @parse.Expr::Name(name) => {
            let value_reg = self.compile_expr(rvals[0])
            match self.find_local(name) {
              Some(target_reg) =>
                if value_reg != target_reg {
                  self.emit(
                    @opcodes.Instruction::abc(
                      @opcodes.OpCode::Move,
                      target_reg,
                      value_reg,
                      0,
                      false,
                    ),
                  )
                }
              None => raise CompileError::UndefinedVariable(name~, line=0)
            }
          }
          _ => () // Ignore complex lvalues for now
        }
      }
    _ => () // Ignore other statements for now
  }
}

///|
/// Compile an expression and return the register containing the result
pub fn Compiler::compile_expr(
  self : Compiler,
  expr : @parse.Expr,
) -> Int raise CompileError {
  match expr {
    @parse.Expr::Nil => {
      let reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(@opcodes.OpCode::LoadNil, reg, 0, 0, false),
      )
      reg
    }
    @parse.Expr::Bool(b) => {
      let reg = self.alloc_register()
      let opcode = if b {
        @opcodes.OpCode::LoadTrue
      } else {
        @opcodes.OpCode::LoadFalse
      }
      self.emit(@opcodes.Instruction::abc(opcode, reg, 0, 0, false))
      reg
    }
    @parse.Expr::Number(n) => {
      let reg = self.alloc_register()
      let const_index = self.add_constant(@value.TValue::number(n))
      self.emit(
        @opcodes.Instruction::abx(@opcodes.OpCode::LoadK, reg, const_index),
      )
      reg
    }
    @parse.Expr::String(s) => {
      let reg = self.alloc_register()
      let const_index = self.add_constant(@value.TValue::string(s))
      self.emit(
        @opcodes.Instruction::abx(@opcodes.OpCode::LoadK, reg, const_index),
      )
      reg
    }
    @parse.Expr::Name(name) =>
      match self.find_local(name) {
        Some(local_reg) => local_reg
        None => raise CompileError::UndefinedVariable(name~, line=0)
      }
    @parse.Expr::Add(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Add,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Sub(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Sub,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Mul(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Mul,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Div(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Div,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Mod(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Mod,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Pow(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Pow,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Not(operand) => {
      let operand_reg = self.compile_expr(operand)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Not,
          result_reg,
          operand_reg,
          0,
          false,
        ),
      )
      result_reg
    }
    _ => {
      // For unimplemented expressions, just return a nil
      let reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(@opcodes.OpCode::LoadNil, reg, 0, 0, false),
      )
      reg
    }
  }
}

///|
/// Finalize and get the compiled prototype
pub fn Compiler::finish(self : Compiler) -> @vm.Proto {
  @vm.Proto::new(self.code, self.constants)
}

///|
/// Compile a complete Lua chunk to bytecode
pub fn compile(stmt : @parse.Stmt) -> @vm.Proto raise CompileError {
  let compiler = Compiler::new()
  compiler.compile_stmt(stmt)
  compiler.finish()
}
