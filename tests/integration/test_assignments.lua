-- Test assignment patterns and variations
print("=== Assignment Patterns ===")

-- Simple assignment
local x = 10
print("Simple: x =", x)

-- Chained assignment (same value)
local a, b, c = 5, 5, 5
print("Chained: a =", a, "b =", b, "c =", c)

-- Assignment from expressions
local sum = 2 + 3
local product = 4 * 5
print("From expressions: sum =", sum, "product =", product)

-- Assignment from function call
local function get_value()
  return 42
end
local val = get_value()
print("From function: val =", val)

-- Assignment with nil
local n = nil
print("With nil: n =", n)

-- Re-assignment
local var = 10
print("\nRe-assignment:")
print("  Initial: var =", var)
var = 20
print("  After: var =", var)

-- Global assignment
global1 = 100
print("\nGlobal: global1 =", global1)

-- Assignment to table fields
local t = {}
t.x = 10
t.y = 20
print("\nTable fields: t.x =", t.x, "t.y =", t.y)

-- Assignment to table indices
local arr = {}
arr[1] = "first"
arr[2] = "second"
print("Table indices: arr[1] =", arr[1], "arr[2] =", arr[2])

-- Assignment with operators (compound assignment doesn't exist in Lua)
local count = 5
count = count + 1
print("\nIncrement: count =", count)

local total = 10
total = total * 2
print("Double: total =", total)

-- Assignment in conditions
local cond = true
if cond then
  local inside = 99
  print("\nInside if: inside =", inside)
end

-- Multiple assignment with expressions
local x1, y1 = 1 + 1, 2 * 2
print("\nWith expressions: x1 =", x1, "y1 =", y1)

print("\n=== All assignment pattern tests passed! ===")
