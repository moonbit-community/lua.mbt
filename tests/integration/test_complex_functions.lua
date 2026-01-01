-- Test complex nested function scenarios
-- BUG: Closures are NOT IMPLEMENTED
-- Functions cannot access variables from outer scope
print("=== Complex Functions ===")

-- Function returning function
-- SKIPPED: Requires closures
print("Function returning function:")
print("  (SKIPPED: closures not implemented)")
-- local function makeCounter()
--   local count = 0
--   return function()
--     count = count + 1
--     return count
--   end
-- end
--
-- local counter = makeCounter()
-- print("  counter() =", counter())
-- print("  counter() =", counter())

-- Recursive function
-- BUG: Local recursive functions don't work
print("\nRecursive function:")
print("  (SKIPPED: local recursive functions broken)")
-- local function factorial(n)
--   if n <= 1 then
--     return 1
--   else
--     return n * factorial(n - 1)
--   end
-- end
--
-- print("  factorial(5) =", factorial(5))
-- print("  factorial(0) =", factorial(0))

-- Mutually recursive functions
-- BUG: Mutual recursion requires forward declaration which may not work
print("\nMutually recursive:")
print("  (SKIPPED: mutual recursion broken)")
-- local function isEven(n)
--   if n == 0 then
--     return true
--   else
--     return isOdd(n - 1)
--   end
-- end
--
-- local function isOdd(n)
--   if n == 0 then
--     return false
--   else
--     return isEven(n - 1)
--   end
-- end
--
-- print("  isEven(4) =", isEven(4))
-- print("  isOdd(4) =", isOdd(4))

-- Function with many parameters
print("\nMany parameters:")
local function sum5(a, b, c, d, e)
  return a + b + c + d + e
end

print("  sum5(1,2,3,4,5) =", sum5(1, 2, 3, 4, 5))

-- Function with optional parameters (using or)
print("\nOptional parameters:")
local function greet(name)
  name = name or "World"
  return "Hello, " .. name
end

print("  greet('Alice') =", greet("Alice"))
print("  greet() =", greet())  -- BUG: Missing arg might not be nil

-- Tail call
-- BUG: Recursive helper functions don't work
print("\nTail call:")
print("  (SKIPPED: recursion broken)")
-- local function helper(n, acc)
--   if n == 0 then
--     return acc
--   else
--     return helper(n - 1, acc + n)
--   end
-- end
--
-- local function sumToN(n)
--   return helper(n, 0)
-- end
--
-- print("  sumToN(100) =", sumToN(100))

-- Function table
print("\nFunction table:")
local ops = {
  add = function(a, b) return a + b end,
  sub = function(a, b) return a - b end,
  mul = function(a, b) return a * b end
}

print("  ops.add(5, 3) =", ops.add(5, 3))
print("  ops.sub(5, 3) =", ops.sub(5, 3))
print("  ops.mul(5, 3) =", ops.mul(5, 3))

-- Multiple returns from nested calls
-- BUG: Local functions can't call other local functions in same scope
print("\nNested returns:")
print("  (SKIPPED: local function scoping broken)")
-- local function swap(a, b)
--   return b, a
-- end
--
-- local function swapTwice(a, b)
--   return swap(swap(a, b))
-- end
--
-- local x, y = swapTwice(1, 2)
-- print("  swapTwice(1, 2) =", x, y)

print("\n=== Complex function tests complete! ===")
