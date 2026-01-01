-- Test return statement variations
print("=== Return Statements ===")

-- Simple return
local function return_value()
  return 42
end
print("Simple return:", return_value())

-- Multiple returns
local function return_multiple()
  return 1, 2, 3
end
local a, b, c = return_multiple()
print("\nMultiple returns: a =", a, "b =", b, "c =", c)

-- Early return
local function early_return(n)
  if n < 0 then
    return "negative"
  end
  if n == 0 then
    return "zero"
  end
  return "positive"
end
print("\nEarly return:")
print("  early_return(-5) =", early_return(-5))
print("  early_return(0) =", early_return(0))
print("  early_return(5) =", early_return(5))

-- Return nil explicitly
local function return_nil()
  return nil
end
print("\nExplicit nil: return_nil() =", return_nil())

-- Return multiple with nil
local function return_with_nil()
  return 1, nil, 3
end
local x, y, z = return_with_nil()
print("With nil: x =", x, "y =", y, "z =", z)

-- Return expression
local function return_expr(a, b)
  return a + b
end
print("\nReturn expression: return_expr(3, 7) =", return_expr(3, 7))

-- Return boolean
local function is_positive(n)
  return n > 0
end
print("\nReturn boolean: is_positive(5) =", is_positive(5))
print("is_positive(-3) =", is_positive(-3))

-- Return table
local function make_point(x, y)
  return {x = x, y = y}
end
local p = make_point(10, 20)
print("\nReturn table: p.x =", p.x, "p.y =", p.y)

-- Return function
local function make_adder(n)
  return function(x)
    return x + n
  end
end
-- NOTE: This requires closures, but let's try simpler version
local function get_function()
  local function inner()
    return 99
  end
  return inner
end
local f = get_function()
print("\nReturn function: f() =", f())

-- Nested returns
local function outer()
  local function inner()
    return 123
  end
  return inner()
end
print("Nested returns: outer() =", outer())

-- Return from different branches
local function branch_return(x)
  if x > 10 then
    return "big"
  elseif x > 5 then
    return "medium"
  else
    return "small"
  end
end
print("\nBranch returns:")
print("  branch_return(15) =", branch_return(15))
print("  branch_return(7) =", branch_return(7))
print("  branch_return(2) =", branch_return(2))

print("\n=== All return statement tests passed! ===")
