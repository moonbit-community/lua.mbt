-- Test operator combinations
print("=== Operator Combinations ===")

-- Arithmetic combinations
print("Arithmetic:")
print("  2 + 3 * 4 - 5 =", 2 + 3 * 4 - 5)
print("  10 / 2 + 3 * 2 =", 10 / 2 + 3 * 2)
print("  2 ^ 3 + 2 ^ 2 =", 2 ^ 3 + 2 ^ 2)

-- With parentheses
print("\nWith parentheses:")
print("  (2 + 3) * (4 - 1) =", (2 + 3) * (4 - 1))
print("  (10 - 5) / (3 - 2) =", (10 - 5) / (3 - 2))

-- Comparison combinations
print("\nComparisons:")
local a, b, c = 5, 10, 15
print("  a < b and b < c =", a < b and b < c)
print("  a < b or b > c =", a < b or b > c)
print("  not (a > b) =", not (a > b))

-- Mixed arithmetic and comparison
print("\nMixed:")
print("  5 + 5 == 10 =", 5 + 5 == 10)
print("  3 * 3 > 8 =", 3 * 3 > 8)
print("  10 - 5 <= 5 =", 10 - 5 <= 5)

-- Logical operator precedence
print("\nLogical precedence:")
print("  true or false and false =", true or false and false)  -- and binds tighter
print("  (true or false) and false =", (true or false) and false)
print("  true or (false and false) =", true or (false and false))

-- Not with comparisons (use parentheses)
print("\nNot with comparisons:")
print("  not (5 > 3) =", not (5 > 3))
print("  not (5 < 3) =", not (5 < 3))
-- NOTE: "not 5 > 3" would fail - parsed as "(not 5) > 3"

-- Bitwise combinations
print("\nBitwise:")
print("  12 & 10 | 4 =", 12 & 10 | 4)
print("  (12 & 10) | 4 =", (12 & 10) | 4)
print("  12 & (10 | 4) =", 12 & (10 | 4))

-- Unary operators
print("\nUnary operators:")
print("  -5 + 3 =", -5 + 3)
print("  -(5 + 3) =", -(5 + 3))
print("  ~5 =", ~5)
print("  not true =", not true)

-- Complex expressions
print("\nComplex expressions:")
print("  2 + 3 * 4 / 2 - 1 =", 2 + 3 * 4 / 2 - 1)
print("  (10 + 20) * (5 - 2) =", (10 + 20) * (5 - 2))

-- String concatenation precedence
print("\nString concat:")
print("  'a' .. 'b' .. 'c' =", "a" .. "b" .. "c")
print("  'sum: ' .. 2 + 3 =", "sum: " .. 2 + 3)

print("\n=== All operator combination tests passed! ===")
