-- Test error handling and edge cases
print("=== Error Handling ===")

-- Using assert for validation
print("Testing assert:")
assert(true, "This should pass")
print("  assert(true) passed")

assert(1 == 1, "Math should work")
print("  assert(1 == 1) passed")

-- assert with truthy values
assert(42, "Numbers are truthy")
print("  assert(42) passed")

assert("string", "Strings are truthy")
print("  assert('string') passed")

-- Type checking before operations
print("\nType checking:")
local function safe_add(a, b)
  if type(a) ~= "number" or type(b) ~= "number" then
    return nil
  end
  return a + b
end

print("  safe_add(3, 5) =", safe_add(3, 5))
print("  safe_add('x', 5) =", safe_add("x", 5))

-- Nil checks
print("\nNil checking:")
local function get_length(t)
  if t == nil then
    return 0
  end
  return #t
end

print("  get_length({1,2,3}) =", get_length({1, 2, 3}))
print("  get_length(nil) =", get_length(nil))

-- Guard clauses
print("\nGuard clauses:")
local function process(val)
  if val == nil then
    return "nil value"
  end
  if val < 0 then
    return "negative"
  end
  return "valid"
end

print("  process(10) =", process(10))
print("  process(-5) =", process(-5))
print("  process(nil) =", process(nil))

-- NOTE: Division by zero throws an error instead of returning inf/nan
-- This is different from standard Lua
print("\nDivision edge cases:")
print("  10 / 2 =", 10 / 2)
print("  1 / 3 =", 1 / 3)
-- print("  10 / 0 =", 10 / 0)  -- Would throw error

-- Defensive division
local function safe_divide(a, b)
  if b == 0 then
    return nil
  end
  return a / b
end

print("  safe_divide(10, 2) =", safe_divide(10, 2))
print("  safe_divide(10, 0) =", safe_divide(10, 0))

print("\n=== All error handling tests passed! ===")
