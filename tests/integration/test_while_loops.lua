-- Test while loop variations
print("=== While Loop Variations ===")

-- Basic while loop
print("Basic while:")
local i = 1
while i <= 5 do
  print("  i =", i)
  i = i + 1
end

-- While with complex condition
print("\nComplex condition:")
local x = 1
local y = 10
while x < 5 and y > 5 do
  print("  x =", x, "y =", y)
  x = x + 1
  y = y - 1
end

-- While with break
print("\nWhile with break:")
local count = 1
while true do
  print("  count =", count)
  count = count + 1
  if count > 3 then
    break
  end
end

-- While false (never executes)
print("\nWhile false (should skip):")
while false do
  print("  This should not print")
end
print("  Skipped correctly")

-- Countdown with while
print("\nCountdown:")
local n = 5
while n > 0 do
  print("  n =", n)
  n = n - 1
end

-- While with multiple statements
print("\nMultiple statements:")
local sum = 0
local num = 1
while num <= 4 do
  sum = sum + num
  print("  num =", num, "sum =", sum)
  num = num + 1
end

-- Nested while loops
print("\nNested while:")
local outer = 1
while outer <= 2 do
  print("  Outer:", outer)
  local inner = 1
  while inner <= 3 do
    print("    Inner:", inner)
    inner = inner + 1
  end
  outer = outer + 1
end

-- While with or condition
print("\nOr condition:")
local a = 0
local b = 3
while a < 2 or b > 0 do
  print("  a =", a, "b =", b)
  a = a + 1
  b = b - 1
  if a > 5 then break end
end

print("\n=== All while loop tests passed! ===")
