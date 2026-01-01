-- Test break and control flow statements
print("=== Break and Control Flow ===")

-- Break in for loop
print("Break in for:")
for i = 1, 10 do
  if i == 4 then
    break
  end
  print("  i =", i)
end
print("  (broke at 4)")

-- Break in while loop
print("\nBreak in while:")
local n = 1
while true do
  print("  n =", n)
  if n >= 3 then
    break
  end
  n = n + 1
end

-- Break in repeat
print("\nBreak in repeat:")
local r = 1
repeat
  print("  r =", r)
  if r == 3 then
    break
  end
  r = r + 1
until r > 10

-- Break in nested loop (breaks inner)
print("\nBreak in nested:")
for i = 1, 3 do
  for j = 1, 5 do
    if j == 3 then
      break
    end
    print("  i, j =", i, j)
  end
end

-- Break with condition
print("\nBreak with condition:")
for i = 1, 10 do
  if i % 2 == 0 and i > 5 then
    print("  Breaking at", i)
    break
  end
  print("  i =", i)
end

-- Break in do block inside loop
print("\nBreak in do block:")
for i = 1, 10 do
  do
    if i == 3 then
      break
    end
    print("  i =", i)
  end
end

-- Early return
print("\nEarly return:")
local function earlyExit(x)
  if x < 0 then
    return "negative"
  end
  if x == 0 then
    return "zero"
  end
  return "positive"
end
print("  earlyExit(-5) =", earlyExit(-5))
print("  earlyExit(0) =", earlyExit(0))
print("  earlyExit(5) =", earlyExit(5))

-- Return in loop
print("\nReturn in loop:")
local function findValue(target)
  for i = 1, 10 do
    if i == target then
      return i
    end
  end
  return nil
end
print("  findValue(5) =", findValue(5))
print("  findValue(20) =", findValue(20))

-- Multiple returns with early exit
print("\nMultiple returns:")
local function analyze(x)
  if x < 0 then
    return "negative", -x
  end
  return "non-negative", x
end
local desc1, val1 = analyze(-5)
print("  analyze(-5):", desc1, val1)
local desc2, val2 = analyze(5)
print("  analyze(5):", desc2, val2)

-- Return from nested block
print("\nReturn from nested:")
local function nested(x)
  if x > 0 then
    do
      if x > 10 then
        return "large"
      end
      return "small positive"
    end
  end
  return "non-positive"
end
print("  nested(15) =", nested(15))
print("  nested(5) =", nested(5))
print("  nested(-1) =", nested(-1))

-- Break with table
print("\nBreak with table:")
local arr = {10, 20, 30, 40, 50}
for i = 1, #arr do
  if arr[i] == 30 then
    print("  Found 30 at index", i)
    break
  end
  print("  arr[" .. i .. "] =", arr[i])
end

-- Search pattern
print("\nSearch pattern:")
local function search(arr, target)
  for i = 1, #arr do
    if arr[i] == target then
      return i
    end
  end
  return nil
end
local data = {5, 10, 15, 20, 25}
print("  search for 15:", search(data, 15))
print("  search for 99:", search(data, 99))

-- Break in complex condition
print("\nComplex break condition:")
for i = 1, 20 do
  if i % 3 == 0 and i % 5 == 0 then
    print("  Breaking at", i, "(divisible by 15)")
    break
  end
  if i % 2 == 0 then
    print("  i =", i, "(even)")
  end
end

-- Conditional execution
print("\nConditional execution:")
for i = 1, 10 do
  if i > 7 then
    break
  end
  if i % 2 == 1 then
    print("  Odd:", i)
  end
end

-- Return with no value
print("\nReturn no value:")
local function maybeReturn(x)
  if x < 0 then
    return
  end
  print("  Positive:", x)
end
maybeReturn(-5)
maybeReturn(5)

-- Guard clauses
print("\nGuard clauses:")
local function process(x)
  if x == nil then
    return "nil input"
  end
  if x < 0 then
    return "negative"
  end
  if x == 0 then
    return "zero"
  end
  return "positive"
end
print("  process(nil):", process(nil))
print("  process(-1):", process(-1))
print("  process(0):", process(0))
print("  process(1):", process(1))

-- Break in while with counter
print("\nWhile with break counter:")
local count = 0
while count < 100 do
  count = count + 1
  if count == 5 then
    print("  Breaking at count =", count)
    break
  end
  print("  count =", count)
end

-- Exit loop early based on accumulator
print("\nAccumulator break:")
local sum = 0
for i = 1, 100 do
  sum = sum + i
  if sum > 20 then
    print("  sum exceeded 20 at i =", i)
    break
  end
end
print("  final sum =", sum)

-- Return from different paths
print("\nReturn paths:")
local function multiPath(x, y)
  if x > y then
    return "x larger"
  elseif y > x then
    return "y larger"
  else
    return "equal"
  end
end
print("  multiPath(5, 3):", multiPath(5, 3))
print("  multiPath(3, 5):", multiPath(3, 5))
print("  multiPath(5, 5):", multiPath(5, 5))

print("\n=== Control flow tests complete! ===")
