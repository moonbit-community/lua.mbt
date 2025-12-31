-- Test do-end blocks
print("=== Do-End Blocks ===")

-- Basic do-end block
do
  local x = 42
  print("Inside do-end: x =", x)
end

-- Multiple statements in do-end
do
  local a = 1
  local b = 2
  local c = a + b
  print("a + b =", c)
end

-- Nested do-end blocks
print("\nNested blocks:")
do
  local outer = "outer"
  print("Outer block:", outer)

  do
    local inner = "inner"
    print("Inner block:", inner)
    print("Can access outer:", outer)
  end

  print("Back in outer:", outer)
end

-- Do-end for limiting scope
print("\nUsing do-end to limit scope:")
local result = 0

do
  local temp1 = 10
  local temp2 = 20
  result = temp1 + temp2
end

print("result =", result)
-- temp1 and temp2 are out of scope now

-- Do-end with early exit (break not valid here)
print("\nDo-end with conditional logic:")
do
  local val = 15

  if val > 10 then
    print("val is greater than 10")
  else
    print("val is 10 or less")
  end
end

-- Empty do-end block
print("\nEmpty do-end:")
do
end
print("After empty block")

print("\n=== All do-end block tests passed! ===")
