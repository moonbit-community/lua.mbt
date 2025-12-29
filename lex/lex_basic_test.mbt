// Basic tests for Lua lexer

///|
test "lex numbers" {
  let lexer = Lexer::new("42 3.14 0xFF")
  let tok1 = try! lexer.next_token()
  @json.inspect(tok1.type_, content="TkNumber")
  inspect(tok1.lexeme, content="42")
  let tok2 = try! lexer.next_token()
  @json.inspect(tok2.type_, content="TkNumber")
  inspect(tok2.lexeme, content="3.14")
  let tok3 = try! lexer.next_token()
  @json.inspect(tok3.type_, content="TkNumber")
  inspect(tok3.lexeme, content="0xFF")
}

///|
test "lex keywords" {
  let lexer = Lexer::new("if then else end")
  let tok1 = try! lexer.next_token()
  @json.inspect(tok1.type_, content="TkIf")
  let tok2 = try! lexer.next_token()
  @json.inspect(tok2.type_, content="TkThen")
  let tok3 = try! lexer.next_token()
  @json.inspect(tok3.type_, content="TkElse")
  let tok4 = try! lexer.next_token()
  @json.inspect(tok4.type_, content="TkEnd")
}

///|
test "lex identifiers" {
  let lexer = Lexer::new("foo bar_123 _test")
  let tok1 = try! lexer.next_token()
  @json.inspect(tok1.type_, content="TkName")
  inspect(tok1.lexeme, content="foo")
  let tok2 = try! lexer.next_token()
  @json.inspect(tok2.type_, content="TkName")
  inspect(tok2.lexeme, content="bar_123")
}

///|
test "lex strings" {
  let source =
    #|"hello world" 'test'
    #|
  let lexer = Lexer::new(source)
  let tok1 = try! lexer.next_token()
  @json.inspect(tok1.type_, content="TkString")
  inspect(tok1.lexeme, content="hello world")
  let tok2 = try! lexer.next_token()
  @json.inspect(tok2.type_, content="TkString")
  inspect(tok2.lexeme, content="test")
}

///|
test "lex operators" {
  let lexer = Lexer::new("+ - * / == ~= <= >=")
  @json.inspect((try! lexer.next_token()).type_, content="TkPlus")
  @json.inspect((try! lexer.next_token()).type_, content="TkMinus")
  @json.inspect((try! lexer.next_token()).type_, content="TkMul")
  @json.inspect((try! lexer.next_token()).type_, content="TkDiv")
  @json.inspect((try! lexer.next_token()).type_, content="TkEq")
  @json.inspect((try! lexer.next_token()).type_, content="TkNe")
  @json.inspect((try! lexer.next_token()).type_, content="TkLe")
  @json.inspect((try! lexer.next_token()).type_, content="TkGe")
}

///|
test "track line and column positions" {
  let source =
    #|local x = 1
    #|local y = 2
    #|
  let lexer = Lexer::new(source)
  let tok1 = try! lexer.next_token()
  inspect(tok1.line, content="1")
  inspect(tok1.column, content="1")
  ignore(try! lexer.next_token()) // x
  ignore(try! lexer.next_token()) // =
  ignore(try! lexer.next_token()) // 1
  let tok5 = try! lexer.next_token() // local on line 2
  inspect(tok5.line, content="2")
}
