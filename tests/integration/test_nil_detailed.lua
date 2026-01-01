-- Test nil value behavior
print("=== Nil Values ===")

-- Nil literal
print("Nil literal:")
print("  nil =", nil)

-- Nil type
print("\nNil type:")
print("  type(nil) =", type(nil))

-- Nil equality
print("\nEquality:")
print("  nil == nil =", nil == nil)
print("  nil == false =", nil == false)
print("  nil == 0 =", nil == 0)
print("  nil == '' =", nil == "")

-- Nil inequality
print("\nInequality:")
print("  nil ~= nil =", nil ~= nil)
print("  nil ~= false =", nil ~= false)

-- Nil in conditionals
print("\nIn conditionals:")
if nil then
  print("  ERROR: nil is truthy")
else
  print("  nil is falsy ✓")
end

-- Not nil
print("\nLogical NOT:")
print("  not nil =", not nil)
print("  not not nil =", not not nil)

-- Nil and/or
print("\nWith and/or:")
print("  nil and true =", nil and true)
print("  nil or true =", nil or true)
print("  true and nil =", true and nil)
print("  true or nil =", true or nil)

-- Nil in expressions
print("\nIn expressions:")
print("  nil or 42 =", nil or 42)
print("  nil and 42 =", nil and 42)

-- Variable with nil
print("\nVariable with nil:")
local x = nil
print("  local x = nil; x =", x)

-- Uninitialized variable
-- Note: In Lua, uninitialized variables are nil, but we can't test truly uninitialized
print("\nImplicit nil:")
local uninit
print("  local uninit; uninit =", uninit)

-- Nil assignment
print("\nNil assignment:")
local val = 42
print("  Before: val =", val)
val = nil
print("  After val = nil: val =", val)

-- Nil in table
print("\nIn table:")
local t = {nil, 2, nil, 4}
print("  {nil, 2, nil, 4}:")
print("  t[1], t[2], t[3], t[4] =", t[1], t[2], t[3], t[4])

-- Nil table field
print("\nTable field:")
local obj = {a = 1, b = nil}
print("  obj.a =", obj.a)
print("  obj.b =", obj.b)
print("  obj.missing =", obj.missing)

-- Setting to nil
print("\nSetting to nil:")
local data = {x = 10, y = 20}
print("  Before: data.x =", data.x)
data.x = nil
print("  After data.x = nil: data.x =", data.x)

-- Nil in multiple assignment
print("\nMultiple assignment:")
local a, b, c = 1, nil, 3
print("  a, b, c = 1, nil, 3")
print("  a, b, c =", a, b, c)

-- Too few values (implicit nil)
local p, q, r = 1
print("  p, q, r = 1")
print("  p, q, r =", p, q, r)

-- Nil from function
print("\nFrom function:")
local function returnsNil()
  return nil
end
print("  returnsNil() =", returnsNil())

-- Implicit return (should be nil but may be bug)
local function noReturn()
end
print("  noReturn() =", noReturn(), "(BUG: may not be nil)")

-- Nil in function args
print("\nFunction args:")
local function takeArgs(a, b, c)
  print("  Args:", a, b, c)
end
takeArgs(1, nil, 3)
takeArgs(1)

-- Nil concatenation
print("\nNil concatenation:")
-- Can't concatenate nil
-- print("  'x' .. nil =", "x" .. nil)  -- Would error
print("  (nil can't be concatenated)")

-- Nil arithmetic
print("\nNil arithmetic:")
-- Can't do arithmetic with nil
-- print("  nil + 1 =", nil + 1)  -- Would error
print("  (nil can't be used in arithmetic)")

-- Nil conversion
print("\nConversion:")
print("  tostring(nil) =", tostring(nil))
print("  tonumber(nil) =", tonumber(nil))

-- Nil length
print("\nLength of nil:")
-- Can't get length of nil
-- print("  #nil =", #nil)  -- Would error
print("  (#nil would error)")

-- Nil comparison
print("\nComparison:")
-- Can't compare nil with <, >, etc
-- print("  nil < 1 =", nil < 1)  -- Would error
print("  (nil can't be ordered with < or >)")

-- Checking for nil
print("\nChecking for nil:")
local check = nil
if check == nil then
  print("  check is nil ✓")
end

if type(check) == "nil" then
  print("  type(check) == 'nil' ✓")
end

-- Nil vs undefined
print("\nNil vs undefined:")
local defined = nil
-- local undefined is not declared
print("  defined =", defined)
-- print("  undefined =", undefined)  -- Would error
print("  (undefined variable would error)")

-- Nil in loop
print("\nIn loop:")
for i = 1, 3 do
  local inner = nil
  print("  inner =", inner)
end

-- Nil table length
print("\nTable with nil:")
local nilTable = {1, 2, nil, 4}
print("  #{1, 2, nil, 4} =", #nilTable)

-- Nil at end
local nilEnd = {1, 2, 3}
nilEnd[3] = nil
print("  After t[3] = nil: #t =", #nilEnd, "(BUG: may be wrong)")

-- Multiple nils
print("\nMultiple nil values:")
local m1, m2, m3 = nil, nil, nil
print("  m1, m2, m3 =", m1, m2, m3)

print("\n=== Nil tests complete! ===")
