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
/// Jump label for backpatching
struct JumpLabel {
  pc : Int // -1 means not yet defined
  patches : Array[Int] // Instruction positions to patch
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

  // Jump labels for control flow
  jump_labels : Array[JumpLabel]
} derive(Show)

///|
/// Create a new compiler
pub fn Compiler::new() -> Compiler {
  Compiler::{
    code: [],
    constants: [],
    locals: [],
    next_register: 0,
    jump_labels: [],
  }
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
/// Get current code position (PC)
fn Compiler::current_pc(self : Compiler) -> Int {
  self.code.length()
}

///|
/// Emit a jump instruction with placeholder, returns the patch position
fn Compiler::emit_jump(self : Compiler) -> Int {
  let pos = self.current_pc()
  // Emit jump with 0 offset, to be patched later
  self.emit(@opcodes.Instruction::asbx(@opcodes.OpCode::Jmp, 0, 0))
  pos
}

///|
/// Patch a jump instruction at given position to jump to current PC
fn Compiler::patch_jump(self : Compiler, pos : Int) -> Unit {
  let offset = self.current_pc() - pos - 1
  self.code[pos] = @opcodes.Instruction::asbx(@opcodes.OpCode::Jmp, 0, offset)
}

///|
/// Patch a jump instruction to jump to specific target
fn Compiler::patch_jump_to(
  self : Compiler,
  pos : Int,
  target : Int,
) -> Unit {
  let offset = target - pos - 1
  self.code[pos] = @opcodes.Instruction::asbx(@opcodes.OpCode::Jmp, 0, offset)
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
      // Simplified: only handle single assignment
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
          @parse.Expr::Index(table_expr, index_expr) => {
            // Table index assignment: table[index] = value
            let table_reg = self.compile_expr(table_expr)
            let index_reg = self.compile_expr(index_expr)
            let value_reg = self.compile_expr(rvals[0])
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::SetTable,
                table_reg,
                index_reg,
                value_reg,
                false,
              ),
            )
          }
          @parse.Expr::Field(table_expr, field_name) => {
            // Table field assignment: table.field = value
            let table_reg = self.compile_expr(table_expr)

            let field_reg = self.alloc_register()
            let const_idx = self.add_constant(@value.TValue::string(field_name))
            self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, field_reg, const_idx))

            let value_reg = self.compile_expr(rvals[0])
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::SetTable,
                table_reg,
                field_reg,
                value_reg,
                false,
              ),
            )
          }
          _ => () // Ignore complex lvalues for now
        }
      }
    @parse.Stmt::If(condition, then_block, else_block) => {
      // Compile condition
      let cond_reg = self.compile_expr(condition)

      // Emit comparison: if condition is false, skip then block
      // Use a true constant for comparison
      let true_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(@opcodes.OpCode::LoadTrue, true_reg, 0, 0, false),
      )

      // Test if condition == true, skip if not
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          cond_reg,
          true_reg,
          0,
          false, // k=false means skip if condition != true
        ),
      )
      let then_jump = self.emit_jump() // Jump over then block if false

      // Compile then block
      self.compile_stmt(then_block)

      // Handle else block
      match else_block {
        Some(else_stmt) => {
          let else_jump = self.emit_jump() // Jump over else block after then
          self.patch_jump(then_jump) // Patch to jump to else
          self.compile_stmt(else_stmt)
          self.patch_jump(else_jump) // Patch to jump past else
        }
        None => self.patch_jump(then_jump) // No else, just patch to end
      }
    }
    @parse.Stmt::While(condition, body) => {
      // Save loop start position
      let loop_start = self.current_pc()

      // Compile condition
      let cond_reg = self.compile_expr(condition)

      // Use a true constant for comparison
      let true_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(@opcodes.OpCode::LoadTrue, true_reg, 0, 0, false),
      )

      // If condition != true, exit loop
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          cond_reg,
          true_reg,
          0,
          false, // Skip if false
        ),
      )
      let exit_jump = self.emit_jump()

      // Compile body
      self.compile_stmt(body)

      // Jump back to loop start
      self.patch_jump_to(self.emit_jump(), loop_start)

      // Patch exit jump to current position
      self.patch_jump(exit_jump)
    }
    @parse.Stmt::For(var_name, start_expr, end_expr, step_expr, body) => {
      // Numeric for loop: for var = start, end, step do body end
      // Compile start, end, step
      let start_reg = self.compile_expr(start_expr)
      let end_reg = self.compile_expr(end_expr)
      let step_reg = match step_expr {
        Some(step) => self.compile_expr(step)
        None => {
          // Default step is 1
          let reg = self.alloc_register()
          let const_idx = self.add_constant(@value.TValue::integer(1L))
          self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, reg, const_idx))
          reg
        }
      }

      // Create loop variable
      let var_reg = self.add_local(var_name)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          var_reg,
          start_reg,
          0,
          false,
        ),
      )

      // Loop start
      let loop_start = self.current_pc()

      // Check if var <= end (for positive step)
      // TODO: This is simplified, real Lua handles negative steps
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          var_reg,
          end_reg,
          0,
          true, // k=true means skip if var <= end is true (inverted logic)
        ),
      )
      let exit_jump = self.emit_jump()

      // Compile body
      self.compile_stmt(body)

      // Increment variable: var = var + step
      let temp_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Add,
          temp_reg,
          var_reg,
          step_reg,
          false,
        ),
      )
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          var_reg,
          temp_reg,
          0,
          false,
        ),
      )

      // Jump back to loop start
      self.patch_jump_to(self.emit_jump(), loop_start)

      // Patch exit jump
      self.patch_jump(exit_jump)

      // Pop loop variable from locals
      // TODO: Proper scope management
    }
    @parse.Stmt::FunctionDef(name, params, is_vararg, body) => {
      // Compile function body in a new compiler
      let func_compiler = Compiler::new()

      // Register parameters as locals (starting at register 0)
      for param in params {
        func_compiler.add_local(param) |> ignore
      }

      // Compile function body
      func_compiler.compile_stmt(body)

      // Get the function code and constants
      let proto = func_compiler.finish()
      let func_value = @value.FunctionValue::new(proto.code(), proto.constants)

      // Add function to constants
      let func_const_idx = self.add_constant(@value.TValue::function(func_value))

      // For global functions, emit SetGlobal instruction
      let temp_reg = self.alloc_register()
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, temp_reg, func_const_idx))

      // Add function name to constants for SetGlobal
      let name_const_idx = self.add_constant(@value.TValue::string(name))
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::SetGlobal, temp_reg, name_const_idx))
    }
    @parse.Stmt::LocalFunctionDef(name, params, is_vararg, body) => {
      // Similar to FunctionDef but creates a local immediately
      // Register function name first (for outer scope)
      let func_reg = self.add_local(name)

      // Compile function body
      let func_compiler = Compiler::new()

      // Register parameters as locals (starting at register 0)
      // Note: Recursion won't work yet - needs upvalues/closures
      for param in params {
        func_compiler.add_local(param) |> ignore
      }

      // Compile function body
      func_compiler.compile_stmt(body)

      // Get the function code and constants
      let proto = func_compiler.finish()
      let func_value = @value.FunctionValue::new(proto.code(), proto.constants)

      // Add function to constants and load it
      let const_idx = self.add_constant(@value.TValue::function(func_value))
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, func_reg, const_idx))
    }
    @parse.Stmt::FunctionCall(func_expr, args) => {
      // Compile function call as a statement (ignore return values)
      // Compile function expression
      let func_reg = self.compile_expr(func_expr)

      // Compile arguments and place them after function
      let arg_count = args.length()
      for i = 0; i < arg_count; i = i + 1 {
        let arg_reg = self.compile_expr(args[i])
        let expected_reg = func_reg + i + 1

        // If argument isn't in the expected position, move it
        if arg_reg != expected_reg {
          self.emit(
            @opcodes.Instruction::abc(
              @opcodes.OpCode::Move,
              expected_reg,
              arg_reg,
              0,
              false,
            ),
          )
          // Ensure next_register is past this position
          while self.next_register <= expected_reg {
            self.next_register = self.next_register + 1
          }
        }
      }

      // Emit CALL instruction: CALL func_reg arg_count result_count
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Call,
          func_reg,
          arg_count,
          0, // 0 means no return values expected for statement
          false,
        ),
      )
    }
    @parse.Stmt::Return(exprs) => {
      // Compile return values
      let return_count = exprs.length()
      let mut start_reg = 0

      if return_count > 0 {
        // Compile first return value to know starting register
        start_reg = self.compile_expr(exprs[0])

        // Compile remaining return values
        for i = 1; i < return_count; i = i + 1 {
          self.compile_expr(exprs[i]) |> ignore
        }
      }

      // Emit RETURN instruction
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Return,
          start_reg,
          return_count,
          0,
          false,
        ),
      )
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
        None => {
          // Not a local, try to load as global
          let reg = self.alloc_register()
          let name_const_idx = self.add_constant(@value.TValue::string(name))
          self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::GetGlobal, reg, name_const_idx))
          reg
        }
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
    @parse.Expr::Eq(left, right) => {
      // For comparisons, we need to emit a comparison instruction
      // followed by a jump, then set result to true/false
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // Emit comparison: skip next instruction if equal
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          left_reg,
          right_reg,
          0,
          true, // k=true means skip if equal
        ),
      )

      // Not equal path: set to false
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadFalse,
          result_reg,
          0,
          0,
          false,
        ),
      )

      // Jump over the true case
      let skip_true = self.emit_jump()

      // Equal path: set to true
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )

      self.patch_jump(skip_true)
      result_reg
    }
    @parse.Expr::Lt(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // Emit comparison: skip if left < right
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Lt,
          left_reg,
          right_reg,
          0,
          true, // k=true means skip if less than
        ),
      )

      // Not less than: set to false
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadFalse,
          result_reg,
          0,
          0,
          false,
        ),
      )
      let skip_true = self.emit_jump()

      // Less than: set to true
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )

      self.patch_jump(skip_true)
      result_reg
    }
    @parse.Expr::Le(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          left_reg,
          right_reg,
          0,
          true, // k=true means skip if <=
        ),
      )

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadFalse,
          result_reg,
          0,
          0,
          false,
        ),
      )
      let skip_true = self.emit_jump()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )

      self.patch_jump(skip_true)
      result_reg
    }
    @parse.Expr::Gt(left, right) => {
      // a > b is same as b < a
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Lt,
          right_reg,
          left_reg,
          0,
          true,
        ),
      )

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadFalse,
          result_reg,
          0,
          0,
          false,
        ),
      )
      let skip_true = self.emit_jump()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )

      self.patch_jump(skip_true)
      result_reg
    }
    @parse.Expr::Ge(left, right) => {
      // a >= b is same as b <= a
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          right_reg,
          left_reg,
          0,
          true,
        ),
      )

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadFalse,
          result_reg,
          0,
          0,
          false,
        ),
      )
      let skip_true = self.emit_jump()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )

      self.patch_jump(skip_true)
      result_reg
    }
    @parse.Expr::Ne(left, right) => {
      // a ~= b is same as not (a == b)
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // Emit comparison: skip if equal
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          left_reg,
          right_reg,
          0,
          true,
        ),
      )

      // Not equal: set to true
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )
      let skip_false = self.emit_jump()

      // Equal: set to false
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadFalse,
          result_reg,
          0,
          0,
          false,
        ),
      )

      self.patch_jump(skip_false)
      result_reg
    }
    @parse.Expr::Call(func_expr, args) => {
      // Compile function call expression
      // Function expression
      let func_reg = self.compile_expr(func_expr)

      // Compile arguments and ensure they're in consecutive registers after func_reg
      let arg_count = args.length()
      for i = 0; i < arg_count; i = i + 1 {
        let arg_reg = self.compile_expr(args[i])
        let expected_reg = func_reg + i + 1

        // If argument isn't in the expected position, move it
        if arg_reg != expected_reg {
          self.emit(
            @opcodes.Instruction::abc(
              @opcodes.OpCode::Move,
              expected_reg,
              arg_reg,
              0,
              false,
            ),
          )
          // Ensure next_register is past this position
          while self.next_register <= expected_reg {
            self.next_register = self.next_register + 1
          }
        }
      }

      // Emit CALL instruction: function expects 1 return value
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Call,
          func_reg,
          arg_count,
          1, // Expect 1 return value
          false,
        ),
      )

      // The result will be in func_reg position after call
      func_reg
    }
    @parse.Expr::TableConstructor(fields) => {
      // Create new table
      let table_reg = self.alloc_register()
      self.emit(@opcodes.Instruction::abc(@opcodes.OpCode::NewTable, table_reg, 0, 0, false))

      // Fill table with fields
      let mut array_index = 1
      for field in fields {
        let (key_opt, value) = field
        match key_opt {
          Some(key) => {
            // Explicit key: table[key] = value
            let key_reg = self.compile_expr(key)
            let value_reg = self.compile_expr(value)
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::SetTable,
                table_reg,
                key_reg,
                value_reg,
                false,
              ),
            )
          }
          None => {
            // Array-style: table[index] = value
            let index_reg = self.alloc_register()
            let const_idx = self.add_constant(@value.TValue::integer(array_index.to_int64()))
            self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, index_reg, const_idx))

            let value_reg = self.compile_expr(value)
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::SetTable,
                table_reg,
                index_reg,
                value_reg,
                false,
              ),
            )
            array_index = array_index + 1
          }
        }
      }

      table_reg
    }
    @parse.Expr::Index(table_expr, index_expr) => {
      // Table indexing: table[index]
      let table_reg = self.compile_expr(table_expr)
      let index_reg = self.compile_expr(index_expr)
      let result_reg = self.alloc_register()

      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::GetTable,
          result_reg,
          table_reg,
          index_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Field(table_expr, field_name) => {
      // Table field access: table.field
      // Compile as table["field"]
      let table_reg = self.compile_expr(table_expr)

      let field_reg = self.alloc_register()
      let const_idx = self.add_constant(@value.TValue::string(field_name))
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, field_reg, const_idx))

      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::GetTable,
          result_reg,
          table_reg,
          field_reg,
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
