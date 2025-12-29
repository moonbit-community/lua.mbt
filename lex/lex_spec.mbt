// Lua Lexer Specification
// Based on Lua 5.4's llex.h
// Tokenizes Lua source code

///|
/// Lua token types
pub(all) enum TokenType {
  // Literals
  TkNumber
  TkString
  TkName // identifiers

  // Keywords
  TkAnd
  TkBreak
  TkDo
  TkElse
  TkElseif
  TkEnd
  TkFalse
  TkFor
  TkFunction
  TkGoto
  TkIf
  TkIn
  TkLocal
  TkNil
  TkNot
  TkOr
  TkRepeat
  TkReturn
  TkThen
  TkTrue
  TkUntil
  TkWhile

  // Operators
  TkPlus // +
  TkMinus // -
  TkMul // *
  TkDiv // /
  TkMod // %
  TkPow // ^
  TkLen // #
  TkBitAnd // &
  TkBitOr // |
  TkBitXor // ~
  TkShl // <<
  TkShr // >>
  TkConcat // ..
  TkDots // ...
  TkEq // ==
  TkNe // ~=
  TkLe // <=
  TkGe // >=
  TkLt // <
  TkGt // >
  TkAssign // =

  // Delimiters
  TkLparen // (
  TkRparen // )
  TkLbrace // {
  TkRbrace // }
  TkLbracket // [
  TkRbracket // ]
  TkSemicolon // ;
  TkColon // :
  TkComma // ,
  TkDot // .
  TkEof
} derive(Eq, Show, ToJson)

///|
/// Lexer errors
pub(all) suberror LexError {
  UnexpectedChar(pos~ : Int, char~ : Char)
  UnterminatedString(pos~ : Int)
  InvalidNumber(pos~ : Int, text~ : String)
  InvalidEscape(pos~ : Int, char~ : Char)
} derive(Eq, Show, ToJson)

///|
/// Token with position information
pub(all) struct Token {
  type_ : TokenType
  lexeme : String
  line : Int
  column : Int
} derive(Eq, Show, ToJson)

///|
/// Lexer state
#declaration_only
pub type Lexer

///|
/// Create a new lexer from source code
#declaration_only
pub fn Lexer::new(source : String) -> Lexer {
  ...
}

///|
/// Get the next token
#declaration_only
pub fn Lexer::next_token(self : Lexer) -> Token raise LexError {
  ...
}

///|
/// Peek at the next token without consuming it
#declaration_only
pub fn Lexer::peek_token(self : Lexer) -> Token raise LexError {
  ...
}

///|
/// Check if we've reached end of input
#declaration_only
pub fn Lexer::is_eof(self : Lexer) -> Bool {
  ...
}

///|
/// Get current line number
#declaration_only
pub fn Lexer::current_line(self : Lexer) -> Int {
  ...
}

///|
/// Get current column number
#declaration_only
pub fn Lexer::current_column(self : Lexer) -> Int {
  ...
}
