-- Test table library functions
-- CRITICAL BUG: table library is NOT IMPLEMENTED
-- Global 'table' does not exist
-- All table.* functions will fail with "Failed to get global 'table'"
print("=== Table Library Functions ===")

-- table.insert
-- NOTE: This will error because table library is not available
print("table.insert:")
local arr = {10, 20, 30}
table.insert(arr, 40)
print("  After insert(arr, 40):", arr[1], arr[2], arr[3], arr[4])

table.insert(arr, 2, 15)  -- Insert at position 2
print("  After insert(arr, 2, 15):", arr[1], arr[2], arr[3], arr[4], arr[5])

-- table.remove
print("\ntable.remove:")
local removed = table.remove(arr)  -- Remove last
print("  Removed:", removed)
print("  After remove():", arr[1], arr[2], arr[3], arr[4])

removed = table.remove(arr, 2)  -- Remove at position 2
print("  Removed at pos 2:", removed)
print("  After remove(2):", arr[1], arr[2], arr[3])

-- table.concat
print("\ntable.concat:")
local words = {"hello", "world", "lua"}
print("  concat(words):", table.concat(words))
print("  concat(words, ' '):", table.concat(words, " "))
print("  concat(words, '-'):", table.concat(words, "-"))

local nums = {1, 2, 3, 4, 5}
print("  concat(nums, ','):", table.concat(nums, ","))

-- table.sort
print("\ntable.sort:")
local unsorted = {5, 2, 8, 1, 9, 3}
table.sort(unsorted)
print("  After sort:", unsorted[1], unsorted[2], unsorted[3], unsorted[4], unsorted[5], unsorted[6])

-- table.sort with custom comparator
local desc = {5, 2, 8, 1, 9, 3}
table.sort(desc, function(a, b) return a > b end)
print("  Descending:", desc[1], desc[2], desc[3], desc[4], desc[5], desc[6])

-- table.pack (Lua 5.2+)
print("\ntable.pack:")
local packed = table.pack(10, 20, 30)
print("  packed[1] =", packed[1])
print("  packed[2] =", packed[2])
print("  packed[3] =", packed[3])
print("  packed.n =", packed.n)

-- table.unpack (Lua 5.2+) / unpack (Lua 5.1)
print("\ntable.unpack:")
local a, b, c = table.unpack({100, 200, 300})
print("  a, b, c =", a, b, c)

print("\n=== Table library tests complete! ===")
