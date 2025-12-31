// Lua Parser Implementation
// Based on Lua 5.4's lparser.c
// Recursive descent parser with operator precedence

///|
/// Parse a hexadecimal string to an integer
fn parse_hex(hex_str : String) -> Int? {
  let mut result = 0
  for i = 0; i < hex_str.length(); i = i + 1 {
    let c = hex_str[i]
    let digit = match c {
      '0' => 0
      '1' => 1
      '2' => 2
      '3' => 3
      '4' => 4
      '5' => 5
      '6' => 6
      '7' => 7
      '8' => 8
      '9' => 9
      'a' | 'A' => 10
      'b' | 'B' => 11
      'c' | 'C' => 12
      'd' | 'D' => 13
      'e' | 'E' => 14
      'f' | 'F' => 15
      _ => return None
    }
    result = result * 16 + digit
  }
  Some(result)
}

///|
/// Parser state
pub struct Parser {
  lexer : @lex.Lexer
} derive(Show)

///|
/// Create a new parser from lexer
pub fn Parser::new(lexer : @lex.Lexer) -> Parser {
  Parser::{ lexer, }
}

///|
/// Peek at the next token type
fn Parser::peek(self : Parser) -> @lex.TokenType raise ParseError {
  let tok = self.lexer.peek_token() catch {
    _ => raise ParseError::UnexpectedEof(line=self.lexer.current_line())
  }
  tok.type_
}

///|
/// Consume and return the next token
fn Parser::advance(self : Parser) -> @lex.Token raise ParseError {
  self.lexer.next_token() catch {
    _ => raise ParseError::UnexpectedEof(line=self.lexer.current_line())
  }
}

///|
/// Expect a specific token type and consume it
fn Parser::expect(
  self : Parser,
  expected : @lex.TokenType,
) -> @lex.Token raise ParseError {
  let tok = self.advance()
  if tok.type_ != expected {
    raise ParseError::UnexpectedToken(
      expected=expected.to_string(),
      actual=tok.type_.to_string(),
      line=tok.line,
    )
  }
  tok
}

///|
/// Check if next token matches type (without consuming)
fn Parser::check(
  self : Parser,
  type_ : @lex.TokenType,
) -> Bool raise ParseError {
  self.peek() == type_
}

///|
/// Parse a complete Lua chunk (top-level block)
pub fn Parser::parse_chunk(self : Parser) -> Stmt raise ParseError {
  let stmts : Array[Stmt] = []
  while true {
    if self.check(@lex.TokenType::TkEof) {
      break
    }
    stmts.push(self.parse_stmt())
  }
  Stmt::Block(stmts)
}

///|
/// Parse a single statement
pub fn Parser::parse_stmt(self : Parser) -> Stmt raise ParseError {
  match self.peek() {
    @lex.TokenType::TkLocal => self.parse_local()
    @lex.TokenType::TkIf => self.parse_if()
    @lex.TokenType::TkWhile => self.parse_while()
    @lex.TokenType::TkRepeat => self.parse_repeat()
    @lex.TokenType::TkFor => self.parse_for()
    @lex.TokenType::TkFunction => self.parse_function_def()
    @lex.TokenType::TkReturn => self.parse_return()
    @lex.TokenType::TkDo => self.parse_do()
    @lex.TokenType::TkBreak => {
      ignore(self.advance())
      Stmt::Break
    }
    @lex.TokenType::TkSemicolon => {
      // Empty statement - just consume the semicolon
      ignore(self.advance())
      Stmt::Block([])
    }
    _ =>
      // Could be assignment or function call
      self.parse_expr_stmt()
  }
}

