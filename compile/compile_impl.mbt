// Lua Bytecode Compiler Implementation
// Based on Lua 5.4's lcode.c
// Compiles AST to bytecode

///|
/// Local variable information
struct LocalVar {
  name : String
  register : Int
  scope_depth : Int
} derive(Show)

///|
/// Jump label for backpatching
struct JumpLabel {
  pc : Int // -1 means not yet defined
  patches : Array[Int] // Instruction positions to patch
} derive(Show)

///|
/// Helper: Find the last dot position in a string
fn find_last_dot(s : String) -> Int {
  let mut last_dot = -1
  for i = 0; i < s.length(); i = i + 1 {
    if s[i].to_int() == '.'.to_int() {
      last_dot = i
    }
  }
  last_dot
}

///|
/// Helper: Split string by dots into array of parts
fn split_by_dots(s : String) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  for i = 0; i < s.length(); i = i + 1 {
    if s[i].to_int() == '.'.to_int() {
      if i > start {
        let part = try {
          s[start:i].to_string()
        } catch {
          _ => ""
        }
        if part.length() > 0 {
          parts.push(part)
        }
      }
      start = i + 1
    }
  }
  // Add the last part
  if start < s.length() {
    let part = try {
      s[start:].to_string()
    } catch {
      _ => ""
    }
    if part.length() > 0 {
      parts.push(part)
    }
  }
  parts
}

///|
/// Helper: Extract substring using string slice notation
fn get_substring(s : String, start : Int, end : Int) -> String {
  // MoonBit supports string slicing with [start:end]
  let slice_result = try {
    s[start:end]
  } catch {
    _ => s[:]  // Return whole string on error
  }
  slice_result.to_string()
}

///|
/// Compiler state
pub struct Compiler {
  // Generated instructions
  code : Array[@opcodes.Instruction]

  // Constant pool
  constants : Array[@value.TValue]

  // Nested function prototypes
  protos : Array[@vm.Proto]

  // Local variables (name -> register)
  locals : Array[LocalVar]

  // Current scope depth (0 = global)
  mut scope_depth : Int

  // Next free register
  mut next_register : Int

  // Stack of register counts at each scope level (for restoring on exit)
  scope_register_base : Array[Int]

  // Jump labels for control flow
  jump_labels : Array[JumpLabel]

  // Stack of break jump positions for nested loops
  break_jumps : Array[Array[Int]]
} derive(Show)

