// Lua Lexer Implementation
// Based on Lua 5.4's llex.c
// Tokenizes Lua source code

///|
/// Lexer state
pub struct Lexer {
  source : String
  mut pos : Int
  mut line : Int
  mut column : Int
  mut peek : Token?
} derive(Show)

///|
/// Create a new lexer from source code
pub fn Lexer::new(source : String) -> Lexer {
  Lexer::{ source, pos: 0, line: 1, column: 1, peek: None }
}

///|
/// Check if character is a whitespace
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// Check if character can start an identifier
fn is_ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
/// Check if character can be in an identifier
fn is_ident_continue(c : Char) -> Bool {
  is_ident_start(c) || (c >= '0' && c <= '9')
}

///|
/// Check if character is a digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Check if character is a hex digit
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
/// Map keyword strings to token types
fn keyword_type(word : String) -> TokenType? {
  match word {
    "and" => Some(TokenType::TkAnd)
    "break" => Some(TokenType::TkBreak)
    "do" => Some(TokenType::TkDo)
    "else" => Some(TokenType::TkElse)
    "elseif" => Some(TokenType::TkElseif)
    "end" => Some(TokenType::TkEnd)
    "false" => Some(TokenType::TkFalse)
    "for" => Some(TokenType::TkFor)
    "function" => Some(TokenType::TkFunction)
    "goto" => Some(TokenType::TkGoto)
    "if" => Some(TokenType::TkIf)
    "in" => Some(TokenType::TkIn)
    "local" => Some(TokenType::TkLocal)
    "nil" => Some(TokenType::TkNil)
    "not" => Some(TokenType::TkNot)
    "or" => Some(TokenType::TkOr)
    "repeat" => Some(TokenType::TkRepeat)
    "return" => Some(TokenType::TkReturn)
    "then" => Some(TokenType::TkThen)
    "true" => Some(TokenType::TkTrue)
    "until" => Some(TokenType::TkUntil)
    "while" => Some(TokenType::TkWhile)
    _ => None
  }
}

///|
/// Get current character without consuming
fn Lexer::current(self : Lexer) -> Char? {
  if self.pos >= self.source.length() {
    None
  } else {
    self.source.get_char(self.pos)
  }
}

///|
/// Advance position and return current character
fn Lexer::advance(self : Lexer) -> Char? {
  match self.current() {
    None => None
    Some(c) => {
      self.pos = self.pos + 1
      if c == '\n' {
        self.line = self.line + 1
        self.column = 1
      } else {
        self.column = self.column + 1
      }
      Some(c)
    }
  }
}

///|
/// Peek at next character without consuming
fn Lexer::peek_char(self : Lexer) -> Char? {
  if self.pos + 1 >= self.source.length() {
    None
  } else {
    self.source.get_char(self.pos + 1)
  }
}

///|
/// Skip whitespace and comments
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while true {
    match self.current() {
      None => break
      Some(c) => {
        if is_whitespace(c) {
          ignore(self.advance())
          continue
        }
        // Single-line comment
        if c == '-' {
          match self.peek_char() {
            Some('-') => {
              ignore(self.advance()) // consume first -
              ignore(self.advance()) // consume second -
              // Skip until end of line
              while true {
                match self.current() {
                  None => break
                  Some('\n') => {
                    ignore(self.advance())
                    break
                  }
                  _ => ignore(self.advance())
                }
              }
              continue
            }
            _ => break
          }
        }
        break
      }
    }
  }
}

///|
/// Scan a number token
fn Lexer::scan_number(self : Lexer) -> Token raise LexError {
  let start_line = self.line
  let start_column = self.column
  let start_pos = self.pos

  // Check for hex numbers
  if self.current() == Some('0') {
    match self.peek_char() {
      Some('x') | Some('X') => {
        ignore(self.advance()) // consume 0
        ignore(self.advance()) // consume x
        // Read hex digits
        while true {
          match self.current() {
            Some(c) if is_hex_digit(c) => ignore(self.advance())
            _ => break
          }
        }
        let lexeme = (try! self.source[start_pos:self.pos]).to_string()
        return Token::{
          type_: TokenType::TkNumber,
          lexeme,
          line: start_line,
          column: start_column,
        }
      }
      _ => ()
    }
  }

  // Read integer part
  while true {
    match self.current() {
      Some(c) if is_digit(c) => ignore(self.advance())
      _ => break
    }
  }

  // Check for decimal point
  if self.current() == Some('.') {
    // Make sure it's not ".." (concat operator)
    if self.peek_char() != Some('.') {
      ignore(self.advance()) // consume .
      // Read fractional part
      while true {
        match self.current() {
          Some(c) if is_digit(c) => ignore(self.advance())
          _ => break
        }
      }
    }
  }

  // Check for exponent
  match self.current() {
    Some('e') | Some('E') => {
      ignore(self.advance())
      // Optional sign
      match self.current() {
        Some('+') | Some('-') => ignore(self.advance())
        _ => ()
      }
      // Read exponent digits
      while true {
        match self.current() {
          Some(c) if is_digit(c) => ignore(self.advance())
          _ => break
        }
      }
    }
    _ => ()
  }
  let lexeme = (try! self.source[start_pos:self.pos]).to_string()
  Token::{
    type_: TokenType::TkNumber,
    lexeme,
    line: start_line,
    column: start_column,
  }
}

