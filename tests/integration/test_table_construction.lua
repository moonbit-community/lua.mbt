-- Test table construction patterns
print("=== Table Construction ===")

-- Array-style construction
local arr1 = {1, 2, 3, 4, 5}
print("Array: {1, 2, 3, 4, 5}")
print("  #arr1 =", #arr1)
print("  arr1[3] =", arr1[3])

-- Dictionary-style construction
local dict1 = {x = 10, y = 20, z = 30}
print("\nDictionary: {x=10, y=20, z=30}")
print("  dict1.x =", dict1.x)
print("  dict1.y =", dict1.y)

-- Mixed construction
local mixed1 = {10, 20, name = "test", 30}
print("\nMixed: {10, 20, name='test', 30}")
print("  mixed1[1] =", mixed1[1])
print("  mixed1[2] =", mixed1[2])
print("  mixed1.name =", mixed1.name)
print("  mixed1[3] =", mixed1[3])

-- Nested construction
local nested = {
  point = {x = 5, y = 10},
  colors = {"red", "green", "blue"}
}
print("\nNested tables:")
print("  nested.point.x =", nested.point.x)
print("  nested.colors[2] =", nested.colors[2])

-- Empty table
local empty = {}
print("\nEmpty table:")
print("  #empty =", #empty)

-- Table with string keys
local scores = {
  ["player1"] = 100,
  ["player2"] = 200
}
print("\nString keys:")
print("  scores['player1'] =", scores["player1"])

-- Table with computed indices
local data = {}
for i = 1, 5 do
  data[i] = i * 10
end
print("\nComputed indices:")
for i = 1, 5 do
  print("  data[" .. i .. "] =", data[i])
end

-- Table with gaps
local sparse = {[1] = "a", [5] = "b", [10] = "c"}
print("\nSparse table:")
print("  sparse[1] =", sparse[1])
print("  sparse[5] =", sparse[5])
print("  sparse[2] =", sparse[2])

print("\n=== All table construction tests passed! ===")
