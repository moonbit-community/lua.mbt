-- Test math library functions
-- CRITICAL BUG: math library is NOT IMPLEMENTED
-- Global 'math' does not exist
-- All math.* functions will fail with "Failed to get global 'math'"
print("=== Math Library ===")

-- Basic constants
-- NOTE: This will error because math library is not available
print("Constants:")
print("  math.pi =", math.pi)
print("  math.huge =", math.huge)

-- Basic operations
print("\nBasic math:")
print("  abs(-5) =", math.abs(-5))
print("  abs(3.14) =", math.abs(3.14))
print("  floor(3.7) =", math.floor(3.7))
print("  ceil(3.2) =", math.ceil(3.2))

-- Min/max
print("\nMin/max:")
print("  min(5, 3) =", math.min(5, 3))
print("  max(5, 3) =", math.max(5, 3))
print("  min(1, 2, 3) =", math.min(1, 2, 3))

-- Power and roots
print("\nPower and roots:")
print("  sqrt(16) =", math.sqrt(16))
print("  sqrt(2) =", math.sqrt(2))
print("  pow(2, 3) =", math.pow(2, 3))

-- Exponential and logarithm
print("\nExp/log:")
print("  exp(1) =", math.exp(1))
print("  log(2.718281828) =", math.log(2.718281828))
print("  log10(100) =", math.log10(100))

-- Trigonometry
print("\nTrig functions:")
print("  sin(0) =", math.sin(0))
print("  cos(0) =", math.cos(0))
print("  tan(0) =", math.tan(0))

-- Rounding
print("\nRounding:")
print("  floor(3.9) =", math.floor(3.9))
print("  ceil(3.1) =", math.ceil(3.1))

-- Random (may not be seeded consistently)
print("\nRandom:")
math.randomseed(42)
print("  random() =", math.random())
print("  random(10) =", math.random(10))
print("  random(5, 10) =", math.random(5, 10))

-- Modulo
print("\nModulo:")
print("  fmod(7, 3) =", math.fmod(7, 3))
print("  fmod(7.5, 2) =", math.fmod(7.5, 2))

print("\n=== Math library tests complete! ===")
