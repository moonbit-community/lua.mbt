-- Test negative number handling thoroughly
print("=== Negative Numbers ===")

-- Basic negative numbers
print("Basic negatives:")
print("  -5 =", -5)
print("  -3.14 =", -3.14)
print("  -0 =", -0)

-- Negative in arithmetic
print("\nNegative arithmetic:")
print("  -5 + 3 =", -5 + 3)
print("  -5 - 3 =", -5 - 3)
print("  -5 * 3 =", -5 * 3)
print("  -5 / 2 =", -5 / 2)
print("  -5 % 3 =", -5 % 3)

-- Unary minus
print("\nUnary minus:")
local x = 5
print("  x = 5")
print("  -x =", -x)
print("  x still =", x)

-- Double negative
print("\nDouble negative:")
print("  -(-5) =", -(-5))
print("  - -5 =", - -5)

-- Negative comparisons
print("\nNegative comparisons:")
print("  -5 < 0 =", -5 < 0)
print("  -5 < -3 =", -5 < -3)
print("  -3 > -5 =", -3 > -5)
print("  -5 == -5 =", -5 == -5)

-- Negative powers
print("\nNegative powers:")
print("  (-2) ^ 3 =", (-2) ^ 3)
print("  (-2) ^ 2 =", (-2) ^ 2)
print("  2 ^ -1 =", 2 ^ -1)
print("  10 ^ -2 =", 10 ^ -2)

-- Negative in expressions
print("\nIn expressions:")
print("  5 + -3 =", 5 + -3)
print("  5 * -2 =", 5 * -2)
print("  10 / -5 =", 10 / -5)

-- Negative zero
-- BUG: Division by -0 throws error instead of returning -inf
print("\nNegative zero:")
print("  -0 == 0 =", -0 == 0)
-- print("  1 / -0 =", 1 / -0)  -- Throws error instead of -inf
print("  (1 / -0 throws error, should be -inf)")

-- Very small negative
print("\nVery small:")
local tiny = -0.0001
print("  -0.0001 =", tiny)

-- Large negative
print("\nLarge negative:")
local big = -1000000
print("  -1000000 =", big)

-- Negative in table
print("\nIn table:")
local t = {-1, -2, -3}
print("  t = {-1, -2, -3}")
print("  t[1], t[2], t[3] =", t[1], t[2], t[3])

-- Negative as key
print("\nAs table key:")
local t2 = {}
t2[-1] = "negative one"
t2[-5] = "negative five"
print("  t2[-1] =", t2[-1])
print("  t2[-5] =", t2[-5])

-- Concatenate negative
print("\nConcatenate:")
print("  'value: ' .. -42 =", "value: " .. -42)

-- Negative in loop
print("\nIn loop:")
for i = -2, 0 do
  print("  i =", i)
end

print("\n=== Negative number tests complete! ===")
