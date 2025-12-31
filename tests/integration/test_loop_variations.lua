-- Test different loop patterns
print("=== Loop Variations ===")

-- Numeric for with step
print("Count by 2s:")
for i = 0, 10, 2 do
  print(i)
end

print("\nCount backwards:")
for i = 5, 1, -1 do
  print(i)
end

print("\nNegative range:")
for i = -3, 3 do
  print(i)
end

-- While loop with multiple conditions
print("\nWhile with complex condition:")
local x = 1
local y = 10
while x < 5 and y > 5 do
  print("x =", x, "y =", y)
  x = x + 1
  y = y - 1
end

-- Nested loops
print("\nNested loops (multiplication table):")
for i = 1, 3 do
  for j = 1, 3 do
    print(i .. " * " .. j .. " =", i * j)
  end
end

-- Break in different positions
print("\nBreak in loop:")
for i = 1, 10 do
  if i == 5 then
    print("Breaking at", i)
    break
  end
  print(i)
end

print("\n=== All loop tests passed! ===")
