-- Test chained operations and complex combinations
print("=== Chained Operations ===")

-- Chained comparisons
print("Chained comparisons:")
print("  1 < 2 and 2 < 3 =", 1 < 2 and 2 < 3)
print("  5 > 3 and 3 > 1 and 1 > 0 =", 5 > 3 and 3 > 1 and 1 > 0)

-- Chained arithmetic
print("\nChained arithmetic:")
local result = 1 + 2 + 3 + 4 + 5
print("  1 + 2 + 3 + 4 + 5 =", result)

result = 100 - 10 - 5 - 3
print("  100 - 10 - 5 - 3 =", result)

result = 2 * 3 * 4
print("  2 * 3 * 4 =", result)

-- Chained table access
print("\nChained table access:")
local t = {a = {b = {c = 42}}}
print("  t.a.b.c =", t.a.b.c)

local arr = {{1, 2}, {3, 4}, {5, 6}}
print("  arr[2][1] =", arr[2][1])

-- Chained function calls
print("\nChained function calls:")
local function add1(x) return x + 1 end
local function mul2(x) return x * 2 end
print("  mul2(add1(5)) =", mul2(add1(5)))

-- Chained string operations
print("\nChained strings:")
local s = "hello" .. " " .. "world" .. "!"
print("  Chained concat =", s)

print("  #('a' .. 'b' .. 'c') =", #("a" .. "b" .. "c"))

-- Chained logical operations
print("\nChained logical:")
print("  true and true and true =", true and true and true)
print("  true and true and false =", true and true and false)
print("  false or false or true =", false or false or true)

-- Mixed chaining
print("\nMixed chaining:")
print("  (1 + 2) * 3 - 4 =", (1 + 2) * 3 - 4)
print("  10 > 5 and 5 > 0 =", 10 > 5 and 5 > 0)

-- Chained not
print("\nChained not:")
print("  not not true =", not not true)
print("  not not false =", not not false)
print("  not not nil =", not not nil)

-- Chained length
print("\nChained length:")
local nested = {{1, 2, 3}}
print("  #nested =", #nested)
print("  #nested[1] =", #nested[1])

-- Chained type conversions
print("\nChained conversions:")
print("  tonumber('42') + 8 =", tonumber("42") + 8)
print("  tostring(10 + 20) =", tostring(10 + 20))

-- Chained assignment
-- BUG: Multiple assignment doesn't evaluate RHS before LHS
print("\nChained assignment:")
local a, b, c = 1, 2, 3
print("  a, b, c = 1, 2, 3")
a, b, c = b, c, a
print("  After a,b,c = b,c,a:")
print("  a, b, c =", a, b, c, "(BUG: should be 2,3,1, is 2,3,2)")

-- Complex nested expression
print("\nComplex nested:")
local complex = ((5 + 3) * 2 - 1) ^ 2 / 4
print("  ((5+3)*2-1)^2/4 =", complex)

-- Chained conditions
print("\nChained conditions:")
local x = 5
if x > 0 and x < 10 and x % 2 == 1 then
  print("  x is positive, single-digit, odd")
end

-- Chained table operations
print("\nChained table ops:")
local data = {x = 10}
data.y = data.x * 2
data.z = data.y + data.x
print("  data.z =", data.z)

-- Long chain of operations
print("\nLong chain:")
local long = 1
long = long + 1
long = long * 2
long = long - 3
long = long / 2
print("  After chain of ops: long =", long)

print("\n=== Chained operations complete! ===")
