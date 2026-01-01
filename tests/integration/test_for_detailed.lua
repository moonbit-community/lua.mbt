-- Test numeric for loops in detail
print("=== Numeric For Loops ===")

-- Simple for
print("Simple for:")
for i = 1, 3 do
  print("  i =", i)
end

-- For with step
print("\nWith step 2:")
for i = 1, 6, 2 do
  print("  i =", i)
end

-- For countdown
print("\nCountdown:")
for i = 3, 1, -1 do
  print("  i =", i)
end

-- For with 0 start
print("\nFrom 0:")
for i = 0, 2 do
  print("  i =", i)
end

-- For with negative numbers
print("\nNegative range:")
for i = -2, 0 do
  print("  i =", i)
end

-- For with large step
print("\nLarge step:")
for i = 0, 10, 5 do
  print("  i =", i)
end

-- For with single iteration
print("\nSingle iteration:")
for i = 5, 5 do
  print("  i =", i)
end

-- For that doesn't execute
print("\nNo iterations:")
for i = 5, 1 do
  print("  ERROR: should not execute")
end
print("  (loop skipped)")

-- Nested for loops
print("\nNested for:")
for i = 1, 2 do
  for j = 1, 2 do
    print("  i, j =", i, j)
  end
end

-- For with local variables
print("\nWith locals:")
for i = 1, 2 do
  local x = i * 10
  print("  i, x =", i, x)
end

-- For with break
print("\nWith break:")
for i = 1, 10 do
  if i == 3 then
    break
  end
  print("  i =", i)
end

-- For with if
print("\nWith if:")
for i = 1, 5 do
  if i % 2 == 0 then
    print("  i =", i, "(even)")
  end
end

-- For with table access
print("\nWith table:")
local t = {10, 20, 30}
for i = 1, #t do
  print("  t[" .. i .. "] =", t[i])
end

-- For with function call in body
print("\nWith function call:")
local function double(x)
  return x * 2
end
for i = 1, 3 do
  print("  double(" .. i .. ") =", double(i))
end

-- For with expression limits
print("\nExpression limits:")
local start = 1
local stop = 3
for i = start, stop do
  print("  i =", i)
end

-- For with computed step
print("\nComputed step:")
local step = 2
for i = 0, 4, step do
  print("  i =", i)
end

-- For modifying table
print("\nModifying table:")
local arr = {}
for i = 1, 3 do
  arr[i] = i * i
end
print("  arr:", arr[1], arr[2], arr[3])

-- For with multiple locals
print("\nMultiple locals:")
for i = 1, 2 do
  local a = i
  local b = i * 2
  local c = i * 3
  print("  a, b, c =", a, b, c)
end

-- For with string concatenation
print("\nWith concat:")
for i = 1, 3 do
  local msg = "Iteration " .. i
  print("  " .. msg)
end

-- Deep nesting
print("\nDeeply nested:")
for i = 1, 2 do
  for j = 1, 2 do
    for k = 1, 2 do
      print("  i, j, k =", i, j, k)
    end
  end
end

-- For with do block
print("\nWith do block:")
for i = 1, 2 do
  do
    local inner = i + 10
    print("  i, inner =", i, inner)
  end
end

-- For with fractions (limits)
print("\nFractional limits:")
for i = 1.5, 3.5 do
  print("  i =", i)
end

-- For with expressions
print("\nExpression in body:")
for i = 1, 3 do
  print("  i * i =", i * i)
end

-- Zero step should never execute (infinite loop)
-- Can't test: for i = 1, 10, 0 do end  -- Would hang

print("\n=== For loop tests complete! ===")