///|
/// Scan a string token
fn Lexer::scan_string(self : Lexer, quote : Char) -> Token raise LexError {
  let start_line = self.line
  let start_column = self.column
  ignore(self.advance()) // consume opening quote
  let content = StringBuilder::new()
  while true {
    match self.current() {
      None => raise LexError::UnterminatedString(pos=self.pos)
      Some(c) => {
        if c == quote {
          ignore(self.advance()) // consume closing quote
          break
        }
        if c == '\\' {
          ignore(self.advance())
          match self.current() {
            None => raise LexError::UnterminatedString(pos=self.pos)
            Some('n') => {
              content.write_char('\n')
              ignore(self.advance())
            }
            Some('t') => {
              content.write_char('\t')
              ignore(self.advance())
            }
            Some('r') => {
              content.write_char('\r')
              ignore(self.advance())
            }
            Some('a') => {
              content.write_char('\u0007')  // Bell/alert
              ignore(self.advance())
            }
            Some('b') => {
              content.write_char('\u0008')  // Backspace
              ignore(self.advance())
            }
            Some('f') => {
              content.write_char('\u000C')  // Form feed
              ignore(self.advance())
            }
            Some('v') => {
              content.write_char('\u000B')  // Vertical tab
              ignore(self.advance())
            }
            Some('\\') => {
              content.write_char('\\')
              ignore(self.advance())
            }
            Some('"') => {
              content.write_char('"')
              ignore(self.advance())
            }
            Some('\'') => {
              content.write_char('\'')
              ignore(self.advance())
            }
            Some('x') => {
              // Hex escape \xHH (exactly 2 hex digits)
              ignore(self.advance())
              let mut hex_value = 0
              let mut digit_count = 0
              while digit_count < 2 {
                match self.current() {
                  Some(d) if is_hex_digit(d) => {
                    let digit_val = if d >= '0' && d <= '9' {
                      d.to_int() - '0'.to_int()
                    } else if d >= 'a' && d <= 'f' {
                      d.to_int() - 'a'.to_int() + 10
                    } else {
                      d.to_int() - 'A'.to_int() + 10
                    }
                    hex_value = hex_value * 16 + digit_val
                    digit_count = digit_count + 1
                    ignore(self.advance())
                  }
                  _ => raise LexError::InvalidEscape(pos=self.pos, char='x')
                }
              }
              content.write_char(hex_value.unsafe_to_char())
            }
            Some(d) if is_digit(d) => {
              // Decimal escape \ddd (up to 3 digits, max 255)
              let mut dec_value = d.to_int() - '0'.to_int()
              ignore(self.advance())
              let mut digit_count = 1
              while digit_count < 3 {
                match self.current() {
                  Some(d2) if is_digit(d2) => {
                    let new_value = dec_value * 10 + (d2.to_int() - '0'.to_int())
                    if new_value > 255 {
                      break
                    }
                    dec_value = new_value
                    digit_count = digit_count + 1
                    ignore(self.advance())
                  }
                  _ => break
                }
              }
              content.write_char(dec_value.unsafe_to_char())
            }
            Some(esc) => raise LexError::InvalidEscape(pos=self.pos, char=esc)
          }
        } else {
          content.write_char(c)
          ignore(self.advance())
        }
      }
    }
  }
  Token::{
    type_: TokenType::TkString,
    lexeme: content.to_string(),
    line: start_line,
    column: start_column,
  }
}

