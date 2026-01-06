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
  let lexer = Lexer::{ source, pos: 0, line: 1, column: 1, peek: None }

  // Skip shebang on first line (Unix script compatibility)
  // If first line starts with #, skip it
  if lexer.current() == Some('#') {
    while true {
      match lexer.current() {
        None => break
        Some('\n') => {
          ignore(lexer.advance())
          break
        }
        _ => ignore(lexer.advance())
      }
    }
  }

  lexer
}

///|
/// Check if character is a whitespace
/// Lua treats all control characters as whitespace outside strings
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\u000B' || c == '\u000C'
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
        // Comments starting with --
        if c == '-' {
          match self.peek_char() {
            Some('-') => {
              ignore(self.advance()) // consume first -
              ignore(self.advance()) // consume second -

              // Check for multiline comment --[[...]] or --[=[...]=]
              if self.current() == Some('[') {
                let save_pos = self.pos
                let save_line = self.line
                let save_column = self.column

                ignore(self.advance()) // consume '['

                // Count '=' characters
                let mut equals_count = 0
                while self.current() == Some('=') {
                  equals_count = equals_count + 1
                  ignore(self.advance())
                }

                // Check if this is a long comment
                if self.current() == Some('[') {
                  ignore(self.advance()) // consume second '['

                  // Skip until closing delimiter
                  while true {
                    match self.current() {
                      None => break // Unclosed comment, but continue lexing
                      Some(']') => {
                        // Check if this is the closing bracket
                        let check_pos = self.pos
                        let check_line = self.line
                        let check_column = self.column

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
                          // False alarm, restore position and continue
                          self.pos = check_pos
                          self.line = check_line
                          self.column = check_column
                          ignore(self.advance())
                        }
                      }
                      Some(_) => ignore(self.advance())
                    }
                  }
                  continue  // Done with multiline comment, look for more whitespace
                } else {
                  // Not a long comment, restore and treat as single-line
                  self.pos = save_pos
                  self.line = save_line
                  self.column = save_column
                }
              }

              // Single-line comment: skip until end of line
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

  // Check for hex numbers (including hex floats)
  if self.current() == Some('0') {
    match self.peek_char() {
      Some('x') | Some('X') => {
        ignore(self.advance()) // consume 0
        ignore(self.advance()) // consume x/X

        // Read hex integer part
        while true {
          match self.current() {
            Some(c) if is_hex_digit(c) => ignore(self.advance())
            _ => break
          }
        }

        // Check for hex decimal point
        if self.current() == Some('.') {
          ignore(self.advance()) // consume .
          // Read hex fractional part
          while true {
            match self.current() {
              Some(c) if is_hex_digit(c) => ignore(self.advance())
              _ => break
            }
          }
        }

        // Check for binary exponent (p or P)
        match self.current() {
          Some('p') | Some('P') => {
            ignore(self.advance())
            // Optional sign
            match self.current() {
              Some('+') | Some('-') => ignore(self.advance())
              _ => ()
            }
            // Read decimal exponent digits
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
            Some('z') => {
              // \z skips all subsequent whitespace (including newlines)
              ignore(self.advance())
              while true {
                match self.current() {
                  Some(c) if c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\u000B' || c == '\u000C' =>
                    ignore(self.advance())
                  _ => break
                }
              }
            }
            Some('\n') | Some('\r') => {
              // Backslash followed by newline: continue string on next line
              let c = self.current().unwrap()
              ignore(self.advance())
              // Handle \r\n as a single newline
              if c == '\r' && self.current() == Some('\n') {
                ignore(self.advance())
              }
              content.write_char('\n')
            }
            Some('u') => {
              // Unicode escape \u{XXX...} (hex digits in braces)
              ignore(self.advance())
              if self.current() != Some('{') {
                raise LexError::InvalidEscape(pos=self.pos, char='u')
              }
              ignore(self.advance())

              let mut unicode_value = 0
              let mut found_close = false
              let mut digit_count = 0

              while true {
                match self.current() {
                  Some('}') => {
                    found_close = true
                    ignore(self.advance())
                    break
                  }
                  Some(d) if is_hex_digit(d) => {
                    let digit_val = if d >= '0' && d <= '9' {
                      d.to_int() - '0'.to_int()
                    } else if d >= 'a' && d <= 'f' {
                      d.to_int() - 'a'.to_int() + 10
                    } else {
                      d.to_int() - 'A'.to_int() + 10
                    }
                    unicode_value = unicode_value * 16 + digit_val
                    digit_count = digit_count + 1
                    // Lua allows up to 8 hex digits (0x00000000 to 0x7FFFFFFF for theoretical UTF-8)
                    if digit_count > 8 {
                      raise LexError::InvalidEscape(pos=self.pos, char='u')
                    }
                    ignore(self.advance())
                  }
                  _ => raise LexError::InvalidEscape(pos=self.pos, char='u')
                }
              }

              if !found_close || digit_count == 0 {
                raise LexError::InvalidEscape(pos=self.pos, char='u')
              }

              // Convert to UTF-8 and write to content
              // For valid Unicode (0-0x10FFFF), use standard encoding
              // For values > 0x10FFFF, Lua encodes using extended UTF-8
              if unicode_value <= 0x7F {
                content.write_char(unicode_value.unsafe_to_char())
              } else if unicode_value < 0x100000 {
                // Use MoonBit's encoding for values < 0x100000
                // (MoonBit hangs for values >= 0x100000)
                content.write_char(unicode_value.unsafe_to_char())
              } else if unicode_value <= 0x3FFFFFF {
                // 5-byte UTF-8: 11111000 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx (21 bits)
                // Manual encoding to avoid MoonBit bug
                let b1 = 0xF8 | (unicode_value >> 24).land(0x03)
                let b2 = 0x80 | ((unicode_value >> 18).land(0x3F))
                let b3 = 0x80 | ((unicode_value >> 12).land(0x3F))
                let b4 = 0x80 | ((unicode_value >> 6).land(0x3F))
                let b5 = 0x80 | (unicode_value.land(0x3F))
                content.write_char(b1.unsafe_to_char())
                content.write_char(b2.unsafe_to_char())
                content.write_char(b3.unsafe_to_char())
                content.write_char(b4.unsafe_to_char())
                content.write_char(b5.unsafe_to_char())
              } else if unicode_value <= 0x7FFFFFFF {
                // 6-byte UTF-8: 11111100 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx (26 bits)
                let b1 = 0xFC | (unicode_value >> 30).land(0x01)
                let b2 = 0x80 | ((unicode_value >> 24).land(0x3F))
                let b3 = 0x80 | ((unicode_value >> 18).land(0x3F))
                let b4 = 0x80 | ((unicode_value >> 12).land(0x3F))
                let b5 = 0x80 | ((unicode_value >> 6).land(0x3F))
                let b6 = 0x80 | (unicode_value.land(0x3F))
                content.write_char(b1.unsafe_to_char())
                content.write_char(b2.unsafe_to_char())
                content.write_char(b3.unsafe_to_char())
                content.write_char(b4.unsafe_to_char())
                content.write_char(b5.unsafe_to_char())
                content.write_char(b6.unsafe_to_char())
              } else {
                // Value too large even for 6-byte UTF-8
                raise LexError::InvalidEscape(pos=self.pos, char='u')
              }
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
          // Check if it's a number starting with decimal point (e.g., .5)
          match self.peek_char() {
            Some(next) if is_digit(next) => return self.scan_number()
            _ => ()
          }
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
          // Check for :: (double colon for labels)
          if self.current() == Some(':') {
            ignore(self.advance())
            Token::{
              type_: TokenType::TkDoubleColon,
              lexeme: "::",
              line: start_line,
              column: start_column,
            }
          } else {
            Token::{
              type_: TokenType::TkColon,
              lexeme: ":",
              line: start_line,
              column: start_column,
            }
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
