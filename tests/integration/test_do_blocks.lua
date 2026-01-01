-- Test do...end blocks comprehensively
print("=== Do-End Blocks ===")

-- Simple do block
print("Simple do block:")
do
  print("  Inside do block")
end
print("  After do block")

-- Do block with local
print("\nDo with local:")
do
  local x = 42
  print("  Inside: x =", x)
end
-- print("  Outside: x =", x)  -- Would error

-- Nested do blocks
print("\nNested do blocks:")
do
  print("  Outer do")
  do
    print("    Inner do")
    do
      print("      Innermost do")
    end
  end
end

-- Do block in function
print("\nDo in function:")
local function testDo()
  do
    local temp = 100
    print("  temp in do:", temp)
  end
  print("  After do block")
end
testDo()

-- Multiple do blocks
print("\nMultiple do blocks:")
do
  local a = 1
  print("  First do: a =", a)
end
do
  local a = 2
  print("  Second do: a =", a)
end

-- Do block with shadowing
-- BUG: Inner local values may persist after block ends
print("\nShadowing in do:")
local value = 10
do
  local value = 20
  print("  Inner value =", value)
end
print("  Outer value =", value, "(BUG: may be wrong)")

-- Do block modifying outer variable
print("\nModifying outer var:")
local counter = 0
do
  counter = counter + 1
  print("  counter in do =", counter)
end
print("  counter after do =", counter)

-- Empty do block
print("\nEmpty do:")
do
end
print("  After empty do")

-- Do with multiple statements
print("\nDo with statements:")
do
  local a = 5
  local b = 10
  local c = a + b
  print("  a + b =", c)
end

-- Do with return (in function)
print("\nDo with return:")
local function earlyReturn(x)
  do
    if x > 0 then
      return "positive"
    end
  end
  return "not positive"
end
print("  earlyReturn(5) =", earlyReturn(5))

-- Do with break (in loop)
print("\nDo with break:")
for i = 1, 10 do
  do
    if i == 3 then
      break
    end
    print("  i =", i)
  end
end

-- Do in if
print("\nDo in if:")
if true then
  do
    print("  Inside if-do")
  end
end

-- Do in loop
print("\nDo in loop:")
for i = 1, 2 do
  do
    print("  Loop", i, "- inside do")
  end
end

-- Scope with do blocks
print("\nScope isolation:")
do
  local x = "first"
  print("  First do: x =", x)
end
do
  local x = "second"
  print("  Second do: x =", x)
end

-- Do with table operations
print("\nDo with table:")
do
  local t = {a = 1, b = 2}
  print("  t.a, t.b =", t.a, t.b)
end

-- Do with function declaration
print("\nDo with function:")
do
  local function helper()
    return 99
  end
  print("  helper() =", helper())
end

-- Deeply nested do blocks
print("\nDeeply nested:")
do
  do
    do
      do
        print("  Very deep!")
      end
    end
  end
end

-- Do with conditional
print("\nDo with conditional:")
do
  local x = 10
  if x > 5 then
    print("  x > 5 in do block")
  end
end

print("\n=== Do-end tests complete! ===")