///|
/// Scan a long string token [[...]]
fn Lexer::scan_long_string(self : Lexer) -> Token raise LexError {
  let start_line = self.line
  let start_column = self.column

  // Consume first '['
  ignore(self.advance())

  // Count '=' characters for nesting level: [===[...]===]
  let mut equals_count = 0
  while self.current() == Some('=') {
    equals_count = equals_count + 1
    ignore(self.advance())
  }

  // Expect second '['
  match self.current() {
    Some('[') => ignore(self.advance())
    _ => raise LexError::InvalidLongString(pos=self.pos)
  }

  // Skip first newline if present (Lua convention)
  if self.current() == Some('\n') {
    ignore(self.advance())
  } else if self.current() == Some('\r') {
    ignore(self.advance())
    if self.current() == Some('\n') {
      ignore(self.advance())
    }
  }

  // Read content until closing ']' with matching '=' count
  let content = StringBuilder::new()
  while true {
    match self.current() {
      None => raise LexError::UnterminatedLongString(pos=self.pos)
      Some(']') => {
        // Check if this is the closing bracket
        let save_pos = self.pos
        let save_line = self.line
        let save_column = self.column

        ignore(self.advance()) // consume ']'

        // Count '=' characters
        let mut found_equals = 0
        while self.current() == Some('=') && found_equals < equals_count {
          found_equals = found_equals + 1
          ignore(self.advance())
        }

        // Check for final ']'
        if found_equals == equals_count && self.current() == Some(']') {
          ignore(self.advance()) // consume final ']'
          break  // Found closing delimiter
        } else {
          // False alarm, restore position and add to content
          self.pos = save_pos
          self.line = save_line
          self.column = save_column
          content.write_char(']')
          ignore(self.advance())
        }
      }
      Some(c) => {
        content.write_char(c)
        ignore(self.advance())
      }
    }
  }

  Token::{
    type_: TokenType::TkString,
    lexeme: content.to_string(),
    line: start_line,
    column: start_column,
  }
}

///|
/// Scan an identifier or keyword
fn Lexer::scan_identifier(self : Lexer) -> Token {
  let start_line = self.line
  let start_column = self.column
  let start_pos = self.pos
  while true {
    match self.current() {
      Some(c) if is_ident_continue(c) => ignore(self.advance())
      _ => break
    }
  }
  let lexeme = (try! self.source[start_pos:self.pos]).to_string()
  let type_ = match keyword_type(lexeme) {
    Some(kw) => kw
    None => TokenType::TkName
  }
  Token::{ type_, lexeme, line: start_line, column: start_column }
}

