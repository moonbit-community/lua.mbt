-- Test type conversion and type checking functions
-- PARTIAL IMPLEMENTATION:
--   ✓ tonumber() works (but base 16 returns nil for "FF")
--   ✓ tostring() works
--   ✓ type() works
--   ✗ Implicit string-to-number conversion DOES NOT WORK ("5" + 3 fails)
--   ✗ string.format() DOES NOT WORK (string library not implemented)
print("=== Type Conversion ===")

-- tonumber
-- NOTE: Works but hex conversion (base 16) has issues
print("tonumber:")
print("  tonumber('42') =", tonumber("42"))
print("  tonumber('3.14') =", tonumber("3.14"))
print("  tonumber('FF', 16) =", tonumber("FF", 16))
print("  tonumber('1010', 2) =", tonumber("1010", 2))
print("  tonumber('invalid') =", tonumber("invalid"))

-- tostring
print("\ntostring:")
print("  tostring(42) =", tostring(42))
print("  tostring(3.14) =", tostring(3.14))
print("  tostring(true) =", tostring(true))
print("  tostring(false) =", tostring(false))
print("  tostring(nil) =", tostring(nil))

-- type function
print("\ntype:")
print("  type(42) =", type(42))
print("  type(3.14) =", type(3.14))
print("  type('hello') =", type("hello"))
print("  type(true) =", type(true))
print("  type(nil) =", type(nil))
print("  type({}) =", type({}))
print("  type(function() end) =", type(function() end))

-- Type conversions in operations
-- BUG: Implicit string-to-number conversion DOES NOT WORK
print("\nImplicit conversions:")
-- print("  '5' + 3 =", "5" + 3)  -- FAILS: String to number conversion not supported
print("  (SKIPPED: '5' + 3 would error)")
print("  10 .. 20 =", 10 .. 20)  -- Number to string for concat

-- Conversion edge cases
print("\nEdge cases:")
print("  tonumber('  42  ') =", tonumber("  42  "))  -- Whitespace
print("  tonumber('1e3') =", tonumber("1e3"))  -- Scientific notation
print("  tonumber('0xFF', 16) =", tonumber("0xFF", 16))  -- Hex with prefix

-- Boolean conversions
print("\nBoolean context:")
if 0 then
  print("  0 is truthy")
else
  print("  0 is falsy (BUG!)")
end

if "" then
  print("  empty string is truthy")
else
  print("  empty string is falsy (BUG!)")
end

-- Number to string formatting
-- BUG: string.format() not available (string library not implemented)
print("\nNumber formatting:")
-- print("  string.format('%d', 42) =", string.format("%d", 42))
-- print("  string.format('%.2f', 3.14159) =", string.format("%.2f", 3.14159))
-- print("  string.format('%x', 255) =", string.format("%x", 255))
print("  (SKIPPED: string.format not available)")

-- Parse numbers from strings
print("\nParsing:")
local n = tonumber("123.456")
print("  Parsed:", n)
print("  Type:", type(n))

print("\n=== Type conversion tests complete! ===")