///|
/// Parse local variable declaration
fn Parser::parse_local(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkLocal))

  // Check for local function
  if self.check(@lex.TokenType::TkFunction) {
    ignore(self.advance())
    let name_tok = self.expect(@lex.TokenType::TkName)
    let (params, is_vararg) = self.parse_param_list()
    let body = self.parse_block()
    ignore(self.expect(@lex.TokenType::TkEnd))
    return Stmt::LocalFunctionDef(name_tok.lexeme, params, is_vararg, body)
  }

  // Parse name list with optional attributes
  let names : Array[String] = []
  let name_tok = self.expect(@lex.TokenType::TkName)
  names.push(name_tok.lexeme)

  // Check for attribute like <const> or <close>
  if self.check(@lex.TokenType::TkLt) {
    ignore(self.advance()) // consume '<'
    ignore(self.expect(@lex.TokenType::TkName)) // attribute name (const, close, etc)
    ignore(self.expect(@lex.TokenType::TkGt)) // consume '>'
  }

  while self.check(@lex.TokenType::TkComma) {
    ignore(self.advance())
    let tok = self.expect(@lex.TokenType::TkName)
    names.push(tok.lexeme)

    // Check for attribute
    if self.check(@lex.TokenType::TkLt) {
      ignore(self.advance()) // consume '<'
      ignore(self.expect(@lex.TokenType::TkName)) // attribute name
      ignore(self.expect(@lex.TokenType::TkGt)) // consume '>'
    }
  }

  // Optional initialization
  let values : Array[Expr] = []
  if self.check(@lex.TokenType::TkAssign) {
    ignore(self.advance())
    values.push(self.parse_expr())
    while self.check(@lex.TokenType::TkComma) {
      ignore(self.advance())
      values.push(self.parse_expr())
    }
  }
  Stmt::LocalDecl(names, values)
}

///|
/// Parse if statement
fn Parser::parse_if(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkIf))
  let cond = self.parse_expr()
  ignore(self.expect(@lex.TokenType::TkThen))
  let then_block = self.parse_block()
  let else_block = self.parse_else_chain()
  ignore(self.expect(@lex.TokenType::TkEnd))
  Stmt::If(cond, then_block, else_block)
}

///|
/// Parse elseif/else chain (helper for parse_if)
fn Parser::parse_else_chain(self : Parser) -> Stmt? raise ParseError {
  if self.check(@lex.TokenType::TkElseif) {
    ignore(self.advance())  // Consume 'elseif'
    let cond = self.parse_expr()
    ignore(self.expect(@lex.TokenType::TkThen))
    let then_block = self.parse_block()
    let else_block = self.parse_else_chain()  // Recursive for more elseif/else
    Some(Stmt::If(cond, then_block, else_block))
  } else if self.check(@lex.TokenType::TkElse) {
    ignore(self.advance())
    Some(self.parse_block())
  } else {
    None
  }
}

///|
/// Parse while statement
fn Parser::parse_while(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkWhile))
  let cond = self.parse_expr()
  ignore(self.expect(@lex.TokenType::TkDo))
  let body = self.parse_block()
  ignore(self.expect(@lex.TokenType::TkEnd))
  Stmt::While(cond, body)
}

///|
/// Parse do-end block
fn Parser::parse_do(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkDo))
  let body = self.parse_block()
  ignore(self.expect(@lex.TokenType::TkEnd))
  body
}

///|
/// Parse repeat statement
fn Parser::parse_repeat(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkRepeat))
  let body = self.parse_block()
  ignore(self.expect(@lex.TokenType::TkUntil))
  let cond = self.parse_expr()
  Stmt::Repeat(body, cond)
}

///|
/// Parse for statement
fn Parser::parse_for(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkFor))
  let name_tok = self.expect(@lex.TokenType::TkName)
  if self.check(@lex.TokenType::TkAssign) {
    // Numeric for
    ignore(self.advance())
    let start = self.parse_expr()
    ignore(self.expect(@lex.TokenType::TkComma))
    let end = self.parse_expr()
    let step = if self.check(@lex.TokenType::TkComma) {
      ignore(self.advance())
      Some(self.parse_expr())
    } else {
      None
    }
    ignore(self.expect(@lex.TokenType::TkDo))
    let body = self.parse_block()
    ignore(self.expect(@lex.TokenType::TkEnd))
    Stmt::For(name_tok.lexeme, start, end, step, body)
  } else {
    // Generic for (for-in)
    let names : Array[String] = [name_tok.lexeme]
    while self.check(@lex.TokenType::TkComma) {
      ignore(self.advance())
      let tok = self.expect(@lex.TokenType::TkName)
      names.push(tok.lexeme)
    }
    ignore(self.expect(@lex.TokenType::TkIn))
    let exprs : Array[Expr] = [self.parse_expr()]
    while self.check(@lex.TokenType::TkComma) {
      ignore(self.advance())
      exprs.push(self.parse_expr())
    }
    ignore(self.expect(@lex.TokenType::TkDo))
    let body = self.parse_block()
    ignore(self.expect(@lex.TokenType::TkEnd))
    Stmt::ForIn(names, exprs, body)
  }
}

