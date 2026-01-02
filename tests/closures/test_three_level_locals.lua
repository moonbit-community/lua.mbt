-- Test three-level closure with direct returns

function outer(x)
  return function(y)
    return function(z)
      local a = x
      local b = y
      local c = z
      return a + b + c
    end
  end
end

local f = outer(10)
local g = f(20)
local result = g(30)
print("result:", result)
