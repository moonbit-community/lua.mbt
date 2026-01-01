-- Test function call variations and edge cases
print("=== Function Calls ===")

-- Basic function call
print("Basic call:")
local function greet()
  return "Hello"
end
print("  greet() =", greet())

-- Function with one argument
print("\nOne argument:")
local function square(x)
  return x * x
end
print("  square(5) =", square(5))

-- Function with multiple arguments
print("\nMultiple arguments:")
local function add(a, b, c)
  return a + b + c
end
print("  add(1, 2, 3) =", add(1, 2, 3))

-- Too few arguments (should be nil)
print("\nToo few arguments:")
local function needsThree(a, b, c)
  return a, b, c
end
local x, y, z = needsThree(1)
print("  needsThree(1) -> a,b,c =", x, y, z)

-- Too many arguments (extra ignored)
print("\nToo many arguments:")
local function needsOne(a)
  return a
end
print("  needsOne(1, 2, 3) =", needsOne(1, 2, 3))

-- Function returning nothing
print("\nNo return:")
local function noReturn()
  -- No return statement
end
local result = noReturn()
print("  noReturn() =", result, "(BUG: should be nil)")

-- Function returning multiple values
print("\nMultiple returns:")
local function multi()
  return 1, 2, 3
end
local a, b, c = multi()
print("  multi() -> a,b,c =", a, b, c)

-- Using only first return value
local first = multi()
print("  first only =", first)

-- Function as argument
print("\nFunction as argument:")
local function apply(f, x)
  return f(x)
end
print("  apply(square, 4) =", apply(square, 4))

-- Returning a function
-- BUG: Requires closures (not implemented)
print("\nReturning function:")
-- local function makeAdder(n)
--   return function(x)
--     return x + n
--   end
-- end
-- local add5 = makeAdder(5)
-- print("  add5(10) =", add5(10))
print("  (SKIPPED: closures not implemented)")

-- Anonymous function
print("\nAnonymous function:")
local double = function(x) return x * 2 end
print("  double(7) =", double(7))

-- Immediate call
print("\nImmediate call:")
print("  (function(x) return x*3 end)(4) =", (function(x) return x*3 end)(4))

-- Function in table
print("\nFunction in table:")
local obj = {
  value = 10,
  getValue = function(self) return self.value end
}
print("  obj.getValue(obj) =", obj.getValue(obj))

-- Call with expression as argument
print("\nExpression as argument:")
print("  square(2 + 3) =", square(2 + 3))

-- Nested function calls
print("\nNested calls:")
print("  square(square(2)) =", square(square(2)))

print("\n=== Function call tests complete! ===")
