-- Test loop control flow
print("=== Loop Control Flow ===")

-- Break in for loop
print("Break in for loop:")
for i = 1, 10 do
  if i == 5 then
    break
  end
  print("  i =", i)
end

-- Break in while loop
print("\nBreak in while loop:")
local count = 0
while true do
  count = count + 1
  if count > 3 then
    break
  end
  print("  count =", count)
end

-- Break in repeat-until
print("\nBreak in repeat-until:")
local n = 0
repeat
  n = n + 1
  if n == 3 then
    break
  end
  print("  n =", n)
until n >= 10

-- Nested loops with break
print("\nNested loops with break:")
for i = 1, 3 do
  print("  Outer i =", i)
  for j = 1, 5 do
    if j == 3 then
      break
    end
    print("    Inner j =", j)
  end
end

-- Break with condition
print("\nBreak with complex condition:")
for i = 1, 20 do
  if i % 2 == 0 and i > 6 then
    print("  Breaking at", i)
    break
  end
  if i % 2 == 0 then
    print("  Even:", i)
  end
end

-- While with break and continue-like pattern
print("\nWhile with skip pattern:")
local x = 0
while x < 10 do
  x = x + 1
  if x % 2 == 1 then
    -- Skip odd numbers (continue-like)
  else
    print("  Even x:", x)
  end
end

print("\n=== All loop control flow tests passed! ===")
