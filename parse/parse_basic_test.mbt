// Basic tests for Lua parser

///|
test "parse simple assignment" {
  let lexer = @lex.Lexer::new("x = 42")
  let parser = Parser::new(lexer)
  let stmt = try! parser.parse_stmt()
  guard stmt is Stmt::Assign(lvals, rvals) else {
    fail("Expected assignment statement")
  }
  inspect(lvals.length(), content="1")
  inspect(rvals.length(), content="1")
}

///|
test "parse local declaration" {
  let lexer = @lex.Lexer::new("local x, y = 1, 2")
  let parser = Parser::new(lexer)
  let stmt = try! parser.parse_stmt()
  guard stmt is Stmt::LocalDecl(names, values) else {
    fail("Expected local declaration")
  }
  inspect(names.length(), content="2")
  inspect(values.length(), content="2")
}

///|
test "parse if statement" {
  let source =
    #|if x > 0 then
    #|  return x
    #|end
    #|
  let lexer = @lex.Lexer::new(source)
  let parser = Parser::new(lexer)
  let stmt = try! parser.parse_stmt()
  guard stmt is Stmt::If(_, _, _) else { fail("Expected if statement") }
}

///|
test "parse binary expressions" {
  let lexer = @lex.Lexer::new("1 + 2 * 3")
  let parser = Parser::new(lexer)
  let expr = try! parser.parse_expr()
  guard expr is Expr::Add(_, Expr::Mul(_, _)) else {
    fail("Expected Add(_, Mul(_, _)) respecting precedence")
  }
}

///|
test "parse function call" {
  let lexer = @lex.Lexer::new("print(42)")
  let parser = Parser::new(lexer)
  let expr = try! parser.parse_expr()
  guard expr is Expr::Call(Expr::Name(name), args) &&
    name == "print" &&
    args.length() == 1 else {
    fail("Expected function call to print with 1 argument")
  }
}

///|
test "parse table constructor" {
  let lexer = @lex.Lexer::new("{x = 1, y = 2, 3}")
  let parser = Parser::new(lexer)
  let expr = try! parser.parse_expr()
  guard expr is Expr::TableConstructor(fields) && fields.length() == 3 else {
    fail("Expected table constructor with 3 fields")
  }
}
