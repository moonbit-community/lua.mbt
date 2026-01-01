-- Test generic for loops with pairs and ipairs
-- BUG: pairs() and ipairs() are NOT IMPLEMENTED
-- The for loop syntax compiles but pairs/ipairs return nothing
-- so the loop bodies never execute
print("=== Generic For Loops ===")

-- ipairs for array iteration
-- NOTE: This will not print anything because ipairs() is not implemented
print("ipairs iteration:")
local arr = {10, 20, 30, 40}
for i, v in ipairs(arr) do
  print("  arr[" .. i .. "] =", v)
end

-- pairs for table iteration
print("\npairs iteration:")
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  print("  t[" .. k .. "] =", v)
end

-- Mixed table (array + hash)
print("\nMixed table:")
local mixed = {10, 20, x = "hello", y = "world"}
print("With ipairs (array part only):")
for i, v in ipairs(mixed) do
  print("  [" .. i .. "] =", v)
end

print("With pairs (all elements):")
for k, v in pairs(mixed) do
  print("  [" .. k .. "] =", v)
end

-- Empty table
print("\nEmpty table:")
for k, v in pairs({}) do
  print("  Should not print")
end
print("  (correctly empty)")

-- Nested iteration
print("\nNested iteration:")
local matrix = {{1, 2}, {3, 4}, {5, 6}}
for i, row in ipairs(matrix) do
  for j, val in ipairs(row) do
    print("  matrix[" .. i .. "][" .. j .. "] =", val)
  end
end

print("\n=== Generic for tests complete! ===")
