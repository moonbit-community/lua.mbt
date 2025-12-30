-- Test: Two global functions calling each other
function add(a, b)
  return a + b
end

local result = add(3, 4)
