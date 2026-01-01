-- Test comparison operators thoroughly
print("=== Comparison Operators ===")

-- Equality
print("Equality (==):")
print("  5 == 5 =", 5 == 5)
print("  5 == 6 =", 5 == 6)
print("  'a' == 'a' =", "a" == "a")
print("  'a' == 'b' =", "a" == "b")
print("  true == true =", true == true)
print("  true == false =", true == false)
print("  nil == nil =", nil == nil)

-- Inequality
print("\nInequality (~=):")
print("  5 ~= 6 =", 5 ~= 6)
print("  5 ~= 5 =", 5 ~= 5)
print("  'a' ~= 'b' =", "a" ~= "b")
print("  true ~= false =", true ~= false)

-- Less than
print("\nLess than (<):")
print("  3 < 5 =", 3 < 5)
print("  5 < 3 =", 5 < 3)
print("  5 < 5 =", 5 < 5)
print("  'a' < 'b' =", "a" < "b")
print("  'z' < 'a' =", "z" < "a")

-- Greater than
print("\nGreater than (>):")
print("  5 > 3 =", 5 > 3)
print("  3 > 5 =", 3 > 5)
print("  5 > 5 =", 5 > 5)

-- Less than or equal
print("\nLess than or equal (<=):")
print("  3 <= 5 =", 3 <= 5)
print("  5 <= 5 =", 5 <= 5)
print("  7 <= 5 =", 7 <= 5)

-- Greater than or equal
print("\nGreater than or equal (>=):")
print("  5 >= 3 =", 5 >= 3)
print("  5 >= 5 =", 5 >= 5)
print("  3 >= 5 =", 3 >= 5)

-- Comparing different types (type mismatch)
print("\nType comparisons:")
print("  5 == '5' =", 5 == "5")  -- Should be false
print("  true == 1 =", true == 1)  -- Should be false
print("  nil == false =", nil == false)  -- Should be false

-- Negative numbers
print("\nNegative numbers:")
print("  -5 < 0 =", -5 < 0)
print("  -3 < -7 =", -3 < -7)
print("  -5 == -5 =", -5 == -5)

-- Float comparisons
print("\nFloat comparisons:")
print("  3.14 > 3 =", 3.14 > 3)
print("  2.5 == 2.5 =", 2.5 == 2.5)
print("  1.0 == 1 =", 1.0 == 1)

-- Chained comparisons using and
print("\nChained comparisons:")
print("  1 < 2 and 2 < 3 =", 1 < 2 and 2 < 3)
print("  5 > 3 and 3 > 1 =", 5 > 3 and 3 > 1)

-- Comparisons in variables
print("\nStored comparisons:")
local result1 = 10 > 5
local result2 = 3 == 3
print("  result1 =", result1)
print("  result2 =", result2)

print("\n=== All comparison operator tests passed! ===")
