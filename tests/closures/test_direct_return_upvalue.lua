-- Test direct return of upvalue expression

function outer(x)
  return function(y)
    return x + y  -- Direct return of upvalue expression
  end
end

local f = outer(10)
local result = f(20)
print("result:", result)
