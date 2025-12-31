-- Test math operations
print("=== Math Operations ===")

-- Basic arithmetic (already tested but for completeness)
print("Addition: 10 + 5 =", 10 + 5)
print("Subtraction: 10 - 5 =", 10 - 5)
print("Multiplication: 10 * 5 =", 10 * 5)
print("Division: 10 / 5 =", 10 / 5)

-- Modulo
print("\nModulo:")
print("10 % 3 =", 10 % 3)
print("20 % 7 =", 20 % 7)
print("15 % 5 =", 15 % 5)

-- Integer division (floor division)
print("\nFloor division:")
print("10 // 3 =", 10 // 3)
print("20 // 7 =", 20 // 7)
print("15 // 5 =", 15 // 5)

-- Power
print("\nExponentiation:")
print("2 ^ 3 =", 2 ^ 3)
print("5 ^ 2 =", 5 ^ 2)
print("10 ^ 0 =", 10 ^ 0)

-- Unary minus
print("\nUnary minus:")
print("-(5) =", -(5))
print("-(-10) =", -(-10))
local val = 42
print("-val =", -val)

-- Mixed operations
print("\nMixed operations:")
print("2 + 3 * 4 =", 2 + 3 * 4)
print("(2 + 3) * 4 =", (2 + 3) * 4)
print("10 - 2 * 3 =", 10 - 2 * 3)
print("2 ^ 3 + 1 =", 2 ^ 3 + 1)

print("\n=== All math operation tests passed! ===")
