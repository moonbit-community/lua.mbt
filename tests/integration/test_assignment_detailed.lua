-- Test assignment operations in detail
print("=== Assignment Operations ===")

-- Simple assignment
print("Simple assignment:")
local a = 10
print("  a = 10; a =", a)

-- Multiple assignment
print("\nMultiple assignment:")
local x, y, z = 1, 2, 3
print("  x, y, z = 1, 2, 3")
print("  x, y, z =", x, y, z)

-- Swapping values
-- BUG: Multiple assignment doesn't evaluate RHS before LHS
print("\nSwapping:")
local p, q = 5, 10
print("  Before: p, q =", p, q)
p, q = q, p
print("  After swap: p, q =", p, q, "(BUG: should be 10, 5)")

-- Too few values
print("\nToo few values:")
local m, n, o = 1
print("  m, n, o = 1")
print("  m, n, o =", m, n, o, "(extras correctly nil)")

-- Too many values
print("\nToo many values:")
local r, s = 1, 2, 3, 4
print("  r, s = 1, 2, 3, 4")
print("  r, s =", r, s)

-- Assignment from function
print("\nFrom function:")
local function multi()
  return 10, 20, 30
end
local a1, b1, c1 = multi()
print("  a1, b1, c1 =", a1, b1, c1)

-- Partial function return
local first = multi()
print("  first only =", first)

-- Global assignment
print("\nGlobal assignment:")
globalVar = 100
print("  globalVar =", globalVar)

-- Reassignment
print("\nReassignment:")
local val = 1
print("  Initial: val =", val)
val = 2
print("  After val = 2: val =", val)

-- Assignment in expression
print("\nAssignment in expression:")
local e = 5 + 3
print("  e = 5 + 3; e =", e)

-- Assignment from table
print("\nFrom table:")
local t = {x = 10, y = 20}
local tx, ty = t.x, t.y
print("  tx, ty = t.x, t.y")
print("  tx, ty =", tx, ty)

-- Assignment to table
print("\nTo table:")
local data = {}
data.a = 1
data.b = 2
print("  data.a, data.b =", data.a, data.b)

-- Chained assignment (not valid in Lua - syntax error)
print("\nChained assignment:")
-- v1 = v2 = 5  -- NOT VALID: Chained assignment syntax doesn't exist in Lua
print("  (Chained assignment like 'a = b = 5' is not valid Lua syntax)")

-- Assignment with operators
print("\nWith operators:")
local inc = 10
inc = inc + 5
print("  inc = inc + 5; inc =", inc)

local mul = 3
mul = mul * 2
print("  mul = mul * 2; mul =", mul)

-- Assignment from concatenation
print("\nFrom concatenation:")
local str = "Hello" .. " " .. "World"
print("  str =", str)

-- Multiple assignments in sequence
print("\nSequence:")
local seq1 = 1
local seq2 = 2
local seq3 = 3
print("  seq1, seq2, seq3 =", seq1, seq2, seq3)

-- Assignment in loop
print("\nIn loop:")
for i = 1, 3 do
  local loop_val = i * 2
  print("  i, loop_val =", i, loop_val)
end

-- Assignment with logical operators
print("\nWith logical:")
local or_val = nil or 42
print("  nil or 42 =", or_val)

local and_val = 10 and 20
print("  10 and 20 =", and_val)

-- Assignment with comparison
print("\nWith comparison:")
local cmp = 5 > 3
print("  5 > 3 =", cmp)

-- Assignment from length
print("\nFrom length:")
local arr = {1, 2, 3}
local len = #arr
print("  len = #arr; len =", len)

-- Assignment to array index
print("\nTo array:")
local array = {}
array[1] = "first"
array[2] = "second"
print("  array[1], array[2] =", array[1], array[2])

-- Assignment with nil
print("\nWith nil:")
local nil_var = nil
print("  nil_var =", nil_var)

-- Overwriting with nil
print("\nOverwriting with nil:")
local was_val = 42
print("  Before: was_val =", was_val)
was_val = nil
print("  After nil: was_val =", was_val)

-- Assignment from ternary-like
print("\nTernary-like:")
local condition = true
local ternary = condition and "yes" or "no"
print("  true and 'yes' or 'no' =", ternary)

-- Assignment with type conversion
print("\nWith conversion:")
local num_str = tostring(123)
print("  tostring(123) =", num_str, type(num_str))

local str_num = tonumber("456")
print("  tonumber('456') =", str_num, type(str_num))

-- Circular assignment
print("\nCircular:")
local c1, c2, c3 = 1, 2, 3
c1, c2, c3 = c2, c3, c1
print("  After c1,c2,c3 = c2,c3,c1:")
print("  c1, c2, c3 =", c1, c2, c3, "(BUG: should be 2,3,1)")

-- Assignment in condition
print("\nIn condition:")
local assigned = 0
if true then
  assigned = 99
end
print("  assigned =", assigned)

-- Assignment with function result
print("\nWith function:")
local function getValue()
  return 777
end
local func_val = getValue()
print("  func_val =", func_val)

print("\n=== Assignment tests complete! ===")
