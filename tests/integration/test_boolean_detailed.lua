-- Test boolean values and operations
print("=== Boolean Values ===")

-- Boolean literals
print("Boolean literals:")
print("  true =", true)
print("  false =", false)

-- Boolean type
print("\nBoolean type:")
print("  type(true) =", type(true))
print("  type(false) =", type(false))

-- Boolean equality
print("\nEquality:")
print("  true == true =", true == true)
print("  false == false =", false == false)
print("  true == false =", true == false)

-- Boolean inequality
print("\nInequality:")
print("  true ~= false =", true ~= false)
print("  true ~= true =", true ~= true)

-- Boolean and
print("\nLogical AND:")
print("  true and true =", true and true)
print("  true and false =", true and false)
print("  false and true =", false and true)
print("  false and false =", false and false)

-- Boolean or
print("\nLogical OR:")
print("  true or true =", true or true)
print("  true or false =", true or false)
print("  false or true =", false or true)
print("  false or false =", false or false)

-- Boolean not
print("\nLogical NOT:")
print("  not true =", not true)
print("  not false =", not false)

-- Boolean in expressions
print("\nIn expressions:")
print("  true and (5 > 3) =", true and (5 > 3))
print("  false or (10 == 10) =", false or (10 == 10))
print("  not (2 > 5) =", not (2 > 5))

-- Comparison results
print("\nFrom comparisons:")
local cmp1 = 5 > 3
print("  5 > 3 =", cmp1, type(cmp1))
local cmp2 = 10 < 5
print("  10 < 5 =", cmp2, type(cmp2))

-- Boolean in conditions
print("\nIn conditions:")
if true then
  print("  true is truthy ✓")
end

if false then
  print("  ERROR: false is truthy")
else
  print("  false is falsy ✓")
end

-- Not not pattern
print("\nDouble negation:")
print("  not not true =", not not true)
print("  not not false =", not not false)

-- Boolean with nil
print("\nBoolean with nil:")
print("  nil == false =", nil == false)
print("  nil ~= false =", nil ~= false)
print("  not nil =", not nil)

-- Boolean with numbers
print("\nBoolean with numbers:")
print("  true == 1 =", true == 1)
print("  false == 0 =", false == 0)
print("  true ~= 1 =", true ~= 1)

-- Boolean and numbers in and/or
-- BUG: Numbers not truthy
print("\nBoolean and numbers:")
print("  true and 1 =", true and 1)
print("  false and 1 =", false and 1)
print("  true or 1 =", true or 1)
print("  false or 1 =", false or 1)
-- print("  1 and true =", 1 and true)  -- Would be false due to truthiness bug
print("  (1 and true = false due to truthiness bug)")

-- Boolean conversion
print("\nBoolean conversion:")
print("  tostring(true) =", tostring(true))
print("  tostring(false) =", tostring(false))
-- tonumber on boolean
local num_true = tonumber("true")
print("  tonumber('true') =", num_true)

-- Boolean in table
print("\nIn table:")
local t = {true, false, true}
print("  t[1], t[2], t[3] =", t[1], t[2], t[3])

-- Boolean as table key
-- BUG: Boolean keys don't work
print("\nAs table key:")
local bt = {}
bt[true] = "yes"
bt[false] = "no"
print("  bt[true] =", bt[true], "(BUG: may be nil)")
print("  bt[false] =", bt[false], "(BUG: may be nil)")

-- Boolean in function
print("\nIn function:")
local function negate(b)
  return not b
end
print("  negate(true) =", negate(true))
print("  negate(false) =", negate(false))

-- Boolean return
print("\nReturn boolean:")
local function isPositive(n)
  return n > 0
end
print("  isPositive(5) =", isPositive(5))
print("  isPositive(-3) =", isPositive(-3))

-- Chained boolean ops
print("\nChained operations:")
print("  true and true and true =", true and true and true)
print("  true and true and false =", true and true and false)
print("  false or false or true =", false or false or true)
print("  false or false or false =", false or false or false)

-- Complex boolean expr
print("\nComplex expressions:")
print("  (true or false) and true =", (true or false) and true)
print("  true and (false or true) =", true and (false or true))
print("  not (true and false) =", not (true and false))

-- Boolean assignment
print("\nAssignment:")
local b1 = true
local b2 = false
print("  b1, b2 =", b1, b2)

-- Swapping booleans
b1, b2 = b2, b1
print("  After swap: b1, b2 =", b1, b2, "(BUG: may be wrong)")

-- Boolean ternary-like
print("\nTernary-like:")
local value = true and "yes" or "no"
print("  true and 'yes' or 'no' =", value)
local value2 = false and "yes" or "no"
print("  false and 'yes' or 'no' =", value2)

print("\n=== Boolean tests complete! ===")
