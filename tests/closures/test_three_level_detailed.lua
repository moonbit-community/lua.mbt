-- Test three-level closure with local assignments

function outer(x)
  print("outer: x =", x, type(x))
  return function(y)
    print("middle: y =", y, type(y))
    print("middle: x =", x, type(x))
    return function(z)
      print("inner: z =", z, type(z))
      print("inner: y =", y, type(y))
      print("inner: x =", x, type(x))

      -- Assign to locals
      local a = x
      local b = y
      local c = z

      print("inner: a =", a, type(a))
      print("inner: b =", b, type(b))
      print("inner: c =", c, type(c))

      local result = a + b + c
      print("inner: result =", result)
      return result
    end
  end
end

print("Creating outer(10)")
local f = outer(10)

print("Calling f(20)")
local g = f(20)

print("Calling g(30)")
local result = g(30)

print("Final result:", result)
