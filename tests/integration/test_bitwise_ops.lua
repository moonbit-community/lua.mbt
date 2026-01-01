-- Test bitwise operators (Lua 5.3+)
print("=== Bitwise Operators ===")

-- Bitwise AND
print("Bitwise AND:")
print("  5 & 3 =", 5 & 3)  -- Should be 1
print("  15 & 7 =", 15 & 7)  -- Should be 7

-- Bitwise OR
print("\nBitwise OR:")
print("  5 | 3 =", 5 | 3)  -- Should be 7
print("  8 | 4 =", 8 | 4)  -- Should be 12

-- Bitwise XOR
print("\nBitwise XOR:")
print("  5 ~ 3 =", 5 ~ 3)  -- Should be 6
print("  15 ~ 15 =", 15 ~ 15)  -- Should be 0

-- Bitwise NOT
print("\nBitwise NOT:")
print("  ~0 =", ~0)  -- Should be -1
print("  ~5 =", ~5)  -- Should be -6

-- Left shift
print("\nLeft shift:")
print("  1 << 3 =", 1 << 3)  -- Should be 8
print("  5 << 2 =", 5 << 2)  -- Should be 20

-- Right shift
print("\nRight shift:")
print("  8 >> 2 =", 8 >> 2)  -- Should be 2
print("  20 >> 1 =", 20 >> 1)  -- Should be 10

-- Combined bitwise operations
print("\nCombined:")
print("  (5 & 3) | 8 =", (5 & 3) | 8)
print("  (10 << 1) >> 1 =", (10 << 1) >> 1)

-- Bitwise on negative numbers
print("\nNegative numbers:")
print("  -5 & 3 =", -5 & 3)
print("  -1 >> 1 =", -1 >> 1)

print("\n=== Bitwise operator tests complete! ===")
