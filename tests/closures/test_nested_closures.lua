-- Test nested closures

function outer(x)
  return function(y)
    return function(z)
      return x + y + z  -- Capture from multiple levels
    end
  end
end

local f = outer(10)
local g = f(20)
local result = g(30)
print(result)  -- Should print 60
