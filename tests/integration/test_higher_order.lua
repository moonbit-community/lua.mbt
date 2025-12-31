-- Test anonymous functions and higher-order functions

print("=== Anonymous Functions ===")

-- Anonymous function assigned to variable
local add = function(a, b)
  return a + b
end

print("add(3, 7) =", add(3, 7))

local multiply = function(x, y)
  return x * y
end

print("multiply(4, 5) =", multiply(4, 5))

-- Higher-order functions: functions that take functions as arguments
print("\n=== Higher-Order Functions ===")

local function apply(f, x, y)
  return f(x, y)
end

print("apply(add, 10, 20) =", apply(add, 10, 20))
print("apply(multiply, 6, 7) =", apply(multiply, 6, 7))

-- Map-like function
print("\n=== Map-like Operation ===")

local function map(f, arr)
  local result = {}
  for i = 1, #arr do
    result[i] = f(arr[i])
  end
  return result
end

local square = function(x)
  return x * x
end

local numbers = {1, 2, 3, 4, 5}
local squares = map(square, numbers)

print("Squares:")
for i = 1, #squares do
  print("  " .. i .. "^2 = " .. squares[i])
end

print("\n=== All higher-order function tests passed! ===")
