-- Test: One function calling another
function add(a, b)
  return a + b
end

function twice(n)
  return add(n, n)
end

local result = twice(5)
