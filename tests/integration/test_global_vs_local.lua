-- Test global vs local variables comprehensively
print("=== Global vs Local Variables ===")

-- Global variable
print("Global variables:")
globalOne = 100
print("  globalOne =", globalOne)

-- Access global from function
print("\nGlobal from function:")
local function useGlobal()
  return globalOne * 2
end
print("  useGlobal() =", useGlobal())

-- Modify global from function
print("\nModify global:")
local function modifyGlobal()
  globalOne = 200
end
modifyGlobal()
print("  After modify: globalOne =", globalOne)

-- Local variable
print("\nLocal variable:")
local localOne = 50
print("  localOne =", localOne)

-- Local shadowing global
print("\nLocal shadows global:")
globalTwo = 10
do
  local globalTwo = 20
  print("  In block: globalTwo =", globalTwo)
end
print("  Outside: globalTwo =", globalTwo)

-- Function local variables
print("\nFunction locals:")
local function testLocals()
  local funcVar = 99
  print("  Inside: funcVar =", funcVar)
  return funcVar
end
local result = testLocals()
print("  Returned:", result)
-- print("  Outside: funcVar =", funcVar)  -- Would error

-- Global assignment without local
print("\nImplicit global:")
implicitGlobal = 777
print("  implicitGlobal =", implicitGlobal)

-- Check if global exists
print("\nCheck global exists:")
local function checkGlobal(name)
  if globalOne then
    return "exists"
  else
    return "doesn't exist"
  end
end
print("  globalOne:", checkGlobal())

-- Multiple globals
print("\nMultiple globals:")
g1 = 1
g2 = 2
g3 = 3
print("  g1, g2, g3 =", g1, g2, g3)

-- Multiple locals
print("\nMultiple locals:")
local l1 = 10
local l2 = 20
local l3 = 30
print("  l1, l2, l3 =", l1, l2, l3)

-- Global in table
print("\nGlobal in table:")
globalTable = {a = 1, b = 2}
print("  globalTable.a =", globalTable.a)

-- Local in table
print("\nLocal in table:")
local localTable = {x = 10, y = 20}
print("  localTable.x =", localTable.x)

-- Nested scope locals
print("\nNested locals:")
local outer = "outer"
do
  local inner = "inner"
  print("  inner scope:", outer, inner)
end
print("  outer scope:", outer)

-- Global accessed from nested function
print("\nNested function access:")
sharedGlobal = 42
local function outer()
  local function inner()
    return sharedGlobal
  end
  return inner()
end
print("  outer() =", outer())

-- Local parameter
print("\nFunction parameters:")
local function withParams(param)
  print("  param =", param)
  local localParam = param * 2
  print("  localParam =", localParam)
end
withParams(5)

-- Global modified in loop
print("\nGlobal in loop:")
loopGlobal = 0
for i = 1, 3 do
  loopGlobal = loopGlobal + i
end
print("  loopGlobal =", loopGlobal)

-- Local in loop
print("\nLocal in loop:")
local loopLocal = 0
for i = 1, 3 do
  loopLocal = loopLocal + i
end
print("  loopLocal =", loopLocal)

-- Redefining local
print("\nRedefining local:")
local redefined = 1
print("  First: redefined =", redefined)
local redefined = 2
print("  Second: redefined =", redefined)

-- Global vs local with same name
-- BUG: Local value persists after block ends
print("\nSame name:")
sameName = "global"
do
  local sameName = "local"
  print("  In block:", sameName)
end
print("  Outside:", sameName, "(BUG: should be 'global', is 'local')")

-- Assignment priority
print("\nAssignment priority:")
priority = 100
local function testPriority()
  local priority = 200
  print("  In function:", priority)
end
testPriority()
print("  Outside:", priority)

-- Global function
print("\nGlobal function:")
function globalFunc()
  return "global function"
end
print("  globalFunc() =", globalFunc())

-- Local function
print("\nLocal function:")
local function localFunc()
  return "local function"
end
print("  localFunc() =", localFunc())

-- Global variable from different scope
print("\nCross-scope global:")
do
  crossScope = "defined in block"
end
print("  crossScope =", crossScope)

-- Local doesn't leak
print("\nLocal doesn't leak:")
do
  local leaked = "should not leak"
end
-- print("  leaked =", leaked)  -- Would error
print("  (local correctly doesn't leak)")

-- Global array
print("\nGlobal array:")
globalArray = {1, 2, 3}
print("  globalArray[1] =", globalArray[1])

-- Accessing undefined global
-- BUG: Throws error instead of returning nil
print("\nUndefined global:")
-- print("  undefinedGlobal =", undefinedGlobal)  -- Throws error
print("  (Accessing undefined global throws error, should return nil)")

-- Setting global to nil
print("\nGlobal to nil:")
globalNil = 5
print("  Before: globalNil =", globalNil)
globalNil = nil
print("  After: globalNil =", globalNil)

-- Local persists in scope
print("\nLocal persistence:")
local persistent = 1
for i = 1, 3 do
  persistent = persistent + 1
  print("  iteration", i, ": persistent =", persistent)
end

-- Global in condition
print("\nGlobal in condition:")
condGlobal = true
if condGlobal then
  print("  condGlobal is truthy")
end

-- Multiple assignment global
print("\nMultiple global assign:")
ga, gb, gc = 10, 20, 30
print("  ga, gb, gc =", ga, gb, gc)

-- Multiple assignment local
print("\nMultiple local assign:")
local la, lb, lc = 100, 200, 300
print("  la, lb, lc =", la, lb, lc)

-- Global modification chains
print("\nGlobal chains:")
chain = 1
chain = chain + 1
chain = chain * 2
print("  chain =", chain)

print("\n=== Global vs local tests complete! ===")
