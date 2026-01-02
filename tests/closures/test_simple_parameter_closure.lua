-- Test single level closure with parameter

function makeAdder(x)
  return function(y)
    print("x type:", type(x))
    print("x value:", x)
    print("y type:", type(y))
    print("y value:", y)
    return x + y
  end
end

local add5 = makeAdder(5)
local result = add5(10)
print("result:", result)
