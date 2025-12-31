-- Test complex expressions and operator precedence
print("=== Complex Expressions ===")

-- Arithmetic precedence
print("Arithmetic precedence:")
print("2 + 3 * 4 =", 2 + 3 * 4)  -- Should be 14, not 20
print("10 - 2 * 3 =", 10 - 2 * 3)  -- Should be 4, not 24
print("2 ^ 3 * 4 =", 2 ^ 3 * 4)  -- Should be 32 (8 * 4)
print("2 * 3 ^ 2 =", 2 * 3 ^ 2)  -- Should be 18 (2 * 9)

-- Parentheses
print("\nWith parentheses:")
print("(2 + 3) * 4 =", (2 + 3) * 4)
print("(10 - 2) * 3 =", (10 - 2) * 3)
print("2 ^ (3 - 1) =", 2 ^ (3 - 1))

-- Comparison precedence
print("\nComparison with arithmetic:")
print("5 + 3 > 6 =", 5 + 3 > 6)
print("10 - 5 == 5 =", 10 - 5 == 5)
print("3 * 2 < 7 =", 3 * 2 < 7)

-- Logical with comparison
print("\nLogical operators:")
print("true and true =", true and true)
print("true and false =", true and false)
print("true or false =", true or false)
print("5 > 3 and 10 < 20 =", 5 > 3 and 10 < 20)
print("5 > 10 or 3 < 7 =", 5 > 10 or 3 < 7)

-- Short-circuit evaluation with values
print("\nShort-circuit returns:")
print("10 and 20 =", 10 and 20)
print("nil or 42 =", nil or 42)
print("false or 'default' =", false or "default")

-- Complex nested expressions
print("\nComplex nested:")
local result = (5 + 3) * 2 - (10 / 2) + 1
print("(5 + 3) * 2 - (10 / 2) + 1 =", result)

-- Chained comparisons (not like Python, each is separate)
print("\nComparisons:")
print("1 < 2 =", 1 < 2)
print("2 < 3 =", 2 < 3)
print("(1 < 2) and (2 < 3) =", (1 < 2) and (2 < 3))

-- Not with complex expressions
print("\nNot operator:")
print("not (5 > 3) =", not (5 > 3))
print("not (true and false) =", not (true and false))
print("not nil =", not nil)
print("not 0 =", not 0)  -- 0 is truthy in Lua!

print("\n=== All complex expression tests passed! ===")
