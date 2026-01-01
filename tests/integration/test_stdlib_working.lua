-- Test basic stdlib functions that actually work
print("=== Working Stdlib Functions ===")

-- type() function
print("type() function:")
print("  type(42) =", type(42))
print("  type('hello') =", type("hello"))
print("  type(true) =", type(true))
print("  type(nil) =", type(nil))
print("  type({}) =", type({}))
local function f() end
print("  type(function) =", type(f))

-- tonumber() function
print("\ntonumber() function:")
print("  tonumber('42') =", tonumber("42"))
print("  tonumber('3.14') =", tonumber("3.14"))
print("  tonumber('0') =", tonumber("0"))
print("  tonumber('-5') =", tonumber("-5"))
print("  tonumber('not a number') =", tonumber("not a number"))
print("  tonumber('  123  ') =", tonumber("  123  "))

-- tonumber() with base
print("\ntonumber() with base:")
print("  tonumber('10', 10) =", tonumber("10", 10))
print("  tonumber('10', 2) =", tonumber("10", 2))
print("  tonumber('10', 8) =", tonumber("10", 8))
print("  tonumber('FF', 16) =", tonumber("FF", 16))
print("  tonumber('ff', 16) =", tonumber("ff", 16))

-- tostring() function
print("\ntostring() function:")
print("  tostring(42) =", tostring(42))
print("  tostring(3.14) =", tostring(3.14))
print("  tostring(true) =", tostring(true))
print("  tostring(false) =", tostring(false))
print("  tostring(nil) =", tostring(nil))
print("  tostring('hello') =", tostring("hello"))

-- tostring() with table/function
print("\ntostring() with complex types:")
local t = {}
print("  tostring({}) = " .. tostring(t) .. " (address)")
local func = function() end
print("  tostring(function) = " .. tostring(func) .. " (address)")

-- Combining stdlib functions
print("\nCombining functions:")
print("  type(tonumber('42')) =", type(tonumber("42")))
print("  tostring(type(42)) =", tostring(type(42)))
print("  tonumber(tostring(100)) =", tonumber(tostring(100)))

-- Edge cases
print("\nEdge cases:")
print("  type(type) =", type(type))
print("  type(tonumber) =", type(tonumber))
print("  type(tostring) =", type(tostring))
print("  type(print) =", type(print))

-- Using in expressions
print("\nIn expressions:")
if type(42) == "number" then
  print("  42 is a number")
end

local num = tonumber("10") + 5
print("  tonumber('10') + 5 =", num)

local str = "Value: " .. tostring(42)
print("  'Value: ' .. tostring(42) =", str)

-- Using in table
print("\nIn tables:")
local types = {
  type(1),
  type("a"),
  type(true),
  type(nil)
}
print("  types table:", types[1], types[2], types[3], types[4])

-- Converting between types
print("\nType conversions:")
local s = "100"
local n = tonumber(s)
print("  '100' -> number:", n, type(n))

local n2 = 200
local s2 = tostring(n2)
print("  200 -> string:", s2, type(s2))

-- Handling failures
print("\nHandling failures:")
local failed = tonumber("xyz")
if failed == nil then
  print("  tonumber('xyz') correctly returns nil")
end

-- Using with operators
print("\nWith operators:")
print("  tonumber('5') * 2 =", tonumber("5") * 2)
print("  tostring(10) .. tostring(20) =", tostring(10) .. tostring(20))

-- Boolean conversions
print("\nBoolean conversions:")
print("  tostring(true) =", tostring(true))
print("  tostring(false) =", tostring(false))
print("  type(true) =", type(true))
print("  type(false) =", type(false))

print("\n=== Working stdlib tests complete! ===")
