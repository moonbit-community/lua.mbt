-- Test: Factorial with while loop
function factorial(n)
  local result = 1
  local i = 1
  while i <= n do
    result = result * i
    i = i + 1
  end
  return result
end

local f5 = factorial(5)
-- f5 should be 120
