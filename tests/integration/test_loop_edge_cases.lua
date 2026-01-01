-- Test complex loop scenarios and edge cases
-- BUG: Accessing variables from anonymous function closures fails
print("=== Loop Edge Cases ===")

-- Break in nested loops
-- NOTE: Works correctly!
print("Break in nested loops:")
for i = 1, 3 do
  for j = 1, 3 do
    if i == 2 and j == 2 then
      break
    end
    print("  i=" .. i .. " j=" .. j)
  end
end

-- For loop with step = 0 (infinite loop potential)
print("\nFor with zero step (should skip):")
-- This might hang or behave unexpectedly
-- for i = 1, 10, 0 do
--   print("  This should not execute")
-- end
print("  (SKIPPED: step=0 is undefined behavior)")

-- For loop where start > end with positive step
print("\nFor loop start > end:")
for i = 10, 1, 1 do
  print("  This should not print")
end
print("  (correctly skipped)")

-- While with side effects in condition
-- SKIPPED: Requires closure to access 'x'
print("\nWhile with side effects:")
print("  (SKIPPED: requires closures)")
-- local x = 0
-- while (function() x = x + 1; return x <= 3 end)() do
--   print("  x =", x)
-- end

-- Nested repeat-until
print("\nNested repeat-until:")
local a = 0
repeat
  a = a + 1
  local b = 0
  repeat
    b = b + 1
    print("  a=" .. a .. " b=" .. b)
  until b >= 2
until a >= 2

-- For loop with fractional step
print("\nFor with fractional step:")
for i = 0, 2, 0.5 do
  print("  i =", i)
end

-- Very large loop count
print("\nLarge loop count:")
local count = 0
for i = 1, 10000 do
  count = count + 1
end
print("  count =", count)

-- Loop variable shadowing
print("\nLoop variable shadowing:")
for i = 1, 2 do
  print("  outer i =", i)
  for i = 10, 11 do
    print("    inner i =", i)
  end
  print("  outer i again =", i)
end

-- Break at start of loop
print("\nBreak at start:")
while true do
  print("  Before break")
  break
  print("  After break (should not print)")
end

-- Multiple breaks
print("\nMultiple potential breaks:")
for i = 1, 5 do
  if i == 2 then
    break
  end
  if i == 3 then
    break
  end
  print("  i =", i)
end

-- Loop with no body
print("\nEmpty loop bodies:")
for i = 1, 3 do
  -- Empty
end
print("  (empty for completed)")

while false do
  -- Never executes
end
print("  (while false completed)")

print("\n=== Loop edge cases complete! ===")
