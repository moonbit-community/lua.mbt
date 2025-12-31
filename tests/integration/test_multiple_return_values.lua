-- Test multiple return values
function f()
  return 10, 20, 30
end

local x, y, z = f()
print("x:", x)
print("y:", y)
print("z:", z)

-- Test with 2 values
function g()
  return "hello", "world"
end

local a, b = g()
print("a:", a)
print("b:", b)
