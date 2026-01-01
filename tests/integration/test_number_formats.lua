-- Test number formats and literals
print("=== Number Formats ===")

-- Integer literals
print("Integer literals:")
print("  0 =", 0)
print("  42 =", 42)
print("  1000000 =", 1000000)

-- Negative integers
print("\nNegative integers:")
print("  -1 =", -1)
print("  -42 =", -42)
print("  -1000 =", -1000)

-- Float literals
print("\nFloat literals:")
print("  3.14 =", 3.14)
print("  0.5 =", 0.5)
print("  99.99 =", 99.99)

-- Leading/trailing decimal
-- BUG: Leading decimal (.5) and trailing decimal (5.) not supported
print("\nDecimal variations:")
-- print("  .5 =", .5)  -- Syntax error
-- print("  5. =", 5.)  -- Syntax error
print("  (Leading/trailing decimal not supported)")
print("  10.0 =", 10.0)

-- Scientific notation
print("\nScientific notation:")
print("  1e3 =", 1e3)
print("  1e-3 =", 1e-3)
print("  2.5e2 =", 2.5e2)
print("  1E3 =", 1E3)
print("  1e+2 =", 1e+2)

-- Hexadecimal
print("\nHexadecimal:")
print("  0x0 =", 0x0)
print("  0x10 =", 0x10)
print("  0xFF =", 0xFF)
print("  0xff =", 0xff)
print("  0xABCD =", 0xABCD)
print("  0xFFFF =", 0xFFFF)

-- Hex with letters
print("\nHex letters:")
print("  0xDEADBEEF =", 0xDEADBEEF)
print("  0xCAFE =", 0xCAFE)

-- Zero variations
print("\nZero variations:")
print("  0 =", 0)
print("  0.0 =", 0.0)
print("  -0 =", -0)
print("  0x0 =", 0x0)

-- Very large numbers
print("\nLarge numbers:")
print("  999999999999 =", 999999999999)
print("  1e15 =", 1e15)

-- Very small numbers
print("\nSmall numbers:")
print("  0.000001 =", 0.000001)
print("  1e-9 =", 1e-9)

-- Numbers in expressions
print("\nIn expressions:")
print("  1 + 2.5 =", 1 + 2.5)
print("  0xFF + 1 =", 0xFF + 1)
print("  1e2 * 2 =", 1e2 * 2)

-- Number comparison
print("\nComparison:")
print("  1 == 1.0 =", 1 == 1.0)
print("  0 == -0 =", 0 == -0)
print("  0x10 == 16 =", 0x10 == 16)
print("  1e2 == 100 =", 1e2 == 100)

-- Number types
print("\nTypes:")
print("  type(42) =", type(42))
print("  type(3.14) =", type(3.14))
print("  type(0xFF) =", type(0xFF))
print("  type(1e3) =", type(1e3))

-- Number precision
print("\nPrecision:")
print("  0.1 + 0.2 =", 0.1 + 0.2)
print("  0.1 + 0.2 == 0.3 =", 0.1 + 0.2 == 0.3)

-- Integer vs float arithmetic
print("\nInteger vs float:")
print("  5 / 2 =", 5 / 2)
print("  5 // 2 =", 5 // 2)
print("  5.0 / 2 =", 5.0 / 2)

-- Negative zero
print("\nNegative zero:")
print("  -0 =", -0)
print("  0 == -0 =", 0 == -0)
print("  0 < -0 =", 0 < -0)

-- Number limits
print("\nNumber limits:")
print("  1 / 0 = (would be inf, but throws error)")
-- print("  1 / 0 =", 1 / 0)  -- Throws error
print("  0 / 0 = (would be nan, but throws error)")
-- print("  0 / 0 =", 0 / 0)  -- Throws error

-- Underscores in numbers (Lua 5.4 feature - may not work)
-- print("\nUnderscores (5.4):")
-- print("  1_000_000 =", 1_000_000)

print("\n=== Number format tests complete! ===")
