-- Comprehensive operator testing
print("=== Comprehensive Operator Testing ===")

-- Arithmetic operators
print("Arithmetic operators:")
print("  10 + 5 =", 10 + 5)
print("  10 - 5 =", 10 - 5)
print("  10 * 5 =", 10 * 5)
print("  10 / 5 =", 10 / 5)
print("  10 // 5 =", 10 // 5)
print("  10 % 3 =", 10 % 3)
print("  2 ^ 3 =", 2 ^ 3)
print("  -10 =", -10)

-- Float arithmetic
print("\nFloat arithmetic:")
print("  3.5 + 2.5 =", 3.5 + 2.5)
print("  3.5 - 2.5 =", 3.5 - 2.5)
print("  3.5 * 2.0 =", 3.5 * 2.0)
print("  7.0 / 2.0 =", 7.0 / 2.0)
print("  7.5 % 2.0 =", 7.5 % 2.0)

-- Mixed int/float
print("\nMixed int/float:")
print("  10 + 2.5 =", 10 + 2.5)
print("  10 - 2.5 =", 10 - 2.5)
print("  10 * 2.5 =", 10 * 2.5)
print("  10 / 4 =", 10 / 4)

-- Comparison operators
print("\nComparison (numbers):")
print("  5 == 5 =", 5 == 5)
print("  5 ~= 5 =", 5 ~= 5)
print("  5 < 10 =", 5 < 10)
print("  5 > 10 =", 5 > 10)
print("  5 <= 5 =", 5 <= 5)
print("  5 >= 5 =", 5 >= 5)
print("  5 == 5.0 =", 5 == 5.0)

-- String comparison
print("\nComparison (strings):")
print("  'a' == 'a' =", "a" == "a")
print("  'a' ~= 'b' =", "a" ~= "b")
print("  'a' < 'b' =", "a" < "b")
print("  'abc' <= 'abc' =", "abc" <= "abc")

-- Logical operators
print("\nLogical operators:")
print("  true and true =", true and true)
print("  true and false =", true and false)
print("  false and true =", false and true)
print("  false and false =", false and false)
print("  true or true =", true or true)
print("  true or false =", true or false)
print("  false or true =", false or true)
print("  false or false =", false or false)
print("  not true =", not true)
print("  not false =", not false)

-- Logical short-circuit
print("\nLogical short-circuit:")
local a = 5
local b = 10
local result1 = (a > 3) and (b > 5)
print("  (5 > 3) and (10 > 5) =", result1)
local result2 = (a < 3) and (b > 5)
print("  (5 < 3) and (10 > 5) =", result2)
local result3 = (a > 3) or (b < 5)
print("  (5 > 3) or (10 < 5) =", result3)

-- Logical with values (truthiness test)
-- BUG: Only true is truthy
print("\nLogical with values:")
print("  5 and 10 =", 5 and 10)
print("  nil and 5 =", nil and 5)
print("  false and 5 =", false and 5)
print("  5 or 10 =", 5 or 10)
print("  nil or 5 =", nil or 5)
print("  false or 5 =", false or 5)

-- Concatenation operator
print("\nConcatenation:")
print("  'hello' .. 'world' =", "hello" .. "world")
print("  'num' .. 42 =", "num" .. 42)
print("  10 .. 20 =", 10 .. 20)
print("  'pi=' .. 3.14 =", "pi=" .. 3.14)

-- Length operator
print("\nLength operator:")
print("  #'hello' =", #"hello")
print("  #'a' =", #"a")
print("  #'' =", #"")
local arr = {1, 2, 3, 4, 5}
print("  #{1,2,3,4,5} =", #arr)
local empty = {}
print("  #{} =", #empty)

-- Operator precedence
print("\nOperator precedence:")
print("  2 + 3 * 4 =", 2 + 3 * 4)
print("  (2 + 3) * 4 =", (2 + 3) * 4)
print("  10 - 5 - 2 =", 10 - 5 - 2)
print("  10 / 2 / 5 =", 10 / 2 / 5)
print("  2 ^ 3 ^ 2 =", 2 ^ 3 ^ 2)
print("  -2 ^ 2 =", -2 ^ 2)
print("  (-2) ^ 2 =", (-2) ^ 2)

-- Unary minus
print("\nUnary minus:")
print("  -(5) =", -(5))
print("  -(-5) =", -(-5))
print("  -(2 + 3) =", -(2 + 3))
local x = 10
print("  -x (x=10) =", -x)

-- Modulo with negatives
print("\nModulo with negatives:")
print("  10 % 3 =", 10 % 3)
print("  -10 % 3 =", -10 % 3)
print("  10 % -3 =", 10 % -3)
print("  -10 % -3 =", -10 % -3)

-- Floor division
print("\nFloor division:")
print("  10 // 3 =", 10 // 3)
print("  -10 // 3 =", -10 // 3)
print("  10 // -3 =", 10 // -3)
print("  7 // 2 =", 7 // 2)
print("  7.5 // 2.0 =", 7.5 // 2.0)

-- Exponentiation
print("\nExponentiation:")
print("  2 ^ 0 =", 2 ^ 0)
print("  2 ^ 1 =", 2 ^ 1)
print("  2 ^ 8 =", 2 ^ 8)
print("  10 ^ 3 =", 10 ^ 3)
print("  4 ^ 0.5 =", 4 ^ 0.5)
print("  2 ^ -1 =", 2 ^ -1)

-- Comparison chaining (not valid in Lua but test each)
print("\nMultiple comparisons:")
local v = 5
local c1 = (v > 3)
local c2 = (v < 10)
print("  5 > 3 and 5 < 10 =", c1 and c2)

-- Not with comparisons
print("\nNot with comparisons:")
print("  not (5 > 3) =", not (5 > 3))
print("  not (5 < 3) =", not (5 < 3))
print("  not (5 == 5) =", not (5 == 5))

-- Equality with different types
print("\nEquality (different types):")
print("  5 == '5' =", 5 == "5")
print("  nil == false =", nil == false)
print("  0 == false =", 0 == false)
print("  '' == false =", "" == false)

-- Table equality
-- BUG: Table equality broken
print("\nTable equality:")
local t1 = {}
local t2 = {}
local t3 = t1
print("  {} == {} =", t1 == t2)
print("  t1 == t1 =", t1 == t1, "(BUG: should be true)")
print("  t1 == t3 (same ref) =", t1 == t3, "(BUG: should be true)")

-- Function equality
print("\nFunction equality:")
function func1() end
function func2() end
local func3 = func1
print("  func1 == func2 =", func1 == func2)
print("  func1 == func1 =", func1 == func1)
print("  func1 == func3 =", func1 == func3)

-- Operator in expressions
print("\nOperators in expressions:")
local sum = 10 + 20 + 30
print("  10 + 20 + 30 =", sum)
local product = 2 * 3 * 4
print("  2 * 3 * 4 =", product)
local mixed = 2 + 3 * 4 - 5
print("  2 + 3 * 4 - 5 =", mixed)

-- Comparison operators in conditions
print("\nComparison in conditions:")
if 5 > 3 then
  print("  5 > 3 is true ✓")
end
if 5 < 3 then
  print("  5 < 3 is true (should not print)")
else
  print("  5 < 3 is false ✓")
end

-- Logical operators in conditions
print("\nLogical in conditions:")
if true and true then
  print("  true and true ✓")
end
if true or false then
  print("  true or false ✓")
end
if not false then
  print("  not false ✓")
end

-- Complex boolean expressions
print("\nComplex boolean:")
local age = 25
local hasMembership = true
if age >= 18 and hasMembership then
  print("  age >= 18 and hasMembership ✓")
end
if age < 18 or not hasMembership then
  print("  age < 18 or not hasMembership (should not print)")
else
  print("  Else branch ✓")
end

-- Arithmetic with variables
print("\nArithmetic with variables:")
local p = 10
local q = 3
print("  p + q =", p + q)
print("  p - q =", p - q)
print("  p * q =", p * q)
print("  p / q =", p / q)
print("  p % q =", p % q)
print("  p ^ q =", p ^ q)

-- Compound expressions
print("\nCompound expressions:")
local r = (10 + 5) * (8 - 3)
print("  (10 + 5) * (8 - 3) =", r)
local s = ((10 + 5) * 2) - (8 / 4)
print("  ((10 + 5) * 2) - (8 / 4) =", s)

-- Operator with function calls
print("\nOperators with function calls:")
function getValue() return 10 end
print("  getValue() + 5 =", getValue() + 5)
print("  getValue() * 2 =", getValue() * 2)

-- Operator with table access
print("\nOperators with table access:")
local nums = {10, 20, 30}
print("  nums[1] + nums[2] =", nums[1] + nums[2])
print("  nums[3] - nums[1] =", nums[3] - nums[1])

print("\n=== Operator tests complete! ===")
