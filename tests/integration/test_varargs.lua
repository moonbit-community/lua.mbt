-- Test variable arguments (...)
-- CRITICAL BUG: Varargs ALL BECOME NIL
-- The ... syntax is parsed and compiled correctly
-- But all values passed as varargs come through as nil
-- This makes varargs completely non-functional
-- Also: select() function is not implemented
print("=== Variable Arguments ===")

-- Basic varargs
-- NOTE: All varargs will be nil due to implementation bug
print("Basic varargs:")
local function printArgs(...)
  local args = {...}
  for i = 1, #args do
    print("  arg[" .. i .. "] =", args[i])
  end
end

printArgs(10, 20, 30)
printArgs("hello", "world")

-- Varargs with named parameters
print("\nVarargs with named params:")
local function greet(greeting, ...)
  print("  " .. greeting .. ":")
  local names = {...}
  for i = 1, #names do
    print("    " .. names[i])
  end
end

greet("Hello", "Alice", "Bob", "Charlie")

-- Counting varargs
print("\nCounting varargs:")
local function countArgs(...)
  return select("#", ...)
end

print("  countArgs(1, 2, 3) =", countArgs(1, 2, 3))
print("  countArgs('a', 'b') =", countArgs("a", "b"))

-- Forwarding varargs
print("\nForwarding varargs:")
local function wrapper(...)
  return printArgs(...)
end

wrapper(100, 200, 300)

-- Select with varargs
print("\nselect with varargs:")
local function demo(...)
  print("  select(2, ...) =", select(2, ...))
  print("  select(3, ...) =", select(3, ...))
end

demo(10, 20, 30, 40)

-- Varargs in return
print("\nVarargs in return:")
local function multiReturn(...)
  return ...
end

local a, b, c = multiReturn(1, 2, 3)
print("  a, b, c =", a, b, c)

-- Empty varargs
print("\nEmpty varargs:")
local function emptyArgs(...)
  local args = {...}
  print("  #args =", #args)
end

emptyArgs()

print("\n=== Varargs tests complete! ===")
