-- Test various syntax features
print("=== Syntax Features ===")

-- Single line comments work (obviously!)
print("Single line comments:")
print("  Works!")

-- Multiple statements on one line with semicolon
print("\nMultiple statements:")
local a = 1; local b = 2; local c = a + b
print("  a=1; b=2; c=a+b =>", c)

-- Long variable names
print("\nLong variable names:")
local very_long_variable_name_with_underscores = 42
print("  very_long_variable_name =", very_long_variable_name_with_underscores)

-- Underscore in names
print("\nUnderscores:")
local _private = 10
local my_var = 20
local var_123 = 30
print("  _private, my_var, var_123 =", _private, my_var, var_123)

-- Unicode in strings (if supported)
-- BUG: Unicode escape sequences not supported
print("\nUnicode strings:")
-- local unicode_str = "Hello \u{1F600}"
-- print("  Unicode string:", unicode_str)
print("  (SKIPPED: \\u{} escape not supported)")

-- Escape sequences
print("\nEscape sequences:")
print("  Newline: 'a\\nb' =", "a\nb")
print("  Tab: 'a\\tb' =", "a\tb")
print("  Quote: 'a\\'b' =", "a'b")
print("  Backslash: 'a\\\\b' =", "a\\b")

-- Numeric literals
print("\nNumeric literals:")
print("  Decimal: 123 =", 123)
print("  Hex: 0xFF =", 0xFF)
-- print("  Binary: 0b1010 =", 0b1010)  -- Not supported
print("  (Binary literals not supported)")
print("  Scientific: 1e3 =", 1e3)
print("  Float: 3.14 =", 3.14)

-- Empty statements
print("\nEmpty statements:")
;;;;;;
print("  Multiple semicolons handled")

-- Nested blocks
print("\nNested blocks:")
do
  local x = 10
  do
    local y = 20
    print("  Inner block: x, y =", x, y)
  end
  print("  Outer block: x =", x)
end

-- Multiple return values in assignment
print("\nMultiple assignment:")
local function returns3()
  return 1, 2, 3
end
local x, y, z = returns3()
print("  x, y, z =", x, y, z)

-- Discarding return values
print("\nDiscarding returns:")
local first = returns3()
print("  first only =", first)

-- Assignment to existing variables
print("\nReassignment:")
local var = 10
print("  Initial: var =", var)
var = 20
print("  After reassign: var =", var)

print("\n=== Syntax feature tests complete! ===")
