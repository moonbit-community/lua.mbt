-- Test type system
print("=== Type System ===")

-- Different types
local n = 42
local s = "hello"
local b = true
local t = {1, 2, 3}
local f = function() end
local nil_val = nil

print("Type of 42:", type(n))
print("Type of 'hello':", type(s))
print("Type of true:", type(b))
print("Type of table:", type(t))
print("Type of function:", type(f))
print("Type of nil:", type(nil_val))

-- Type checking in conditionals
print("\nType-based conditionals:")
if type(n) == "number" then
  print("n is a number")
end

if type(s) == "string" then
  print("s is a string")
end

if type(t) == "table" then
  print("t is a table")
end

-- Type conversions
print("\nType conversions:")
local str_num = "123"
local num = tonumber(str_num)
print("tonumber('123') =", num, "type:", type(num))

local num_str = tostring(456)
print("tostring(456) =", num_str, "type:", type(num_str))

print("\n=== All type system tests passed! ===")
