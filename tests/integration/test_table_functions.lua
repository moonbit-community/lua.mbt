-- Test: Functions that manipulate tables
function create_table(n)
  local t = {}
  for i = 1, n do
    t[i] = i * i
  end
  return t
end

function sum_table(t, n)
  local total = 0
  for i = 1, n do
    total = total + t[i]
  end
  return total
end

local squares = create_table(5)
local result = sum_table(squares, 5)
-- result should be 1 + 4 + 9 + 16 + 25 = 55
