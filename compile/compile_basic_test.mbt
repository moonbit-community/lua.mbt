// Basic tests for Lua compiler

///|
test "compile local declaration with initialization" {
  let stmt = @parse.Stmt::LocalDecl(["x", "y"], [
    @parse.Expr::Number(1.0),
    @parse.Expr::Number(2.0),
  ])
  let proto = try! compile(stmt)
  // Should have: LOADK x, LOADK y (or MOVE if needed)
  assert_true(proto.code().length() > 0)
}

///|
test "compile binary expression" {
  let expr = @parse.Expr::Add(
    @parse.Expr::Number(5.0),
    @parse.Expr::Number(3.0),
  )
  let compiler = Compiler::new()
  ignore(try! compiler.compile_expr(expr))
  let proto = compiler.finish(0, false)
  let code = proto.code()

  // Should have LOADK for both numbers and ADD instruction
  assert_true(code.length() >= 3)
}

///|
test "compile constants pool" {
  let stmt = @parse.Stmt::LocalDecl(["a", "b"], [
    @parse.Expr::Number(1.5),
    @parse.Expr::Number(2.5),
  ])
  let proto = try! compile(stmt)

  // Check that constants were added
  let constant = proto.constant(0)
  assert_true(constant.is_number())
}

///|
test "compile arithmetic operations" {
  let stmt = @parse.Stmt::LocalDecl(["result"], [
    @parse.Expr::Mul(
      @parse.Expr::Number(3.0),
      @parse.Expr::Add(@parse.Expr::Number(1.0), @parse.Expr::Number(2.0)),
    ),
  ])
  let proto = try! compile(stmt)
  // Should have multiple instructions for nested operations
  assert_true(proto.code().length() >= 3)
}
