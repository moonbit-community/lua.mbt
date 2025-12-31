-- Test table operations (without table library)
print("=== Table Operations ===")

-- Array operations
local arr = {3, 1, 4, 1, 5, 9, 2, 6}

print("Original array:")
for i = 1, #arr do
  print("  arr[" .. i .. "] =", arr[i])
end
print("  Length: #arr =", #arr)

-- Append to array
print("\nAppending to array:")
arr[#arr + 1] = 99
print("  After arr[#arr + 1] = 99:")
print("  #arr =", #arr)
print("  arr[" .. #arr .. "] =", arr[#arr])

-- Prepend (shift all elements)
print("\nManual prepend:")
local new_arr = {0}
for i = 1, 3 do
  new_arr[i + 1] = i * 10
end
for i = 1, #new_arr do
  print("  new_arr[" .. i .. "] =", new_arr[i])
end

-- Remove last element
print("\nRemoving last element:")
arr[#arr] = nil
print("  After arr[#arr] = nil:")
print("  #arr =", #arr)

-- Sparse tables
print("\nSparse table:")
local sparse = {}
sparse[1] = "first"
sparse[5] = "fifth"
sparse[10] = "tenth"
print("  sparse[1] =", sparse[1])
print("  sparse[5] =", sparse[5])
print("  sparse[10] =", sparse[10])
print("  #sparse =", #sparse)

-- Table as stack
print("\nTable as stack:")
local stack = {}
-- Push
stack[#stack + 1] = "a"
stack[#stack + 1] = "b"
stack[#stack + 1] = "c"
print("  After pushing a, b, c:")
print("  #stack =", #stack)
-- Pop
local top = stack[#stack]
stack[#stack] = nil
print("  Popped:", top)
print("  #stack =", #stack)

-- Multi-dimensional arrays
print("\nMulti-dimensional array:")
local matrix = {
  {1, 2, 3},
  {4, 5, 6},
  {7, 8, 9}
}
print("  matrix[2][2] =", matrix[2][2])
print("  matrix[3][1] =", matrix[3][1])

-- Modify nested
matrix[1][1] = 99
print("  After matrix[1][1] = 99:")
print("  matrix[1][1] =", matrix[1][1])

print("\n=== All table operation tests passed! ===")
