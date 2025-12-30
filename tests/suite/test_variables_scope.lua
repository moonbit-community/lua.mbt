-- Test: Variable scoping
-- Tests local vs global variables and shadowing

-- Global variables
g1 = 10
g2 = 20
local l1 = g1 + g2

-- Local variables
local x = 5
local y = 10
local z = x + y

-- Local shadowing global
g3 = 100
function test()
  local g3 = 200  -- Shadows global g3
  return g3
end
local result = test()
-- result should be 200, g3 should still be 100

-- Nested scopes
local a = 1
if a == 1 then
  local a = 2  -- Shadows outer a
  local b = a
  -- b should be 2
end
-- a should still be 1

-- Scope in loops
local count = 0
for i = 1, 3 do
  local temp = i * 2
  count = count + temp
end
-- count should be 12, temp is out of scope

-- Function parameters shadow outer variables
local p = 10
function process(p)
  return p * 2
end
local r = process(5)
-- r should be 10, outer p should still be 10

-- Multiple locals
local v1, v2, v3 = 1, 2, 3
local sum = v1 + v2 + v3

-- Global modified in function
g4 = 1
function increment_global()
  g4 = g4 + 1
end
increment_global()
increment_global()
-- g4 should be 3
