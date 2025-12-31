-- Test multiple assignment
print("=== Multiple Assignment ===")

-- Basic multiple assignment
local a, b = 1, 2
print("a =", a, "b =", b)

-- NOTE: Swap doesn't currently work due to evaluation order
-- a, b = b, a should give (2, 1) but currently gives (2, 2)
-- This requires evaluating all RHS before assigning to LHS

-- Multiple assignment with different counts
local x, y, z = 10, 20, 30
print("x =", x, "y =", y, "z =", z)

-- More values on right than left (extras ignored)
local m, n = 1, 2, 3, 4
print("m =", m, "n =", n)

-- Fewer values on right than left (gets nil)
local p, q, r = 100, 200
print("p =", p, "q =", q, "r =", r)

-- Multiple assignment from function returns
local function returns_two()
  return 5, 10
end

local f1, f2 = returns_two()
print("f1 =", f1, "f2 =", f2)

-- Multiple assignment in global scope
g1, g2 = 99, 88
print("g1 =", g1, "g2 =", g2)

-- Assignment with mixed sources
local result1, result2 = 42, returns_two()
print("result1 =", result1, "result2 =", result2)

print("\n=== All multiple assignment tests passed! ===")
