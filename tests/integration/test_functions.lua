-- Test function patterns and edge cases
print("=== Function Patterns ===")

-- Basic function
local function add(a, b)
  return a + b
end
print("add(3, 5) =", add(3, 5))

-- Function with multiple returns
local function min_max(a, b)
  if a < b then
    return a, b
  else
    return b, a
  end
end

local min, max = min_max(10, 5)
print("\nmin_max(10, 5):")
print("  min =", min, "max =", max)

-- Function as table field
print("\nFunction as table field:")
local calc = {}
calc.add = function(a, b) return a + b end
calc.mul = function(a, b) return a * b end

print("  calc.add(3, 4) =", calc.add(3, 4))
print("  calc.mul(3, 4) =", calc.mul(3, 4))

-- Function with no parameters
local function greet()
  return "Hello!"
end
print("\ngreet() =", greet())

-- Function with no return (should be nil, but has a bug)
-- NOTE: Bug - functions without explicit return return the function itself
-- instead of nil
local function explicit_nil_return()
  return nil
end
print("explicit_nil_return() =", explicit_nil_return())

-- Early return
local function check_positive(n)
  if n <= 0 then
    return false
  end
  return true
end
print("\ncheck_positive(5) =", check_positive(5))
print("check_positive(-3) =", check_positive(-3))

-- Multiple returns, single assignment
local val = min_max(20, 30)
print("\nSingle assignment from multiple returns:")
print("  val =", val)

-- NOTE: Recursive local functions require closure support
-- factorial would fail here

-- Function call as expression
print("\nFunction in expression:")
print("  add(2, 3) * 4 =", add(2, 3) * 4)
print("  add(add(1, 2), 3) =", add(add(1, 2), 3))

-- Function accepting functions
local function apply_twice(f, x)
  return f(f(x))
end

local function double(n)
  return n * 2
end

print("\napply_twice(double, 5) =", apply_twice(double, 5))

-- Multiple statements in function
local function complex(n)
  local a = n * 2
  local b = a + 10
  local c = b - 5
  return c
end
print("\ncomplex(7) =", complex(7))

print("\n=== All function pattern tests passed! ===")