///|
/// Parse function definition
fn Parser::parse_function_def(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkFunction))
  let name_tok = self.expect(@lex.TokenType::TkName)

  // Check if this is a method definition (function a:x(params))
  // or a table field function (function a.b.c(params))
  let mut table_name : String? = None
  let mut method_name : String? = None
  let mut final_name = name_tok.lexeme

  // Handle dotted names and method syntax
  while self.check(@lex.TokenType::TkDot) || self.check(@lex.TokenType::TkColon) {
    if self.check(@lex.TokenType::TkColon) {
      // Method syntax: function a:x(params)
      ignore(self.advance())
      let method_tok = self.expect(@lex.TokenType::TkName)
      table_name = Some(final_name)
      method_name = Some(method_tok.lexeme)
      final_name = final_name + "." + method_tok.lexeme
      break  // Colon can only appear once at the end
    } else {
      // Dotted name: function a.b.c(params)
      ignore(self.advance())
      let field_tok = self.expect(@lex.TokenType::TkName)
      final_name = final_name + "." + field_tok.lexeme
    }
  }

  // Parse parameters
  let (params, is_vararg) = self.parse_param_list()

  // If this is a method definition, prepend 'self' to parameters
  let final_params = match method_name {
    Some(_) => {
      let new_params : Array[String] = []
      new_params.push("self")
      for p in params {
        new_params.push(p)
      }
      new_params
    }
    None => params
  }

  let body = self.parse_block()
  ignore(self.expect(@lex.TokenType::TkEnd))

  // For now, we'll use FunctionDef with the full dotted name
  // In a full implementation, this would need to be converted to an assignment
  Stmt::FunctionDef(final_name, final_params, is_vararg, body)
}

///|
/// Parse return statement
fn Parser::parse_return(self : Parser) -> Stmt raise ParseError {
  ignore(self.expect(@lex.TokenType::TkReturn))
  let values : Array[Expr] = []

  // Return can be empty or followed by expressions
  if !self.check(@lex.TokenType::TkEnd) &&
    !self.check(@lex.TokenType::TkEof) &&
    !self.check(@lex.TokenType::TkElse) &&
    !self.check(@lex.TokenType::TkElseif) &&
    !self.check(@lex.TokenType::TkUntil) &&
    !self.check(@lex.TokenType::TkSemicolon) {
    values.push(self.parse_expr())
    while self.check(@lex.TokenType::TkComma) {
      ignore(self.advance())
      values.push(self.parse_expr())
    }
  }
  Stmt::Return(values)
}

///|
/// Parse parameter list (params, is_vararg)
fn Parser::parse_param_list(
  self : Parser,
) -> (Array[String], Bool) raise ParseError {
  ignore(self.expect(@lex.TokenType::TkLparen))
  let params : Array[String] = []
  let mut is_vararg = false
  if !self.check(@lex.TokenType::TkRparen) {
    while true {
      if self.check(@lex.TokenType::TkDots) {
        ignore(self.advance())
        is_vararg = true
        break
      }
      let tok = self.expect(@lex.TokenType::TkName)
      params.push(tok.lexeme)
      if !self.check(@lex.TokenType::TkComma) {
        break
      }
      ignore(self.advance())
    }
  }
  ignore(self.expect(@lex.TokenType::TkRparen))
  (params, is_vararg)
}

///|
/// Parse a block of statements
fn Parser::parse_block(self : Parser) -> Stmt raise ParseError {
  let stmts : Array[Stmt] = []
  while true {
    match self.peek() {
      @lex.TokenType::TkEnd
      | @lex.TokenType::TkElse
      | @lex.TokenType::TkElseif
      | @lex.TokenType::TkUntil
      | @lex.TokenType::TkEof => break
      _ => {
        stmts.push(self.parse_stmt())
        // Optionally consume semicolons after statements
        while self.check(@lex.TokenType::TkSemicolon) {
          ignore(self.advance())
        }
      }
    }
  }
  Stmt::Block(stmts)
}

