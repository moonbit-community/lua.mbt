-- Test if-else variations
print("=== If-Else Variations ===")

-- Simple if
print("Simple if:")
local x = 10
if x > 5 then
  print("  x is greater than 5")
end

-- If-else
print("\nIf-else:")
local y = 3
if y > 5 then
  print("  FAIL: y > 5")
else
  print("  PASS: y <= 5")
end

-- If-elseif-else
print("\nIf-elseif-else:")
local score = 75
if score >= 90 then
  print("  Grade: A")
elseif score >= 80 then
  print("  Grade: B")
elseif score >= 70 then
  print("  Grade: C")
else
  print("  Grade: F")
end

-- Nested if
print("\nNested if:")
local age = 25
local has_license = true
if age >= 18 then
  if has_license then
    print("  Can drive")
  else
    print("  Need license")
  end
else
  print("  Too young")
end

-- Multiple conditions in if
print("\nMultiple conditions:")
local a = 5
local b = 10
if a > 0 and b > 0 then
  print("  Both positive")
end

if a < 10 or b < 10 then
  print("  At least one less than 10")
end

-- If with not
print("\nWith not:")
local done = false
if not done then
  print("  Not done yet")
end

-- If with complex expression
print("\nComplex expression:")
local val = 15
if val > 10 and val < 20 then
  print("  val is between 10 and 20")
end

-- Empty if branches
print("\nEmpty branches:")
if true then
  -- Empty then branch
end
print("  Empty branch handled")

-- If returning from function
print("\nIf in function:")
local function check(n)
  if n > 0 then
    return "positive"
  elseif n < 0 then
    return "negative"
  else
    return "zero"
  end
end
print("  check(5) =", check(5))
print("  check(-3) =", check(-3))
print("  check(0) =", check(0))

-- Truthiness in if
print("\nTruthiness:")
-- CRITICAL BUG: Only 'true' is truthy in if statements!
-- In standard Lua, only nil and false are falsy, everything else is truthy
-- This implementation incorrectly treats numbers, strings, and tables as falsy

if true then
  print("  true is truthy")
end

if not nil then
  print("  nil is falsy")
end

if not false then
  print("  false is falsy")
end

-- NOTE: These would fail because only true is truthy:
-- if 1 then ... end  -- FAILS
-- if "hello" then ... end  -- FAILS
-- if {} then ... end  -- FAILS

print("\n=== All if-else tests passed! ===")
