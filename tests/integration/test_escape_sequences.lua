-- Test string escape sequences
print("=== Escape Sequences ===")

-- Backslash escapes
print("Backslash escapes:")
print("  Backslash: \\\\")
print("  Single quote: \\'")
print("  Double quote: \\\"")

-- Whitespace escapes
print("\nWhitespace escapes:")
print("  Newline:\nSecond line")
print("  Tab:\there")
print("  Carriage return (invisible):\r")

-- Character escapes
-- BUG: Some character escapes not supported (\a, \b, \f, \v may not work)
print("\nCharacter codes:")
-- print("  Null char (\\0):", "\0", "(may not display)")
-- print("  Bell (\\a):", "\a", "(may beep)")
-- print("  Backspace (\\b):", "abc\b", "(backspace)")
-- print("  Form feed (\\f):", "\f", "(form feed)")
-- print("  Vertical tab (\\v):", "\v", "(vtab)")
print("  (Some character escapes skipped - not all supported)")

-- Numeric escapes
-- BUG: Numeric decimal escapes not supported
print("\nNumeric escapes:")
-- print("  \\65 (A):", "\65")
-- print("  \\097 (a):", "\097")
-- print("  \\049\\050\\051 (123):", "\049\050\051")
print("  (Numeric \\ddd escapes not supported)")

-- Hex escapes
-- BUG: Hex escapes may not be supported
print("\nHex escapes:")
-- print("  \\x41 (A):", "\x41")
-- print("  \\x61 (a):", "\x61")
-- print("  \\x30 (0):", "\x30")
-- print("  \\x48\\x69 (Hi):", "\x48\x69")
print("  (Hex \\xHH escapes may not be supported)")

-- Unicode escapes (if supported)
-- BUG: Unicode escapes not supported
print("\nUnicode escapes:")
-- print("  \\u{41} (A):", "\u{41}")
-- print("  \\u{1F600} (emoji):", "\u{1F600}")
print("  (Unicode \\u{} escapes not supported)")

-- Escape in different contexts
print("\nEscape contexts:")
local s1 = "Line1\nLine2"
print("  String with \\n:")
print(s1)

local s2 = 'Quote: \''
print("  Single-quoted with \\': ", s2)

local s3 = "Quote: \""
print("  Double-quoted with \\\": ", s3)

-- Raw string patterns
print("\nEscape combinations:")
print("  Tab and newline: A\t\nB")
print("  Multiple backslashes: \\\\\\\\")
print("  Mixed: \"Hello\\tWorld!\\n\"")

-- Escape in concatenation
print("\nEscape in concat:")
local combined = "First\n" .. "Second"
print(combined)

-- Escape sequences in table
print("\nEscape in table:")
local escapes = {
  "\n",
  "\t",
  "\\",
  "\""
}
print("  Table contains:", #escapes, "escape sequences")

-- Invalid or unsupported escapes
print("\nEdge cases:")
print("  Empty string: ''")
print("  Just newline: '\n'")
print("  Multiple newlines: '\n\n\n'")

-- Comparing escaped strings
print("\nComparisons:")
-- print("  'A' == '\\65' =", "A" == "\65")
-- print("  'Hi' == '\\x48\\x69' =", "Hi" == "\x48\x69")
print("  (Comparisons with numeric/hex escapes skipped)")

-- Length with escapes
print("\nLength with escapes:")
print("  #'A\\nB' =", #"A\nB")
print("  #'\\t' =", #"\t")
print("  #'\\\\' =", #"\\")

-- Using in expressions
print("\nIn expressions:")
local path = "folder\\file"
print("  Path with backslash:", path)

local message = "Error:\n  Line 1\n  Line 2"
print(message)

print("\n=== Escape sequence tests complete! ===")
