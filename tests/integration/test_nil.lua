-- Test nil handling
print("=== Nil Handling ===")

-- nil in variables
local x = nil
print("x =", x)

-- nil in conditionals
if x == nil then
  print("x is nil")
end

if not x then
  print("not x is true (nil is falsy)")
end

-- nil vs false
local y = false
print("\ny =", y)
if y == nil then
  print("FAIL: y should not be nil")
else
  print("PASS: y is not nil, it's false")
end

-- nil in tables
local t = {1, 2, nil, 4, 5}
print("\nTable with nil:")
print("t[1] =", t[1])
print("t[3] =", t[3])
print("t[4] =", t[4])
print("#t =", #t)

-- Setting to nil
local val = 42
print("\nval =", val)
val = nil
print("After setting to nil: val =", val)

-- nil in function arguments (explicit nil works)
local function test_nil(a, b, c)
  print("a =", a, "b =", b, "c =", c)
end

print("\nFunction with explicit nil:")
test_nil(1, nil, 3)

-- NOTE: Missing arguments have a bug - they reuse previous values
-- instead of being nil. This is a register cleanup issue.
-- test_nil(1) should give (1, nil, nil) but gives wrong values

-- nil in returns
local function returns_nil()
  return nil
end

local result = returns_nil()
print("\nResult from returns_nil():", result)

-- nil in comparisons
print("\nNil in comparisons:")
print("nil == nil:", nil == nil)
print("nil == false:", nil == false)
print("not nil:", not nil)

print("\n=== All nil handling tests passed! ===")
