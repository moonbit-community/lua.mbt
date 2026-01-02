-- Test nested closures with debugging

function outer(x)
  print("outer called with x =", x)
  return function(y)
    print("middle called with y =", y)
    print("x in middle =", x)
    return function(z)
      print("inner called with z =", z)
      print("x in inner =", x)
      print("y in inner =", y)
      local sum = x + y + z
      return sum
    end
  end
end

local f = outer(10)
local g = f(20)
local result = g(30)
print("result:", result)
