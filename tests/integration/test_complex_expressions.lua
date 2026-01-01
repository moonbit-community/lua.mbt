-- Test complex expression evaluation
print("=== Complex Expressions ===")

-- Operator precedence
print("Operator precedence:")
print("  2 + 3 * 4 =", 2 + 3 * 4)  -- Should be 14
print("  (2 + 3) * 4 =", (2 + 3) * 4)  -- Should be 20
print("  10 - 5 - 2 =", 10 - 5 - 2)  -- Left-to-right: should be 3
print("  2 ^ 3 ^ 2 =", 2 ^ 3 ^ 2)  -- Right-to-left: should be 512

-- Comparison chaining (doesn't work in Lua but test anyway)
print("\nMultiple comparisons:")
print("  5 > 3 and 3 > 1 =", 5 > 3 and 3 > 1)
print("  10 < 5 or 5 < 20 =", 10 < 5 or 5 < 20)

-- Short-circuit evaluation
print("\nShort-circuit evaluation:")
local function alwaysTrue()
  print("  alwaysTrue called")
  return true
end

local function neverCalled()
  print("  neverCalled called (BUG!)")
  return false
end

print("  Result:", true or neverCalled())
print("  Result:", false and neverCalled())

-- Truthiness with and/or
print("\nTruthiness in and/or:")
print("  1 and 2 =", 1 and 2)
print("  nil and 2 =", nil and 2)
print("  false and 2 =", false and 2)
print("  1 or 2 =", 1 or 2)
print("  nil or 2 =", nil or 2)

-- Complex string concatenation
print("\nComplex concatenation:")
print("  'a' .. 'b' .. 'c' =", "a" .. "b" .. "c")
print("  1 .. 2 .. 3 =", 1 .. 2 .. 3)
print("  'x' .. 5 .. 'y' =", "x" .. 5 .. "y")

-- Deeply nested expressions
print("\nDeeply nested:")
local result = ((((1 + 2) * 3) - 4) / 2) ^ 2
print("  ((((1+2)*3)-4)/2)^2 =", result)

-- Mixed operators
print("\nMixed operators:")
print("  10 % 3 * 2 =", 10 % 3 * 2)
print("  -5 ^ 2 =", -5 ^ 2)  -- Unary minus vs power
print("  -(5 ^ 2) =", -(5 ^ 2))

-- Not operator precedence
print("\nNot precedence:")
print("  not false and true =", not false and true)
print("  not (false and true) =", not (false and true))
print("  not true or true =", not true or true)

-- Comparison with arithmetic
print("\nComparison with arithmetic:")
print("  5 + 3 > 7 =", 5 + 3 > 7)
print("  10 / 2 == 5 =", 10 / 2 == 5)
print("  3 * 4 ~= 11 =", 3 * 4 ~= 11)

-- String comparison
print("\nString comparison:")
print("  'abc' < 'xyz' =", "abc" < "xyz")
print("  'aaa' < 'ab' =", "aaa" < "ab")
print("  'A' < 'a' =", "A" < "a")

-- Nil in expressions
print("\nNil in expressions:")
print("  nil == nil =", nil == nil)
print("  nil == false =", nil == false)
print("  not nil =", not nil)

-- Empty string
print("\nEmpty string:")
print("  '' == '' =", "" == "")
print("  #'' =", #"")

-- Very long expression
print("\nVery long expression:")
local long = 1 + 2 - 3 * 4 / 5 % 6 + 7 - 8 * 9
print("  1+2-3*4/5%6+7-8*9 =", long)

print("\n=== Complex expression tests complete! ===")
