// Lua Bytecode Compiler Specification
// Based on Lua 5.4's lcode.h
// Compiles AST to bytecode

///|
/// Compilation errors
pub(all) suberror CompileError {
  TooManyLocals(line~ : Int)
  TooManyConstants(line~ : Int)
  InvalidJumpTarget(line~ : Int)
  UndefinedVariable(name~ : String, line~ : Int)
  BreakOutsideLoop(line~ : Int)
  InvalidSyntax(message~ : String, line~ : Int)
} derive(Eq, Show, ToJson)

///|
/// Compiler state
#declaration_only
pub type Compiler

///|
/// Create a new compiler
#declaration_only
pub fn Compiler::new() -> Compiler {
  ...
}

///|
/// Compile a statement into bytecode
#declaration_only
pub fn Compiler::compile_stmt(
  self : Compiler,
  stmt : @parse.Stmt,
) -> Unit raise CompileError {
  ...
}

///|
/// Compile an expression into bytecode and return the register containing the result
#declaration_only
pub fn Compiler::compile_expr(
  self : Compiler,
  expr : @parse.Expr,
) -> Int raise CompileError {
  ...
}

///|
/// Finalize and get the compiled prototype
#declaration_only
pub fn Compiler::finish(self : Compiler) -> @vm.Proto {
  ...
}

///|
/// Compile a complete Lua chunk to bytecode
#declaration_only
pub fn compile(stmt : @parse.Stmt) -> @vm.Proto raise CompileError {
  ...
}