///|
/// Parse expression statement (assignment or function call)
fn Parser::parse_expr_stmt(self : Parser) -> Stmt raise ParseError {
  let first = self.parse_expr()

  // Check for comma (multi-value assignment: x,y = ...)
  let lvals : Array[Expr] = [first]
  while self.check(@lex.TokenType::TkComma) {
    ignore(self.advance())
    // Check if next is '=' (to avoid consuming rvalues)
    if self.check(@lex.TokenType::TkAssign) {
      break
    }
    lvals.push(self.parse_expr())
  }

  // Check if it's an assignment
  if self.check(@lex.TokenType::TkAssign) {
    ignore(self.advance())
    let rvals : Array[Expr] = [self.parse_expr()]
    while self.check(@lex.TokenType::TkComma) {
      ignore(self.advance())
      rvals.push(self.parse_expr())
    }
    return Stmt::Assign(lvals, rvals)
  }

  // Check if it's a function call or method call
  match first {
    Expr::Call(func, args) => Stmt::FunctionCall(func, args)
    Expr::MethodCall(obj, method, args) => Stmt::MethodCall(obj, method, args)
    _ =>
      raise ParseError::InvalidSyntax(
        message="Expected assignment or function call",
        line=self.lexer.current_line(),
      )
  }
}

///|
/// Parse an expression
pub fn Parser::parse_expr(self : Parser) -> Expr raise ParseError {
  self.parse_or()
}

///|
/// Parse logical OR expression
fn Parser::parse_or(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_and()
  while self.check(@lex.TokenType::TkOr) {
    ignore(self.advance())
    let right = self.parse_and()
    left = Expr::Or(left, right)
  }
  left
}

///|
/// Parse logical AND expression
fn Parser::parse_and(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_comparison()
  while self.check(@lex.TokenType::TkAnd) {
    ignore(self.advance())
    let right = self.parse_comparison()
    left = Expr::And(left, right)
  }
  left
}

///|
/// Parse comparison expression
fn Parser::parse_comparison(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_bitor()
  while true {
    match self.peek() {
      @lex.TokenType::TkEq => {
        ignore(self.advance())
        left = Expr::Eq(left, self.parse_bitor())
      }
      @lex.TokenType::TkNe => {
        ignore(self.advance())
        left = Expr::Ne(left, self.parse_bitor())
      }
      @lex.TokenType::TkLt => {
        ignore(self.advance())
        left = Expr::Lt(left, self.parse_bitor())
      }
      @lex.TokenType::TkLe => {
        ignore(self.advance())
        left = Expr::Le(left, self.parse_bitor())
      }
      @lex.TokenType::TkGt => {
        ignore(self.advance())
        left = Expr::Gt(left, self.parse_bitor())
      }
      @lex.TokenType::TkGe => {
        ignore(self.advance())
        left = Expr::Ge(left, self.parse_bitor())
      }
      _ => break
    }
  }
  left
}

///|
/// Parse bitwise OR expression (|)
fn Parser::parse_bitor(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_bitxor()
  while self.check(@lex.TokenType::TkBitOr) {
    ignore(self.advance())
    left = Expr::BOr(left, self.parse_bitxor())
  }
  left
}

///|
/// Parse bitwise XOR expression (~)
fn Parser::parse_bitxor(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_bitand()
  while self.check(@lex.TokenType::TkBitXor) {
    ignore(self.advance())
    left = Expr::BXor(left, self.parse_bitand())
  }
  left
}

///|
/// Parse bitwise AND expression (&)
fn Parser::parse_bitand(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_bitshift()
  while self.check(@lex.TokenType::TkBitAnd) {
    ignore(self.advance())
    left = Expr::BAnd(left, self.parse_bitshift())
  }
  left
}

///|
/// Parse bitwise shift expression (<< >>)
fn Parser::parse_bitshift(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_concat()
  while true {
    match self.peek() {
      @lex.TokenType::TkShl => {
        ignore(self.advance())
        left = Expr::Shl(left, self.parse_concat())
      }
      @lex.TokenType::TkShr => {
        ignore(self.advance())
        left = Expr::Shr(left, self.parse_concat())
      }
      _ => break
    }
  }
  left
}

///|
/// Parse concatenation expression
fn Parser::parse_concat(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_additive()
  while self.check(@lex.TokenType::TkConcat) {
    ignore(self.advance())
    let right = self.parse_additive()
    left = Expr::Concat(left, right)
  }
  left
}

