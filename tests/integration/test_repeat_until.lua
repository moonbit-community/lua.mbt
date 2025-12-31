-- Test repeat-until loops
print("=== Repeat-Until Loops ===")

-- Basic repeat-until
local count = 0
repeat
  count = count + 1
  print("count =", count)
until count >= 3

print("Final count:", count)

-- Repeat-until always executes at least once
print("\nAlways executes once:")
local x = 10
repeat
  print("x =", x)
  x = x + 1
until x > 5  -- Condition already true, but body runs once

-- Repeat-until with complex condition
print("\nComplex condition:")
local a = 1
local b = 10
repeat
  print("a =", a, "b =", b)
  a = a + 1
  b = b - 1
until a >= 5 or b <= 5

-- Nested repeat-until
print("\nNested repeat-until:")
local i = 1
repeat
  print("Outer:", i)
  local j = 1
  repeat
    print("  Inner:", j)
    j = j + 1
  until j > 2
  i = i + 1
until i > 2

print("\n=== All repeat-until tests passed! ===")
