-- Test: Nested function calls
function add(a, b)
  return a + b
end

function multiply(a, b)
  return a * b
end

function compute(x)
  local a = add(x, 5)
  local b = multiply(a, 2)
  return b
end

local result = compute(10)
-- result should be (10 + 5) * 2 = 30