///|
/// Parse additive expression (+ -)
fn Parser::parse_additive(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_multiplicative()
  while true {
    match self.peek() {
      @lex.TokenType::TkPlus => {
        ignore(self.advance())
        left = Expr::Add(left, self.parse_multiplicative())
      }
      @lex.TokenType::TkMinus => {
        ignore(self.advance())
        left = Expr::Sub(left, self.parse_multiplicative())
      }
      _ => break
    }
  }
  left
}

///|
/// Parse multiplicative expression (* / %)
fn Parser::parse_multiplicative(self : Parser) -> Expr raise ParseError {
  let mut left = self.parse_unary()
  while true {
    match self.peek() {
      @lex.TokenType::TkMul => {
        ignore(self.advance())
        left = Expr::Mul(left, self.parse_unary())
      }
      @lex.TokenType::TkDiv => {
        ignore(self.advance())
        left = Expr::Div(left, self.parse_unary())
      }
      @lex.TokenType::TkFloorDiv => {
        ignore(self.advance())
        left = Expr::Idiv(left, self.parse_unary())
      }
      @lex.TokenType::TkMod => {
        ignore(self.advance())
        left = Expr::Mod(left, self.parse_unary())
      }
      _ => break
    }
  }
  left
}

///|
/// Parse unary expression (- not # ~)
fn Parser::parse_unary(self : Parser) -> Expr raise ParseError {
  match self.peek() {
    @lex.TokenType::TkNot => {
      ignore(self.advance())
      Expr::Not(self.parse_unary())
    }
    @lex.TokenType::TkLen => {
      ignore(self.advance())
      Expr::Len(self.parse_unary())
    }
    @lex.TokenType::TkMinus => {
      ignore(self.advance())
      // Unary minus: -expr = 0 - expr
      Expr::Sub(Expr::Number(0.0), self.parse_unary())
    }
    @lex.TokenType::TkBitXor => {
      ignore(self.advance())
      // Unary bitwise NOT: ~expr
      Expr::BNot(self.parse_unary())
    }
    _ => self.parse_power()
  }
}

///|
/// Parse power expression (^, right associative)
fn Parser::parse_power(self : Parser) -> Expr raise ParseError {
  let left = self.parse_postfix()
  if self.check(@lex.TokenType::TkPow) {
    ignore(self.advance())
    Expr::Pow(left, self.parse_unary()) // Right associative, allow unary on RHS
  } else {
    left
  }
}

///|
/// Parse postfix expression (function call, indexing, field access)
fn Parser::parse_postfix(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_primary()
  while true {
    match self.peek() {
      @lex.TokenType::TkLparen => {
        // Function call
        ignore(self.advance())
        let args : Array[Expr] = []
        if !self.check(@lex.TokenType::TkRparen) {
          args.push(self.parse_expr())
          while self.check(@lex.TokenType::TkComma) {
            ignore(self.advance())
            args.push(self.parse_expr())
          }
        }
        ignore(self.expect(@lex.TokenType::TkRparen))
        expr = Expr::Call(expr, args)
      }
      @lex.TokenType::TkString => {
        // Function call with string literal (no parens)
        let tok = self.advance()
        expr = Expr::Call(expr, [Expr::String(tok.lexeme)])
      }
      @lex.TokenType::TkLbrace => {
        // Function call with table constructor (no parens)
        let table = self.parse_table_constructor()
        expr = Expr::Call(expr, [table])
      }
      @lex.TokenType::TkLbracket => {
        // Indexing
        ignore(self.advance())
        let index = self.parse_expr()
        ignore(self.expect(@lex.TokenType::TkRbracket))
        expr = Expr::Index(expr, index)
      }
      @lex.TokenType::TkDot => {
        // Field access
        ignore(self.advance())
        let field_tok = self.expect(@lex.TokenType::TkName)
        expr = Expr::Field(expr, field_tok.lexeme)
      }
      @lex.TokenType::TkColon => {
        // Method call: obj:method(args)
        ignore(self.advance())
        let method_tok = self.expect(@lex.TokenType::TkName)
        ignore(self.expect(@lex.TokenType::TkLparen))
        let args : Array[Expr] = []
        if !self.check(@lex.TokenType::TkRparen) {
          args.push(self.parse_expr())
          while self.check(@lex.TokenType::TkComma) {
            ignore(self.advance())
            args.push(self.parse_expr())
          }
        }
        ignore(self.expect(@lex.TokenType::TkRparen))
        expr = Expr::MethodCall(expr, method_tok.lexeme, args)
      }
      _ => break
    }
  }
  expr
}

