-- Test table operations comprehensively
print("=== Table Operations ===")

-- Table creation
print("Table creation:")
local t1 = {}
print("  Empty table: type =", type(t1))

local t2 = {1, 2, 3}
print("  Array table: #t2 =", #t2)

local t3 = {x = 10, y = 20}
print("  Dict table: t3.x =", t3.x)

-- Table access
print("\nTable access:")
local arr = {10, 20, 30}
print("  arr[1] =", arr[1])
print("  arr[2] =", arr[2])
print("  arr[3] =", arr[3])

-- Table assignment
print("\nTable assignment:")
local data = {}
data[1] = "first"
data[2] = "second"
print("  data[1], data[2] =", data[1], data[2])

-- Mixed keys
print("\nMixed keys:")
local mixed = {}
mixed[1] = "index 1"
mixed["key"] = "string key"
mixed[10] = "index 10"
print("  mixed[1] =", mixed[1])
print("  mixed['key'] =", mixed["key"])
print("  mixed[10] =", mixed[10])

-- Dot notation vs bracket
print("\nDot vs bracket:")
local obj = {value = 42}
print("  obj.value =", obj.value)
print("  obj['value'] =", obj["value"])

-- Assigning via dot
obj.newField = 99
print("  obj.newField =", obj.newField)

-- Overwriting values
print("\nOverwriting:")
local t = {x = 1}
print("  Initial: t.x =", t.x)
t.x = 2
print("  After t.x = 2: t.x =", t.x)

-- Nil values
print("\nNil values:")
local nilTest = {a = 1, b = 2}
print("  nilTest.a =", nilTest.a)
nilTest.a = nil
print("  After nil: nilTest.a =", nilTest.a)

-- Non-existent keys
print("\nNon-existent keys:")
local empty = {}
print("  empty.missing =", empty.missing)
print("  empty[999] =", empty[999])

-- Nested tables
print("\nNested tables:")
local nested = {
  inner = {
    value = 100
  }
}
print("  nested.inner.value =", nested.inner.value)

-- Table length
print("\nTable length:")
local len1 = {}
print("  #{} =", #len1)

local len2 = {1, 2, 3, 4, 5}
print("  #{1,2,3,4,5} =", #len2)

-- Length with nil holes
print("\nLength with holes:")
local holes = {1, 2, nil, 4}
print("  #{1,2,nil,4} =", #holes)

-- Table as value
print("\nTable as value:")
local container = {}
container.inner = {a = 10}
print("  container.inner.a =", container.inner.a)

-- Multiple levels
print("\nMultiple levels:")
local deep = {
  level1 = {
    level2 = {
      level3 = "deep"
    }
  }
}
print("  deep.level1.level2.level3 =", deep.level1.level2.level3)

-- Array operations
print("\nArray operations:")
local arr2 = {}
for i = 1, 5 do
  arr2[i] = i * 10
end
print("  Built array:", arr2[1], arr2[2], arr2[3], arr2[4], arr2[5])

-- Table in table
print("\nTable in table:")
local collection = {}
collection[1] = {x = 1}
collection[2] = {x = 2}
print("  collection[1].x =", collection[1].x)
print("  collection[2].x =", collection[2].x)

-- Modifying nested
print("\nModifying nested:")
local mod = {inner = {val = 5}}
print("  Before: mod.inner.val =", mod.inner.val)
mod.inner.val = 10
print("  After: mod.inner.val =", mod.inner.val)

-- String keys
print("\nString keys:")
local strings = {}
strings["first"] = 1
strings["second"] = 2
print("  strings['first'] =", strings["first"])
print("  strings['second'] =", strings["second"])

-- Number keys
print("\nNumber keys:")
local numbers = {}
numbers[1] = "one"
numbers[2] = "two"
numbers[100] = "hundred"
print("  numbers[1], numbers[100] =", numbers[1], numbers[100])

-- Boolean keys (may not work)
-- BUG: Boolean keys return nil
print("\nBoolean keys:")
local bools = {}
bools[true] = "yes"
bools[false] = "no"
print("  bools[true] =", bools[true], "(BUG: may be nil)")
print("  bools[false] =", bools[false], "(BUG: may be nil)")

-- Float keys (may not work)
-- BUG: Float keys return nil
print("\nFloat keys:")
local floats = {}
floats[1.5] = "one point five"
floats[2.7] = "two point seven"
print("  floats[1.5] =", floats[1.5], "(BUG: may be nil)")
print("  floats[2.7] =", floats[2.7], "(BUG: may be nil)")

-- Iterating with for
print("\nIterating with for:")
local iter = {10, 20, 30}
for i = 1, #iter do
  print("  iter[" .. i .. "] =", iter[i])
end

-- Table identity
-- BUG: Table equality is broken - table doesn't even equal itself!
print("\nTable identity:")
local t_a = {}
local t_b = {}
print("  t_a == t_b =", t_a == t_b, "(should be false)")
print("  t_a == t_a =", t_a == t_a, "(BUG: should be true!)")

-- Table in expression
print("\nTable in expression:")
local expr = {count = 5}
local result = expr.count * 2
print("  expr.count * 2 =", result)

print("\n=== Table operation tests complete! ===")
