-- Test mixed data type interactions
print("=== Mixed Data Types ===")

-- Number and string
print("Number and string:")
local num = 42
local str = "hello"
print("  num + num =", num + num)
print("  str .. str =", str .. str)
print("  str .. num =", str .. num)
-- print("  num + str =", num + str)  -- Would error
print("  (num + str would error)")

-- Number and boolean
print("\nNumber and boolean:")
print("  1 and true =", 1 and true)
print("  0 and true =", 0 and true)
print("  1 or false =", 1 or false)
-- print("  1 + true =", 1 + true)  -- Would error
print("  (1 + true would error)")

-- Number and nil
print("\nNumber and nil:")
print("  5 and nil =", 5 and nil)
print("  nil and 5 =", nil and 5)
print("  5 or nil =", 5 or nil)
print("  nil or 5 =", nil or 5)
print("  5 == nil =", 5 == nil)

-- String and boolean
print("\nString and boolean:")
print("  'hello' and true =", "hello" and true)
print("  'hello' or false =", "hello" or false)
-- print("  'hello' .. true =", "hello" .. true)  -- May error
print("  (string .. boolean may error)")

-- Table and number
print("\nTable and number:")
local t = {1, 2, 3}
print("  #{1,2,3} =", #t)
print("  t[1] + 10 =", t[1] + 10)

-- Mixed in table
print("\nMixed table:")
local mixed = {1, "two", true, nil, 5}
print("  mixed[1] (number) =", mixed[1])
print("  mixed[2] (string) =", mixed[2])
print("  mixed[3] (boolean) =", mixed[3])
print("  mixed[4] (nil) =", mixed[4])
print("  mixed[5] (number) =", mixed[5])

-- Type checking mixed
print("\nType checking:")
local values = {42, "hello", true, nil, {}, function() end}
for i = 1, 6 do
  local v = values[i]
  print("  type(values[" .. i .. "]) =", type(v))
end

-- Comparison across types
print("\nCross-type comparison:")
print("  1 == '1' =", 1 == "1")
print("  true == 1 =", true == 1)
print("  nil == false =", nil == false)
print("  {} == {} =", {} == {})

-- Mixed return values
print("\nMixed returns:")
function mixedReturn()
  return 1, "two", true
end
local a, b, c = mixedReturn()
print("  a, b, c =", a, b, c)
print("  types:", type(a), type(b), type(c))

-- Truthiness of different types
print("\nTruthiness (broken):")
if 0 then
  print("  0 is truthy")
else
  print("  0 is falsy (BUG)")
end

if "" then
  print("  '' is truthy")
else
  print("  '' is falsy (BUG)")
end

if {} then
  print("  {} is truthy")
else
  print("  {} is falsy (BUG)")
end

-- Function as value
print("\nFunction as value:")
local func = function() return 42 end
print("  type(func) =", type(func))
print("  func() =", func())

print("\n=== Mixed type tests complete! ===")