///|
/// Parse primary expression (literals, names, tables, parenthesized)
fn Parser::parse_primary(self : Parser) -> Expr raise ParseError {
  match self.peek() {
    @lex.TokenType::TkNil => {
      ignore(self.advance())
      Expr::Nil
    }
    @lex.TokenType::TkTrue => {
      ignore(self.advance())
      Expr::Bool(true)
    }
    @lex.TokenType::TkFalse => {
      ignore(self.advance())
      Expr::Bool(false)
    }
    @lex.TokenType::TkNumber => {
      let tok = self.advance()
      // Parse the number
      let num = if tok.lexeme.starts_with("0x") || tok.lexeme.starts_with("0X") {
        // Parse hex number
        let hex_str = tok.lexeme.substring(start=2) // Skip "0x" or "0X"
        match parse_hex(hex_str) {
          Some(v) => v.to_double()
          None =>
            raise ParseError::InvalidSyntax(
              message="Invalid hex number literal",
              line=tok.line,
            )
        }
      } else {
        @strconv.parse_double(tok.lexeme) catch {
          _ =>
            raise ParseError::InvalidSyntax(
              message="Invalid number literal",
              line=tok.line,
            )
        }
      }
      Expr::Number(num)
    }
    @lex.TokenType::TkString => {
      let tok = self.advance()
      Expr::String(tok.lexeme)
    }
    @lex.TokenType::TkName => {
      let tok = self.advance()
      Expr::Name(tok.lexeme)
    }
    @lex.TokenType::TkDots => {
      ignore(self.advance())
      Expr::Vararg
    }
    @lex.TokenType::TkLparen => {
      ignore(self.advance())
      let expr = self.parse_expr()
      ignore(self.expect(@lex.TokenType::TkRparen))
      expr
    }
    @lex.TokenType::TkLbrace => self.parse_table_constructor()
    @lex.TokenType::TkFunction => self.parse_function_expr()
    _ => {
      let tok = self.advance()
      raise ParseError::UnexpectedToken(
        expected="expression",
        actual=tok.type_.to_string(),
        line=tok.line,
      )
    }
  }
}

///|
/// Parse table constructor
fn Parser::parse_table_constructor(self : Parser) -> Expr raise ParseError {
  ignore(self.expect(@lex.TokenType::TkLbrace))
  let fields : Array[(Expr?, Expr)] = []
  while !self.check(@lex.TokenType::TkRbrace) {
    // Check for [key] = value
    if self.check(@lex.TokenType::TkLbracket) {
      ignore(self.advance())
      let key = self.parse_expr()
      ignore(self.expect(@lex.TokenType::TkRbracket))
      ignore(self.expect(@lex.TokenType::TkAssign))
      let value = self.parse_expr()
      fields.push((Some(key), value))
    } else {
      // Try to parse name = value
      let start_pos = self.lexer.current_line()
      let first = self.parse_expr()
      if self.check(@lex.TokenType::TkAssign) {
        // It's name = value
        match first {
          Expr::Name(name) => {
            ignore(self.advance())
            let value = self.parse_expr()
            fields.push((Some(Expr::String(name)), value))
          }
          _ =>
            raise ParseError::InvalidSyntax(
              message="Expected field name before =",
              line=start_pos,
            )
        }
      } else {
        // It's just a value (array-like entry)
        fields.push((None, first))
      }
    }

    // Optional comma or semicolon
    if self.check(@lex.TokenType::TkComma) ||
      self.check(@lex.TokenType::TkSemicolon) {
      ignore(self.advance())
    } else if !self.check(@lex.TokenType::TkRbrace) {
      raise ParseError::InvalidSyntax(
        message="Expected ',' or '}' in table constructor",
        line=self.lexer.current_line(),
      )
    }
  }
  ignore(self.expect(@lex.TokenType::TkRbrace))
  Expr::TableConstructor(fields)
}

///|
/// Parse function expression
fn Parser::parse_function_expr(self : Parser) -> Expr raise ParseError {
  ignore(self.expect(@lex.TokenType::TkFunction))
  let (params, is_vararg) = self.parse_param_list()
  let body = self.parse_block()
  ignore(self.expect(@lex.TokenType::TkEnd))
  Expr::Function(params, is_vararg, body)
}
