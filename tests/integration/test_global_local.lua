-- Test global vs local variable interactions
print("=== Global vs Local Variables ===")

-- Global variable
globalVar = 100
print("Global variable:")
print("  globalVar =", globalVar)

-- Local shadowing global
print("\nLocal shadowing global:")
local globalVar = 200
print("  local globalVar =", globalVar)

do
  print("  Inside block: globalVar =", globalVar)
end

-- After block
print("  After block: globalVar =", globalVar)

-- Accessing global from function
print("\nGlobal from function:")
function getGlobal()
  return globalVar
end
print("  getGlobal() =", getGlobal())

-- Modifying global from function
print("\nModifying global:")
function setGlobal(val)
  globalVar = val
end
setGlobal(300)
print("  After setGlobal(300): globalVar =", globalVar)

-- Local variable persisting after function
print("\nLocal in function:")
function makeLocal()
  local funcLocal = 42
  return funcLocal
end
print("  makeLocal() =", makeLocal())
-- print("  funcLocal outside =", funcLocal)  -- Would error

-- Multiple locals with same name
-- BUG: Inner local value persists after block ends!
print("\nMultiple locals:")
do
  local x = 1
  print("  Outer x =", x)
  do
    local x = 2
    print("    Inner x =", x)
  end
  print("  Outer x again =", x, "(BUG: should be 1, is 2)")
end

-- Global without explicit assignment
print("\nImplicit global:")
function createGlobal()
  implicitGlobal = 999
end
createGlobal()
print("  implicitGlobal =", implicitGlobal)

-- Local hides global in same scope
print("\nLocal declaration order:")
local y = 10
print("  local y =", y)
y = 20
print("  After y=20: y =", y)

-- Uninitialized local
print("\nUninitialized local:")
local uninit
print("  local uninit (no value) =", uninit)

-- Multiple local declaration
print("\nMultiple declaration:")
local a, b, c = 1, 2, 3
print("  a, b, c =", a, b, c)

local d, e = 4
print("  d, e (only 1 value) =", d, e)

local f, g = 5, 6, 7
print("  f, g (3 values) =", f, g)

print("\n=== Global vs local tests complete! ===")
