-- Test various edge cases and advanced features

-- Unary operators
print("Unary operators:")
local x = 10
print("-10 =", -x)
print("-(-10) =", -(-x))

-- String concatenation with automatic number conversion
print("\nString concatenation:")
local s1 = "Number: " .. 42
print(s1)
local s2 = 3.14 .. " is pi"
print(s2)

-- Nested function calls
print("\nNested function calls:")
function add(a, b)
  return a + b
end

function mul(a, b)
  return a * b
end

local result = add(mul(2, 3), mul(4, 5))
print("add(mul(2,3), mul(4,5)) =", result)

-- Break in loops
print("\nBreak statement:")
for i = 1, 10 do
  if i == 4 then
    break
  end
  print("i =", i)
end

-- Global variables
print("\nGlobal variables:")
globalVar = 42
print("globalVar =", globalVar)

function useGlobal()
  return globalVar * 2
end

print("useGlobal() =", useGlobal())

-- Truthiness with 0 and empty string
print("\nLua truthiness (0 and empty string are truthy):")
print("0 and 42 =", 0 and 42)
print("'' and 'hello' =", "" and "hello")
