-- Test while loops comprehensively
print("=== While Loops ===")

-- Simple while
print("Simple while:")
local i = 1
while i <= 3 do
  print("  i =", i)
  i = i + 1
end

-- While with break
print("\nWhile with break:")
local n = 1
while true do
  print("  n =", n)
  if n >= 3 then
    break
  end
  n = n + 1
end

-- While false (never executes)
print("\nWhile false:")
while false do
  print("  ERROR: should not execute")
end
print("  (while false body skipped)")

-- While with complex condition
print("\nComplex condition:")
local a = 1
local b = 10
while a < 5 and b > 5 do
  print("  a, b =", a, b)
  a = a + 1
  b = b - 1
end

-- Nested while
print("\nNested while:")
local outer = 1
while outer <= 2 do
  local inner = 1
  while inner <= 2 do
    print("  outer, inner =", outer, inner)
    inner = inner + 1
  end
  outer = outer + 1
end

-- While with local variables
print("\nWhile with locals:")
local count = 1
while count <= 3 do
  local temp = count * 10
  print("  count, temp =", count, temp)
  count = count + 1
end

-- While modifying condition variable
print("\nModifying in loop:")
local val = 0
while val < 5 do
  val = val + 1
  print("  val =", val)
end

-- While with countdown
print("\nCountdown:")
local countdown = 3
while countdown > 0 do
  print("  countdown =", countdown)
  countdown = countdown - 1
end

-- While with multiple statements
print("\nMultiple statements:")
local j = 1
while j <= 2 do
  local x = j * 2
  local y = j * 3
  print("  j, x, y =", j, x, y)
  j = j + 1
end

-- While with function call
print("\nWith function call:")
local function shouldContinue(x)
  return x < 3
end
local k = 1
while shouldContinue(k) do
  print("  k =", k)
  k = k + 1
end

-- While with table
print("\nWith table:")
local t = {1, 2, 3}
local idx = 1
while idx <= #t do
  print("  t[" .. idx .. "] =", t[idx])
  idx = idx + 1
end

-- Empty while body
print("\nEmpty while:")
local empty = 0
while empty < 2 do
  empty = empty + 1
end
print("  After empty while: empty =", empty)

-- While with do block
print("\nWhile with do:")
local m = 1
while m <= 2 do
  do
    local inner = m * 5
    print("  m, inner =", m, inner)
  end
  m = m + 1
end

-- While with if
print("\nWhile with if:")
local p = 1
while p <= 5 do
  if p % 2 == 0 then
    print("  p =", p, "(even)")
  end
  p = p + 1
end

-- While with truthiness
-- BUG: Only true is truthy
print("\nTruthiness in while:")
-- local truthy = 1
-- while truthy do  -- Should loop forever since 1 is truthy
--   print("  BUG: 1 should be truthy")
--   break
-- end
print("  (BUG: can't use 1 as truthy in while condition)")

-- While with logical operators
print("\nLogical operators:")
local x = 1
local y = 5
while x < 3 and y > 3 do
  print("  x, y =", x, y)
  x = x + 1
  y = y - 1
end

-- While with or
print("\nWith or condition:")
local r = 0
local s = 10
while r < 2 or s > 8 do
  print("  r, s =", r, s)
  r = r + 1
  s = s - 1
end

-- While with not
print("\nWith not:")
local done = false
local loop = 0
while not done do
  loop = loop + 1
  print("  loop =", loop)
  if loop >= 2 then
    done = true
  end
end

print("\n=== While loop tests complete! ===")
