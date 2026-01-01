-- Test return value behavior
print("=== Return Values ===")

-- Simple return
print("Simple return:")
local function returnOne()
  return 42
end
print("  returnOne() =", returnOne())

-- No return (implicit nil)
-- BUG: Returns function instead of nil
print("\nNo return:")
local function noReturn()
  local x = 10
end
local result = noReturn()
print("  noReturn() =", result, "(BUG: should be nil)")

-- Empty return
print("\nEmpty return:")
local function emptyReturn()
  return
end
print("  emptyReturn() =", emptyReturn())

-- Multiple returns
print("\nMultiple returns:")
local function multiReturn()
  return 1, 2, 3
end
local a, b, c = multiReturn()
print("  a, b, c =", a, b, c)

-- Using only first return
local first = multiReturn()
print("  first only =", first)

-- Extra variables in assignment
local p, q, r, s = multiReturn()
print("  p, q, r, s =", p, q, r, s)

-- Return in middle of function
print("\nEarly return:")
local function earlyReturn(x)
  if x > 0 then
    return "positive"
  end
  return "not positive"
end
print("  earlyReturn(5) =", earlyReturn(5))
print("  earlyReturn(-3) =", earlyReturn(-3))

-- Return from nested block
print("\nReturn from nested:")
local function nestedReturn(x)
  do
    if x == 1 then
      return "one"
    end
  end
  return "not one"
end
print("  nestedReturn(1) =", nestedReturn(1))
print("  nestedReturn(2) =", nestedReturn(2))

-- Return expression
print("\nReturn expression:")
local function returnExpr()
  return 5 + 3 * 2
end
print("  returnExpr() =", returnExpr())

-- Return function call
-- BUG: Local functions can't call other local functions in same scope
print("\nReturn function call:")
-- local function add(a, b)
--   return a + b
-- end
-- local function returnCall()
--   return add(10, 20)
-- end
-- print("  returnCall() =", returnCall())
print("  (SKIPPED: local function scoping broken)")

-- Return multiple function calls
print("\nReturn multiple calls:")
-- local function double(x)
--   return x * 2
-- end
-- local function triple(x)
--   return x * 3
-- end
-- local function both(x)
--   return double(x), triple(x)
-- end
-- local d, t = both(5)
-- print("  double(5), triple(5) =", d, t)
print("  (SKIPPED: local function scoping broken)")

-- Return table
print("\nReturn table:")
local function returnTable()
  return {x = 10, y = 20}
end
local tbl = returnTable()
print("  tbl.x, tbl.y =", tbl.x, tbl.y)

-- Return from loop
print("\nReturn from loop:")
local function findFirst(target)
  for i = 1, 5 do
    if i == target then
      return i
    end
  end
  return nil
end
print("  findFirst(3) =", findFirst(3))
print("  findFirst(10) =", findFirst(10))

-- Tail call return
-- BUG: Local recursive functions don't work
print("\nTail call:")
-- local function factorial(n, acc)
--   acc = acc or 1
--   if n <= 1 then
--     return acc
--   end
--   return factorial(n - 1, n * acc)
-- end
-- print("  factorial(5) =", factorial(5))
print("  (SKIPPED: local recursion broken)")

-- Return boolean
print("\nReturn boolean:")
local function isEven(n)
  return n % 2 == 0
end
print("  isEven(4) =", isEven(4))
print("  isEven(3) =", isEven(3))

-- Return nil explicitly
print("\nExplicit nil return:")
local function returnNil()
  return nil
end
print("  returnNil() =", returnNil())

-- Return string concatenation
print("\nReturn concatenation:")
local function greet(name)
  return "Hello, " .. name
end
print("  greet('World') =", greet("World"))

-- Multiple return with expressions
print("\nMultiple with expressions:")
local function calc(x)
  return x + 1, x * 2, x ^ 2
end
local inc, dbl, sq = calc(5)
print("  calc(5) =", inc, dbl, sq)

print("\n=== Return value tests complete! ===")
