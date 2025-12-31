-- Test number edge cases and special values
print("=== Number Edge Cases ===")

-- Large numbers
print("Large numbers:")
print("  1000000 =", 1000000)
print("  1000000000 =", 1000000000)

-- Small numbers
print("\nSmall numbers:")
print("  0.001 =", 0.001)
print("  0.0001 =", 0.0001)

-- Negative numbers
print("\nNegative numbers:")
print("  -42 =", -42)
print("  -3.14 =", -3.14)

-- Scientific notation (if supported)
print("\nScientific notation:")
-- May not be supported, test carefully
local sci1 = 1e3
print("  1e3 =", sci1)

local sci2 = 1.5e2
print("  1.5e2 =", sci2)

local sci3 = 2e-2
print("  2e-2 =", sci3)

-- Zero variations
print("\nZero:")
print("  0 =", 0)
print("  0.0 =", 0.0)
print("  -0 =", -0)

-- Arithmetic with special values
print("\nArithmetic edge cases:")
print("  1 / 3 =", 1 / 3)
print("  2 / 3 =", 2 / 3)
print("  10 / 3 =", 10 / 3)

-- Integer vs float
print("\nInteger vs float:")
print("  5 =", 5)
print("  5.0 =", 5.0)
print("  5 == 5.0 =", 5 == 5.0)

-- Very large multiplication
print("\nLarge operations:")
print("  1000 * 1000 =", 1000 * 1000)
print("  999 * 999 =", 999 * 999)

-- Power edge cases
print("\nPower edge cases:")
print("  2 ^ 0 =", 2 ^ 0)
print("  0 ^ 0 =", 0 ^ 0)
print("  1 ^ 100 =", 1 ^ 100)
print("  (-2) ^ 3 =", (-2) ^ 3)

print("\n=== All number edge case tests passed! ===")
