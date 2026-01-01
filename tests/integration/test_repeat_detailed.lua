-- Test repeat-until loops comprehensively
print("=== Repeat-Until Loops ===")

-- Simple repeat
print("Simple repeat:")
local i = 1
repeat
  print("  i =", i)
  i = i + 1
until i > 3

-- Repeat with single iteration
print("\nSingle iteration:")
local once = 5
repeat
  print("  once =", once)
  once = 10
until once >= 10

-- Repeat with complex condition
print("\nComplex condition:")
local a = 1
local b = 10
repeat
  print("  a, b =", a, b)
  a = a + 1
  b = b - 1
until a >= 3 or b <= 7

-- Nested repeat
print("\nNested repeat:")
local outer = 1
repeat
  local inner = 1
  repeat
    print("  outer, inner =", outer, inner)
    inner = inner + 1
  until inner > 2
  outer = outer + 1
until outer > 2

-- Repeat with local variables
print("\nWith locals:")
local count = 1
repeat
  local temp = count * 5
  print("  count, temp =", count, temp)
  count = count + 1
until count > 3

-- Repeat with break
print("\nWith break:")
local n = 1
repeat
  print("  n =", n)
  if n == 3 then
    break
  end
  n = n + 1
until n > 10

-- Repeat always executes once
print("\nAlways executes once:")
local never = 1
repeat
  print("  Executed despite condition being true")
  never = 2
until never > 1

-- Repeat with table
print("\nWith table:")
local t = {10, 20, 30}
local idx = 1
repeat
  print("  t[" .. idx .. "] =", t[idx])
  idx = idx + 1
until idx > #t

-- Repeat with function call
print("\nWith function call:")
local function check(x)
  return x >= 3
end
local k = 1
repeat
  print("  k =", k)
  k = k + 1
until check(k)

-- Repeat with do block
print("\nWith do block:")
local m = 1
repeat
  do
    local inner = m * 10
    print("  m, inner =", m, inner)
  end
  m = m + 1
until m > 2

-- Repeat with if
print("\nWith if:")
local p = 1
repeat
  if p % 2 == 0 then
    print("  p =", p, "(even)")
  else
    print("  p =", p, "(odd)")
  end
  p = p + 1
until p > 4

-- Repeat modifying table
print("\nModifying table:")
local arr = {}
local j = 1
repeat
  arr[j] = j * j
  j = j + 1
until j > 3
print("  arr:", arr[1], arr[2], arr[3])

-- Repeat with multiple conditions
print("\nMultiple conditions:")
local x = 1
local y = 5
repeat
  print("  x, y =", x, y)
  x = x + 1
  y = y - 1
until x > 3 and y < 3

-- Repeat with not
print("\nWith not:")
local done = false
local loop = 0
repeat
  loop = loop + 1
  print("  loop =", loop)
  if loop >= 2 then
    done = true
  end
until done

-- Repeat countdown
print("\nCountdown:")
local countdown = 3
repeat
  print("  countdown =", countdown)
  countdown = countdown - 1
until countdown <= 0

-- Repeat with expression
print("\nWith expression:")
local val = 2
repeat
  print("  val * 2 =", val * 2)
  val = val + 1
until val > 3

-- Repeat with logical operators
print("\nLogical operators:")
local r = 0
local s = 10
repeat
  print("  r, s =", r, s)
  r = r + 1
  s = s - 1
until r > 2 or s < 8

-- Empty repeat (just condition)
print("\nMinimal repeat:")
local min = 0
repeat
  min = min + 1
until min >= 2
print("  After repeat: min =", min)

-- Repeat with string concatenation
print("\nWith concat:")
local str = ""
local num = 1
repeat
  str = str .. num
  num = num + 1
until num > 3
print("  Concatenated:", str)

-- Scope in repeat
-- Note: In Lua, variables declared in repeat body are visible in until condition
print("\nScope in repeat:")
local scope = 0
repeat
  scope = scope + 1
  local visible = scope * 10
  print("  scope, visible =", scope, visible)
until scope >= 2

print("\n=== Repeat-until tests complete! ===")
