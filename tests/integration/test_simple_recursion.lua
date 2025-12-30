-- Test: Simple recursion
function test(n)
  if n == 0 then
    return 0
  end
  return test(n - 1)
end

local r = test(0)
