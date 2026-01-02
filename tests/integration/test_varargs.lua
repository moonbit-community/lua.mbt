-- Test variable arguments (...)
-- FIXED: Varargs now work correctly for both pure varargs and named params + varargs!
print("=== Variable Arguments ===")

-- Basic varargs - direct print
print("Basic varargs (direct print):")
function printArgs(...)
  print("  Args:", ...)
end

printArgs(10, 20, 30)
printArgs("hello", "world")

-- Varargs with named parameters
print("\nVarargs with named params:")
function greet(greeting, ...)
  print("  " .. greeting .. ":", ...)
end

greet("Hello", "Alice", "Bob", "Charlie")
greet("Hi", "World")

-- Forwarding varargs to another function
print("\nForwarding varargs:")
function wrapper(...)
  printArgs(...)
end

wrapper(100, 200, 300)

-- Multiple named params + varargs
print("\nMultiple named params + varargs:")
function process(a, b, ...)
  print("  Fixed: a=" .. a .. ", b=" .. b)
  print("  Varargs:", ...)
end

process(1, 2, 3, 4, 5)
process(10, 20)

-- Varargs in return (passing through)
print("\nVarargs in return:")
function multiReturn(...)
  return ...
end

x, y, z = multiReturn(100, 200, 300)
print("  x, y, z =", x, y, z)

-- Empty varargs
print("\nEmpty varargs:")
function emptyArgs(...)
  print("  Called with empty varargs")
end

emptyArgs()

-- Different types in varargs
print("\nMixed types in varargs:")
function mixedArgs(...)
  print("  Mixed:", ...)
end

mixedArgs(1, "two", true, nil, 5.5)

print("\n=== Varargs tests complete! ===")