///|
/// Create a new compiler
pub fn Compiler::new() -> Compiler {
  Compiler::{
    code: [],
    constants: [],
    protos: [],
    locals: [],
    scope_depth: 0,
    next_register: 0,
    scope_register_base: [],
    jump_labels: [],
    break_jumps: [],
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
/// Add a nested proto to the proto pool
fn Compiler::add_proto(self : Compiler, proto : @vm.Proto) -> Int {
  let index = self.protos.length()
  self.protos.push(proto)
  index
}

///|
/// Look up a local variable by name (returns the most recent one)
fn Compiler::find_local(self : Compiler, name : String) -> Int? {
  // Search backwards to find the most recent local with this name
  let len = self.locals.length()
  for i = len - 1; i >= 0; i = i - 1 {
    if self.locals[i].name == name {
      return Some(self.locals[i].register)
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
  self.locals.push(LocalVar::{ name, register: reg, scope_depth: self.scope_depth })
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
/// Enter a new scope
fn Compiler::enter_scope(self : Compiler) -> Unit {
  // Save the current register count so we can restore it on exit
  self.scope_register_base.push(self.next_register)
  self.scope_depth = self.scope_depth + 1
}

///|
/// Exit current scope and remove local variables
fn Compiler::exit_scope(self : Compiler) -> Unit {
  self.scope_depth = self.scope_depth - 1

  // Remove all locals from the exited scope
  while self.locals.length() > 0 {
    let last_idx = self.locals.length() - 1
    if self.locals[last_idx].scope_depth > self.scope_depth {
      ignore(self.locals.pop())
    } else {
      break
    }
  }

  // Restore register count to what it was before entering this scope
  if self.scope_register_base.length() > 0 {
    self.next_register = self.scope_register_base.pop().unwrap()
  }
}

///|
/// Enter a loop context (for handling break statements)
fn Compiler::enter_loop(self : Compiler) -> Unit {
  self.break_jumps.push([])
}

///|
/// Exit loop context and patch all break statements
fn Compiler::exit_loop(self : Compiler) -> Unit {
  let breaks = self.break_jumps.pop()
  match breaks {
    Some(jump_positions) =>
      for pos in jump_positions {
        self.patch_jump(pos)
      }
    None => ()
  }
}

///|
/// Add a break jump to the current loop
fn Compiler::add_break(self : Compiler) -> Unit raise CompileError {
  if self.break_jumps.length() == 0 {
    raise CompileError::BreakOutsideLoop(line=0)
  }
  let pos = self.emit_jump()
  let last_idx = self.break_jumps.length() - 1
  self.break_jumps[last_idx].push(pos)
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
    @parse.Stmt::Block(stmts) => {
      // Only enter/exit scope for nested blocks, not the top-level chunk
      let is_nested = self.scope_depth > 0
      if is_nested {
        self.enter_scope()
      }
      for s in stmts {
        // Save register baseline before statement (to free expression temporaries after)
        let baseline = self.next_register
        self.compile_stmt(s)
        // Restore baseline after statement (but keep any new locals)
        // Find highest register used by locals at current scope
        let mut max_local_reg = -1
        for local in self.locals {
          if local.scope_depth == self.scope_depth && local.register > max_local_reg {
            max_local_reg = local.register
          }
        }
        // Reset to max(baseline, max_local_reg + 1) to preserve new locals
        let target_reg = if max_local_reg >= baseline {
          max_local_reg + 1
        } else {
          baseline
        }
        self.next_register = target_reg
      }
      if is_nested {
        self.exit_scope()
      }
    }
    @parse.Stmt::LocalDecl(names, values) => {
      // Special case: if we have a single value that's a function call,
      // we need to handle multiple return values
      if values.length() == 1 {
        match values[0] {
          @parse.Expr::Call(func_expr, args) => {
            // Compile function call to return multiple values
            let num_names = names.length()
            let mut func_reg = self.compile_expr(func_expr)

            // Move function to new register if needed (same as in compile_expr Call)
            if func_reg < self.next_register {
              let new_func_reg = self.alloc_register()
              self.emit(
                @opcodes.Instruction::abc(
                  @opcodes.OpCode::Move,
                  new_func_reg,
                  func_reg,
                  0,
                  false,
                ),
              )
              func_reg = new_func_reg
            }

            // Compile arguments
            let arg_count = args.length()
            for i = 0; i < arg_count; i = i + 1 {
              let arg_reg = self.compile_expr(args[i])
              let expected_reg = func_reg + i + 1
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
                while self.next_register <= expected_reg {
                  self.next_register = self.next_register + 1
                }
              }
            }

            // Register all local variables first
            let local_regs : Array[Int] = []
            for name in names {
              let local_reg = self.add_local(name)
              local_regs.push(local_reg)
            }

            // Emit CALL instruction expecting num_names return values
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::Call,
                func_reg,
                arg_count + 1,
                num_names + 1, // C = number of expected results + 1
                false,
              ),
            )

            // Move results from call site to local registers
            // IMPORTANT: Move in REVERSE order to avoid clobbering values!
            // If result_reg overlaps with local_reg, moving forward would overwrite
            // values we haven't moved yet.
            for i = num_names - 1; i >= 0; i = i - 1 {
              let local_reg = local_regs[i]
              let result_reg = func_reg + i
              if result_reg != local_reg {
                self.emit(
                  @opcodes.Instruction::abc(
                    @opcodes.OpCode::Move,
                    local_reg,
                    result_reg,
                    0,
                    false,
                  ),
                )
              }
            }

            // Update next_register
            if local_regs.length() > 0 {
              self.next_register = local_regs[local_regs.length() - 1] + 1
            }
            return  // Done with this special case
          }
          _ => () // Fall through to normal case
        }
      }

      // Normal case: compile values first
      let value_regs : Array[Int] = []
      for value in values {
        let reg = self.compile_expr(value)
        value_regs.push(reg)
      }

      // Register locals and move values
      let mut last_local_reg = -1
      for i, name in names {
        let local_reg = self.add_local(name)
        last_local_reg = local_reg
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

      // Free temporary value registers (reset next_register to just past the last local)
      if last_local_reg >= 0 {
        self.next_register = last_local_reg + 1
      }
    }
    @parse.Stmt::Assign(lvals, rvals) => {
      // Compile rvalues first
      let value_regs : Array[Int] = []
      for value in rvals {
        let reg = self.compile_expr(value)
        value_regs.push(reg)
      }

      // Assign to lvalues
      for i, lval in lvals {
        let value_reg = if i < value_regs.length() {
          value_regs[i]
        } else {
          // If not enough rvalues, use nil
          let nil_reg = self.alloc_register()
          self.emit(
            @opcodes.Instruction::abc(
              @opcodes.OpCode::LoadNil,
              nil_reg,
              0,
              0,
              false,
            ),
          )
          nil_reg
        }

        match lval {
          @parse.Expr::Name(name) => {
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
              None => {
                // Not a local variable, treat as global assignment
                let name_const_idx = self.add_constant(@value.TValue::string(name))
                self.emit(
                  @opcodes.Instruction::abx(
                    @opcodes.OpCode::SetGlobal,
                    value_reg,
                    name_const_idx,
                  ),
                )
              }
            }
          }
          @parse.Expr::Index(table_expr, index_expr) => {
            // Table index assignment: table[index] = value
            let table_reg = self.compile_expr(table_expr)
            let index_reg = self.compile_expr(index_expr)
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
    }
    @parse.Stmt::If(condition, then_block, else_block) => {
      // Compile condition
      let cond_reg = self.compile_expr(condition)

      // TEST instruction: if (not R[A]) != k then PC++
      // With k=false: skip if condition is truthy (i.e., execute then block if truthy)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Test,
          cond_reg,  // A = condition register
          0,  // B unused
          0,  // C unused
          false, // k=false: skip jump if truthy
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
      self.enter_loop()

      // Save loop start position
      let loop_start = self.current_pc()

      // Compile condition
      let cond_reg = self.compile_expr(condition)

      // TEST instruction: if (not R[A]) != k then PC++
      // With k=false: skip if condition is truthy (continue looping if truthy)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Test,
          cond_reg,  // A = condition register
          0,  // B unused
          0,  // C unused
          false, // k=false: skip exit jump if truthy, i.e., continue looping
        ),
      )
      let exit_jump = self.emit_jump()

      // Compile body
      self.compile_stmt(body)

      // Jump back to loop start
      self.patch_jump_to(self.emit_jump(), loop_start)

      // Patch exit jump to current position
      self.patch_jump(exit_jump)
      self.exit_loop()
    }
    @parse.Stmt::Repeat(body, condition) => {
      self.enter_loop()

      // Repeat-until loop: repeat body until condition
      // Save loop start position
      let loop_start = self.current_pc()

      // Compile body first (do-while style)
      self.compile_stmt(body)

      // Compile condition
      let cond_reg = self.compile_expr(condition)

      // TEST instruction: if (not R[A]) != k then PC++
      // With k=false: skip loop-back jump if condition is truthy (exit loop)
      // If condition is falsy, execute the jump back (continue loop)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Test,
          cond_reg,  // A = condition register
          0,  // B unused
          0,  // C unused
          false, // k=false: skip loop-back jump if condition is truthy (exit loop)
        ),
      )

      // Jump back to loop start (executed when condition is false)
      self.patch_jump_to(self.emit_jump(), loop_start)
      self.exit_loop()
    }
    @parse.Stmt::For(var_name, start_expr, end_expr, step_expr, body) => {
      // Numeric for loop: for var = start, end, step do body end
      // Compile start, end, step expressions
      let start_reg = self.compile_expr(start_expr)
      let end_expr_reg = self.compile_expr(end_expr)
      let step_expr_reg = match step_expr {
        Some(step) => self.compile_expr(step)
        None => {
          // Default step is 1
          let reg = self.alloc_register()
          let const_idx = self.add_constant(@value.TValue::integer(1L))
          self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, reg, const_idx))
          reg
        }
      }

      // CRITICAL: Create hidden local variables to preserve end and step
      // Without this, these temporary registers can be overwritten when
      // the loop body allocates new registers (e.g., for table operations)
      let end_reg = self.add_local("(for limit)")
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          end_reg,
          end_expr_reg,
          0,
          false,
        ),
      )

      let step_reg = self.add_local("(for step)")
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          step_reg,
          step_expr_reg,
          0,
          false,
        ),
      )

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

      self.enter_loop()

      // Loop start
      let loop_start = self.current_pc()

      // Check loop condition based on step direction
      // For positive step: continue while var <= end
      // For negative step: continue while var >= end

      // Compare step with 0
      let zero_reg = self.alloc_register()
      let zero_const = self.add_constant(@value.TValue::integer(0L))
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, zero_reg, zero_const))

      // Check if step < 0 (for negative step / countdown)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Lt,
          0, // A is unused
          step_reg, // B is left operand
          zero_reg, // C is right operand
          false, // k=false: if step < 0 is true, skip next instruction
        ),
      )

      // If step >= 0, jump to positive step handling (skip negative path)
      let positive_step_jump = self.emit_jump()

      // Negative step path: check var >= end (i.e., end <= var)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          0, // A is unused
          end_reg, // B is left operand
          var_reg, // C is right operand
          false, // k=false means skip next if end > var (i.e., var < end, should exit)
        ),
      )
      let exit_jump_neg = self.emit_jump()

      // Jump over positive step check to loop body
      let skip_positive = self.emit_jump()

      // Positive step path: check var <= end
      self.patch_jump(positive_step_jump)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          0, // A is unused for comparisons
          var_reg, // B is left operand
          end_reg, // C is right operand
          false, // k=false means skip next if var > end
        ),
      )
      let exit_jump_pos = self.emit_jump()

      // Continue with loop body
      self.patch_jump(skip_positive)

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

      // Patch both exit jumps (positive and negative step paths)
      self.patch_jump(exit_jump_pos)
      self.patch_jump(exit_jump_neg)
      self.exit_loop()

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
      let func_value = @value.FunctionValue::new_with_params(
        proto.code(),
        proto.constants,
        params.length(),
      )

      // Add function to constants
      let func_const_idx = self.add_constant(@value.TValue::function(func_value))

      // Load function into a temporary register
      let temp_reg = self.alloc_register()
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, temp_reg, func_const_idx))

      // Check if the name contains a dot (table field assignment)
      if name.contains(".") {
        // Split the name into parts: "a.b.c.f" -> ["a", "b", "c", "f"]
        let parts = split_by_dots(name)
        if parts.length() < 2 {
          // Shouldn't happen, but fallback to global
          let name_const_idx = self.add_constant(@value.TValue::string(name))
          self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::SetGlobal, temp_reg, name_const_idx))
        } else {
          // Get the base table (first part)
          let mut table_reg = match self.find_local(parts[0]) {
            Some(local_reg) => local_reg  // Base is a local variable
            None => {
              // Base is a global
              let reg = self.alloc_register()
              let base_const = self.add_constant(@value.TValue::string(parts[0]))
              self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::GetGlobal, reg, base_const))
              reg
            }
          }

          // Navigate through intermediate tables (parts[1] to parts[length-2])
          for i = 1; i < parts.length() - 1; i = i + 1 {
            let field_reg = self.alloc_register()
            let field_const = self.add_constant(@value.TValue::string(parts[i]))
            self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, field_reg, field_const))

            let next_table_reg = self.alloc_register()
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::GetTable,
                next_table_reg,
                table_reg,
                field_reg,
                false,
              ),
            )
            table_reg = next_table_reg
          }

          // Set the final field (last part)
          let final_field = parts[parts.length() - 1]
          let field_reg = self.alloc_register()
          let field_const = self.add_constant(@value.TValue::string(final_field))
          self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, field_reg, field_const))

          self.emit(
            @opcodes.Instruction::abc(
              @opcodes.OpCode::SetTable,
              table_reg,
              field_reg,
              temp_reg,
              false,
            ),
          )
        }
      } else {
        // Simple global function
        let name_const_idx = self.add_constant(@value.TValue::string(name))
        self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::SetGlobal, temp_reg, name_const_idx))
      }
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
      let func_value = @value.FunctionValue::new_with_params(
        proto.code(),
        proto.constants,
        params.length(),
      )

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
      //Note: In Lua CALL instruction, B = number of arguments + 1
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Call,
          func_reg,
          arg_count + 1, // B = arg_count + 1 (Lua convention)
          0, // 0 means no return values expected for statement
          false,
        ),
      )
    }
    @parse.Stmt::MethodCall(obj_expr, method, args) => {
      // Compile method call statement: obj:method(args)
      // This is sugar for obj.method(obj, args)

      // Compile object expression
      let obj_reg = self.compile_expr(obj_expr)

      // Allocate register for the method function
      let method_reg = self.alloc_register()

      // Load method name into a register first
      let method_name_reg = self.alloc_register()
      let method_const = self.add_constant(@value.TValue::string(method))
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, method_name_reg, method_const))

      // Load method from object: method_reg = obj[method_name]
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::GetTable,
          method_reg,
          obj_reg,
          method_name_reg,
          false,
        ),
      )

      // Place object as first argument (self)
      let self_reg = method_reg + 1
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          self_reg,
          obj_reg,
          0,
          false,
        ),
      )

      // Ensure next_register is past self_reg
      while self.next_register <= self_reg {
        self.next_register = self.next_register + 1
      }

      // Compile remaining arguments
      let arg_count = args.length()
      for i = 0; i < arg_count; i = i + 1 {
        let arg_reg = self.compile_expr(args[i])
        let expected_reg = self_reg + i + 1

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
          while self.next_register <= expected_reg {
            self.next_register = self.next_register + 1
          }
        }
      }

      // Emit CALL instruction: method(self, args...)
      // Total args = 1 (self) + arg_count
      // For statement form, we don't expect return values (C=0)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Call,
          method_reg,
          arg_count + 2, // B = 1 (self) + arg_count + 1 (Lua convention)
          0, // No return values expected for statement
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

        // Compile remaining return values into consecutive registers
        for i = 1; i < return_count; i = i + 1 {
          let reg = self.compile_expr(exprs[i])
          let expected_reg = start_reg + i

          // Ensure the value is in the expected consecutive register
          if reg != expected_reg {
            self.emit(
              @opcodes.Instruction::abc(
                @opcodes.OpCode::Move,
                expected_reg,
                reg,
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
    @parse.Stmt::Break => self.add_break()
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
    @parse.Expr::Idiv(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Idiv,
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
    @parse.Expr::BAnd(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::BAnd,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::BOr(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::BOr,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::BXor(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::BXor,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::BNot(expr) => {
      let expr_reg = self.compile_expr(expr)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::BNot,
          result_reg,
          expr_reg,
          0,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Shl(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Shl,
          result_reg,
          left_reg,
          right_reg,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Shr(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Shr,
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
    @parse.Expr::Len(operand) => {
      let operand_reg = self.compile_expr(operand)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Len,
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

      // EQ instruction: if (R[B] == R[C]) ~= k then PC++
      // We want to compare left == right, so B=left_reg, C=right_reg
      // With k=false: if comparison is true, skip the JMP to false case
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          0,  // A is unused for comparison instructions
          left_reg,
          right_reg,
          false, // k=false: skip next instruction if equal
        ),
      )

      // If not equal, jump to false case
      let to_false = self.emit_jump()

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

      // Jump over the false case
      let skip_false = self.emit_jump()

      // Not equal path: set to false (to_false points here)
      self.patch_jump(to_false)
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
    @parse.Expr::Lt(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // LT instruction: if (R[B] < R[C]) ~= k then PC++
      // We want to compare left < right, so B=left_reg, C=right_reg
      // With k=false: if comparison is true, skip the JMP to false case
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Lt,
          0,  // A is unused for comparison instructions
          left_reg,
          right_reg,
          false, // k=false: skip next instruction if less than
        ),
      )

      // If not less than, jump to false case
      let to_false = self.emit_jump()

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

      // Jump over false case
      let skip_false = self.emit_jump()

      // Not less than: set to false (to_false points here)
      self.patch_jump(to_false)
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
    @parse.Expr::Le(left, right) => {
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // LE instruction: if (R[B] <= R[C]) ~= k then PC++
      // We want to compare left <= right, so B=left_reg, C=right_reg
      // With k=false: if comparison is true, skip the JMP to false case
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          0,  // A is unused for comparison instructions
          left_reg,
          right_reg,
          false, // k=false: skip next instruction if comparison is true
        ),
      )

      // If comparison is false, jump to false case
      let to_false = self.emit_jump()

      // Comparison is true: load true
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::LoadTrue,
          result_reg,
          0,
          0,
          false,
        ),
      )

      // Jump over the false case
      let skip_false = self.emit_jump()

      // Comparison is false: load false (to_false points here)
      self.patch_jump(to_false)
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
    @parse.Expr::Gt(left, right) => {
      // a > b is same as b < a
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // LT instruction: if (R[B] < R[C]) ~= k then PC++
      // For a > b, we want b < a, so B=right_reg, C=left_reg
      // With k=false: if comparison is true, skip the JMP to false case
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Lt,
          0,  // A is unused
          right_reg,
          left_reg,
          false, // k=false: skip next instruction if (b < a)
        ),
      )

      // If not (b < a), jump to false case
      let to_false = self.emit_jump()

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

      self.patch_jump(to_false)
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
    @parse.Expr::Ge(left, right) => {
      // a >= b is same as b <= a
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // LE instruction: if (R[B] <= R[C]) ~= k then PC++
      // For a >= b, we want b <= a, so B=right_reg, C=left_reg
      // With k=false: if comparison is true, skip the JMP to false case
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Le,
          0,  // A is unused
          right_reg,
          left_reg,
          false, // k=false: skip next instruction if (b <= a)
        ),
      )

      // If not (b <= a), jump to false case
      let to_false = self.emit_jump()

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

      self.patch_jump(to_false)
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
    @parse.Expr::Ne(left, right) => {
      // a ~= b is same as not (a == b)
      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)
      let result_reg = self.alloc_register()

      // EQ instruction: if (R[B] == R[C]) ~= k then PC++
      // We want to compare left == right, so B=left_reg, C=right_reg
      // For not-equal, we want opposite of equality
      // With k=false: if equal, skip the JMP (execute LoadFalse), else jump to LoadTrue
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          0,  // A is unused
          left_reg,
          right_reg,
          false,  // k=false: if equal, skip next instruction
        ),
      )

      // If not equal, jump to true case
      let to_true = self.emit_jump()

      // Equal: set to false (for not-equal operator)
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

      // Not equal: set to true (to_true points here)
      self.patch_jump(to_true)
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
    @parse.Expr::Call(func_expr, args) => {
      // Compile function call expression
      // Function expression
      let mut func_reg = self.compile_expr(func_expr)

      // If func_reg is behind next_register, we need to move it to avoid
      // conflicts when compiling arguments (which might overwrite registers)
      if func_reg < self.next_register {
        let new_func_reg = self.alloc_register()
        self.emit(
          @opcodes.Instruction::abc(
            @opcodes.OpCode::Move,
            new_func_reg,
            func_reg,
            0,
            false,
          ),
        )
        func_reg = new_func_reg
      }

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
      // Note: In Lua CALL instruction, B = number of arguments + 1
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Call,
          func_reg,
          arg_count + 1, // B = arg_count + 1 (Lua convention)
          1, // Expect 1 return value
          false,
        ),
      )

      // The result will be in func_reg position after call
      func_reg
    }
    @parse.Expr::MethodCall(obj_expr, method, args) => {
      // Compile method call: obj:method(args)
      // This is sugar for obj.method(obj, args)

      // Compile object expression
      let obj_reg = self.compile_expr(obj_expr)

      // Allocate register for the method function
      let method_reg = self.alloc_register()

      // Load method name into a register first
      let method_name_reg = self.alloc_register()
      let method_const = self.add_constant(@value.TValue::string(method))
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, method_name_reg, method_const))

      // Load method from object: method_reg = obj[method_name]
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::GetTable,
          method_reg,
          obj_reg,
          method_name_reg,
          false,
        ),
      )

      // Place object as first argument (self)
      let self_reg = method_reg + 1
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          self_reg,
          obj_reg,
          0,
          false,
        ),
      )

      // Ensure next_register is past self_reg
      while self.next_register <= self_reg {
        self.next_register = self.next_register + 1
      }

      // Compile remaining arguments
      let arg_count = args.length()
      for i = 0; i < arg_count; i = i + 1 {
        let arg_reg = self.compile_expr(args[i])
        let expected_reg = self_reg + i + 1

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
          while self.next_register <= expected_reg {
            self.next_register = self.next_register + 1
          }
        }
      }

      // Emit CALL instruction: method(self, args...)
      // Total args = 1 (self) + arg_count
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Call,
          method_reg,
          arg_count + 2, // B = 1 (self) + arg_count + 1 (Lua convention)
          1, // Expect 1 return value
          false,
        ),
      )

      // The result will be in method_reg position after call
      method_reg
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
    @parse.Expr::And(left, right) => {
      // a and b: if a is falsy (nil or false), return a; else return b
      // Compile left operand
      let left_reg = self.compile_expr(left)
      let result_reg = self.alloc_register()

      // Move left to result (in case we return it)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          result_reg,
          left_reg,
          0,
          false,
        ),
      )

      // Test if left is falsy: check if (NOT left) is true
      // If NOT left == false, then left is truthy, so evaluate right
      let not_left_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Not,
          not_left_reg,
          left_reg,
          0,
          false,
        ),
      )

      let false_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(@opcodes.OpCode::LoadFalse, false_reg, 0, 0, false),
      )

      // EQ: if (NOT left) == false, then left is truthy, skip jump (evaluate right)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          0,
          not_left_reg,
          false_reg,
          false,  // k=false: if NOT left is false (left is truthy), skip next instruction
        ),
      )

      // Left is falsy, jump to end (return left in result_reg)
      let skip_right = self.emit_jump()

      // Left is truthy, evaluate right and move to result
      let right_reg = self.compile_expr(right)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          result_reg,
          right_reg,
          0,
          false,
        ),
      )

      self.patch_jump(skip_right)
      result_reg
    }
    @parse.Expr::Or(left, right) => {
      // a or b: if a is truthy (not nil and not false), return a; else return b
      // Compile left operand
      let left_reg = self.compile_expr(left)
      let result_reg = self.alloc_register()

      // Move left to result (in case we return it)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          result_reg,
          left_reg,
          0,
          false,
        ),
      )

      // Test if left is truthy: check if (NOT left) is false
      // If NOT left == false, then left is truthy, return left
      let not_left_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Not,
          not_left_reg,
          left_reg,
          0,
          false,
        ),
      )

      let false_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(@opcodes.OpCode::LoadFalse, false_reg, 0, 0, false),
      )

      // EQ: if (NOT left) == false, then left is truthy, skip evaluation of right
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Eq,
          0,
          not_left_reg,
          false_reg,
          true,  // k=true: if NOT equal (NOT left != false, i.e., left is falsy), skip next instruction
        ),
      )

      // Left is truthy, jump to end (return left in result_reg)
      let skip_right = self.emit_jump()

      // Left is falsy, evaluate right and move to result
      let right_reg = self.compile_expr(right)
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          result_reg,
          right_reg,
          0,
          false,
        ),
      )

      self.patch_jump(skip_right)
      result_reg
    }
    @parse.Expr::Concat(left, right) => {
      // String concatenation: R[A] := R[B].. ... ..R[C]
      // CONCAT requires consecutive registers from B to C
      // For binary concat, we allocate exactly 2 consecutive registers

      let left_reg = self.compile_expr(left)
      let right_reg = self.compile_expr(right)

      // Allocate two consecutive registers for the concat operation
      let concat_reg1 = self.alloc_register()
      let concat_reg2 = self.alloc_register()

      // Move values to consecutive registers
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          concat_reg1,
          left_reg,
          0,
          false,
        ),
      )
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Move,
          concat_reg2,
          right_reg,
          0,
          false,
        ),
      )

      // Now concatenate: concat_reg2 = concat_reg1 + 1 (consecutive)
      let result_reg = self.alloc_register()
      self.emit(
        @opcodes.Instruction::abc(
          @opcodes.OpCode::Concat,
          result_reg,
          concat_reg1,
          concat_reg2,
          false,
        ),
      )
      result_reg
    }
    @parse.Expr::Function(params, is_vararg, body) => {
      // Compile anonymous function expression
      // Create a new compiler for the function body
      let func_compiler = Compiler::new()

      // Register parameters as locals (starting at register 0)
      for param in params {
        func_compiler.add_local(param) |> ignore
      }

      // Compile function body
      func_compiler.compile_stmt(body)

      // Get the function code and constants
      let proto = func_compiler.finish()
      let func_value = @value.FunctionValue::new_with_params(
        proto.code(),
        proto.constants,
        params.length(),
      )

      // Add function to constants
      let func_const_idx = self.add_constant(@value.TValue::function(func_value))

      // Load function into a register
      let func_reg = self.alloc_register()
      self.emit(@opcodes.Instruction::abx(@opcodes.OpCode::LoadK, func_reg, func_const_idx))

      func_reg
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
  @vm.Proto::new(self.code, self.constants, self.protos)
}

///|
/// Compile a complete Lua chunk to bytecode
pub fn compile(stmt : @parse.Stmt) -> @vm.Proto raise CompileError {
  let compiler = Compiler::new()
  compiler.compile_stmt(stmt)
  compiler.finish()
}
