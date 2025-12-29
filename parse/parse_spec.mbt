// Lua Parser Specification
// Based on Lua 5.4's lparser.h
// Parses Lua source code into an AST

///|
/// Parse errors
pub(all) suberror ParseError {
  UnexpectedToken(expected~ : String, actual~ : String, line~ : Int)
  UnexpectedEof(line~ : Int)
  InvalidSyntax(message~ : String, line~ : Int)
} derive(Eq, Show, ToJson)

///|
/// AST Expression nodes
pub(all) enum Expr {
  Nil
  Bool(Bool)
  Number(Double)
  String(String)
  Vararg // ...

  // Variables and fields
  Name(String)
  Index(Expr, Expr) // table[key]
  Field(Expr, String) // table.field

  // Binary operations
  Add(Expr, Expr)
  Sub(Expr, Expr)
  Mul(Expr, Expr)
  Div(Expr, Expr)
  Mod(Expr, Expr)
  Pow(Expr, Expr)

  // Comparison
  Eq(Expr, Expr)
  Ne(Expr, Expr)
  Lt(Expr, Expr)
  Le(Expr, Expr)
  Gt(Expr, Expr)
  Ge(Expr, Expr)

  // Logic
  And(Expr, Expr)
  Or(Expr, Expr)
  Not(Expr)

  // Other
  Concat(Expr, Expr) // ..
  Len(Expr) // #expr
  Call(Expr, Array[Expr])
  TableConstructor(Array[(Expr?, Expr)]) // {[key]=value, value, ...}
  Function(Array[String], Bool, Expr) // (params, is_vararg, body)
} derive(Eq, Show, ToJson)

///|
/// AST Statement nodes
pub(all) enum Stmt {
  Block(Array[Stmt])
  Assign(Array[Expr], Array[Expr]) // lvalues = rvalues
  LocalDecl(Array[String], Array[Expr]) // local names = values
  FunctionCall(Expr, Array[Expr])
  Return(Array[Expr])
  Break
  If(Expr, Stmt, Stmt?) // condition, then_block, else_block
  While(Expr, Stmt)
  Repeat(Stmt, Expr) // body, until_condition
  For(String, Expr, Expr, Expr?, Stmt) // name, start, end, step, body
  ForIn(Array[String], Array[Expr], Stmt) // names, iterators, body
  FunctionDef(String, Array[String], Bool, Stmt) // name, params, is_vararg, body
  LocalFunctionDef(String, Array[String], Bool, Stmt)
} derive(Eq, Show, ToJson)

///|
/// Parser state
#declaration_only
pub type Parser

///|
/// Create a new parser from lexer
#declaration_only
pub fn Parser::new(lexer : @lex.Lexer) -> Parser {
  ...
}

///|
/// Parse a complete Lua chunk (top-level block)
#declaration_only
pub fn Parser::parse_chunk(self : Parser) -> Stmt raise ParseError {
  ...
}

///|
/// Parse a single statement
#declaration_only
pub fn Parser::parse_stmt(self : Parser) -> Stmt raise ParseError {
  ...
}

///|
/// Parse an expression
#declaration_only
pub fn Parser::parse_expr(self : Parser) -> Expr raise ParseError {
  ...
}