///|
/// Get the next token (internal implementation)
fn Lexer::scan_token(self : Lexer) -> Token raise LexError {
  self.skip_whitespace()
  let start_line = self.line
  let start_column = self.column
  match self.current() {
    None =>
      Token::{
        type_: TokenType::TkEof,
        lexeme: "",
        line: start_line,
        column: start_column,
      }
    Some(c) => {
      // Numbers
      if is_digit(c) {
        return self.scan_number()
      }

      // Strings
      if c == '"' || c == '\'' {
        return self.scan_string(c)
      }

      // Identifiers and keywords
      if is_ident_start(c) {
        return self.scan_identifier()
      }

      // Operators and delimiters
      match c {
        '+' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkPlus,
            lexeme: "+",
            line: start_line,
            column: start_column,
          }
        }
        '-' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkMinus,
            lexeme: "-",
            line: start_line,
            column: start_column,
          }
        }
        '*' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkMul,
            lexeme: "*",
            line: start_line,
            column: start_column,
          }
        }
        '/' => {
          ignore(self.advance())
          // Check for floor division //
          match self.current() {
            Some('/') => {
              ignore(self.advance())
              Token::{
                type_: TokenType::TkFloorDiv,
                lexeme: "//",
                line: start_line,
                column: start_column,
              }
            }
            _ =>
              Token::{
                type_: TokenType::TkDiv,
                lexeme: "/",
                line: start_line,
                column: start_column,
              }
          }
        }
        '%' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkMod,
            lexeme: "%",
            line: start_line,
            column: start_column,
          }
        }
        '^' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkPow,
            lexeme: "^",
            line: start_line,
            column: start_column,
          }
        }
        '#' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkLen,
            lexeme: "#",
            line: start_line,
            column: start_column,
          }
        }
        '&' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkBitAnd,
            lexeme: "&",
            line: start_line,
            column: start_column,
          }
        }
        '|' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkBitOr,
            lexeme: "|",
            line: start_line,
            column: start_column,
          }
        }
        '~' => {
          ignore(self.advance())
          if self.current() == Some('=') {
            ignore(self.advance())
            Token::{
              type_: TokenType::TkNe,
              lexeme: "~=",
              line: start_line,
              column: start_column,
            }
          } else {
            Token::{
              type_: TokenType::TkBitXor,
              lexeme: "~",
              line: start_line,
              column: start_column,
            }
          }
        }
        '<' => {
          ignore(self.advance())
          match self.current() {
            Some('=') => {
              ignore(self.advance())
              Token::{
                type_: TokenType::TkLe,
                lexeme: "<=",
                line: start_line,
                column: start_column,
              }
            }
            Some('<') => {
              ignore(self.advance())
              Token::{
                type_: TokenType::TkShl,
                lexeme: "<<",
                line: start_line,
                column: start_column,
              }
            }
            _ =>
              Token::{
                type_: TokenType::TkLt,
                lexeme: "<",
                line: start_line,
                column: start_column,
              }
          }
        }
        '>' => {
          ignore(self.advance())
          match self.current() {
            Some('=') => {
              ignore(self.advance())
              Token::{
                type_: TokenType::TkGe,
                lexeme: ">=",
                line: start_line,
                column: start_column,
              }
            }
            Some('>') => {
              ignore(self.advance())
              Token::{
                type_: TokenType::TkShr,
                lexeme: ">>",
                line: start_line,
                column: start_column,
              }
            }
            _ =>
              Token::{
                type_: TokenType::TkGt,
                lexeme: ">",
                line: start_line,
                column: start_column,
              }
          }
        }
        '=' => {
          ignore(self.advance())
          if self.current() == Some('=') {
            ignore(self.advance())
            Token::{
              type_: TokenType::TkEq,
              lexeme: "==",
              line: start_line,
              column: start_column,
            }
          } else {
            Token::{
              type_: TokenType::TkAssign,
              lexeme: "=",
              line: start_line,
              column: start_column,
            }
          }
        }
        '.' => {
          ignore(self.advance())
          if self.current() == Some('.') {
            ignore(self.advance())
            if self.current() == Some('.') {
              ignore(self.advance())
              Token::{
                type_: TokenType::TkDots,
                lexeme: "...",
                line: start_line,
                column: start_column,
              }
            } else {
              Token::{
                type_: TokenType::TkConcat,
                lexeme: "..",
                line: start_line,
                column: start_column,
              }
            }
          } else {
            Token::{
              type_: TokenType::TkDot,
              lexeme: ".",
              line: start_line,
              column: start_column,
            }
          }
        }
        '(' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkLparen,
            lexeme: "(",
            line: start_line,
            column: start_column,
          }
        }
        ')' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkRparen,
            lexeme: ")",
            line: start_line,
            column: start_column,
          }
        }
        '{' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkLbrace,
            lexeme: "{",
            line: start_line,
            column: start_column,
          }
        }
        '}' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkRbrace,
            lexeme: "}",
            line: start_line,
            column: start_column,
          }
        }
        '[' => {
          // Check for long string [[...]] or [=[...]=] etc.
          // Look ahead to see if it's '[' or '='
          if self.pos + 1 < self.source.length() {
            let next_char = self.source[self.pos + 1].to_int().unsafe_to_char()
            if next_char == '[' || next_char == '=' {
              return self.scan_long_string()
            }
          }
          ignore(self.advance())
          Token::{
            type_: TokenType::TkLbracket,
            lexeme: "[",
            line: start_line,
            column: start_column,
          }
        }
        ']' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkRbracket,
            lexeme: "]",
            line: start_line,
            column: start_column,
          }
        }
        ';' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkSemicolon,
            lexeme: ";",
            line: start_line,
            column: start_column,
          }
        }
        ':' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkColon,
            lexeme: ":",
            line: start_line,
            column: start_column,
          }
        }
        ',' => {
          ignore(self.advance())
          Token::{
            type_: TokenType::TkComma,
            lexeme: ",",
            line: start_line,
            column: start_column,
          }
        }
        _ => raise LexError::UnexpectedChar(pos=self.pos, char=c)
      }
    }
  }
}

///|
/// Get the next token
pub fn Lexer::next_token(self : Lexer) -> Token raise LexError {
  match self.peek {
    Some(tok) => {
      self.peek = None
      tok
    }
    None => self.scan_token()
  }
}

///|
/// Peek at the next token without consuming it
pub fn Lexer::peek_token(self : Lexer) -> Token raise LexError {
  match self.peek {
    Some(tok) => tok
    None => {
      let tok = self.scan_token()
      self.peek = Some(tok)
      tok
    }
  }
}

///|
/// Check if we've reached end of input
pub fn Lexer::is_eof(self : Lexer) -> Bool {
  self.pos >= self.source.length()
}

///|
/// Get current line number
pub fn Lexer::current_line(self : Lexer) -> Int {
  self.line
}

///|
/// Get current column number
pub fn Lexer::current_column(self : Lexer) -> Int {
  self.column
}
