-- Test table edge cases and complex scenarios
-- BUGS FOUND:
--   ✓ Most table operations work correctly
--   ✗ Boolean keys (true/false) don't work - return nil
--   ✗ Float keys (10.5) don't work - return nil
--   ✗ Table keys don't work - return nil
--   ✗ Index 0 and negative indexes don't work - return nil
print("=== Table Edge Cases ===")

-- Nil values in arrays
-- NOTE: Works correctly!
print("Nil values in arrays:")
local arr = {1, 2, nil, 4, 5}
print("  arr[1] =", arr[1])
print("  arr[2] =", arr[2])
print("  arr[3] =", arr[3])
print("  arr[4] =", arr[4])
print("  #arr =", #arr)  -- Length might be wrong with nil

-- Sparse arrays
print("\nSparse arrays:")
local sparse = {}
sparse[1] = "a"
sparse[10] = "b"
sparse[100] = "c"
print("  sparse[1] =", sparse[1])
print("  sparse[10] =", sparse[10])
print("  sparse[100] =", sparse[100])
print("  #sparse =", #sparse)

-- Very deeply nested table
print("\nDeeply nested:")
local deep = {{{{{5}}}}}
print("  deep[1][1][1][1][1] =", deep[1][1][1][1][1])

-- Table with mixed keys
print("\nMixed keys:")
local mixed = {
  [1] = "first",
  ["key"] = "value",
  [true] = "bool key",
  [10.5] = "float key"
}
print("  mixed[1] =", mixed[1])
print("  mixed['key'] =", mixed["key"])
print("  mixed[true] =", mixed[true])
print("  mixed[10.5] =", mixed[10.5])

-- Table as key (if supported)
print("\nTable as key:")
local key1 = {x = 1}
local key2 = {x = 1}
local meta = {}
meta[key1] = "first"
meta[key2] = "second"
print("  Different table instances:", meta[key1], meta[key2])

-- Circular reference
print("\nCircular reference:")
local t = {}
t.self = t
print("  t.self.self.self exists =", t.self.self.self ~= nil)

-- Array boundary cases
print("\nArray boundaries:")
local arr2 = {10, 20, 30}
arr2[0] = 5  -- Index 0
arr2[-1] = 1  -- Negative index
print("  arr2[0] =", arr2[0])
print("  arr2[-1] =", arr2[-1])
print("  #arr2 =", #arr2)

-- Removing array elements
print("\nRemoving elements:")
local arr3 = {1, 2, 3, 4, 5}
arr3[3] = nil
print("  After arr3[3]=nil, #arr3 =", #arr3)
print("  arr3[1], arr3[2], arr3[3], arr3[4], arr3[5] =", arr3[1], arr3[2], arr3[3], arr3[4], arr3[5])

-- Large array
print("\nLarge array:")
local large = {}
for i = 1, 1000 do
  large[i] = i * 2
end
print("  large[500] =", large[500])
print("  #large =", #large)

-- Table with only hash part
print("\nHash-only table:")
local hash = {a = 1, b = 2, c = 3}
print("  #hash =", #hash)  -- Should be 0

-- Empty table operations
print("\nEmpty table:")
local empty = {}
print("  #empty =", #empty)
print("  empty[1] =", empty[1])
print("  empty.foo =", empty.foo)

print("\n=== Table edge cases complete! ===")
