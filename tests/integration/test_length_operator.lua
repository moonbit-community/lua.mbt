-- Test length operator edge cases
print("=== Length Operator (#) ===")

-- String length
print("String length:")
print("  #'hello' =", #"hello")
print("  #'' =", #"")
print("  #'a b c' =", #"a b c")

-- Array length
print("\nArray length:")
local arr = {1, 2, 3, 4, 5}
print("  #{1,2,3,4,5} =", #arr)

-- Empty table
print("\nEmpty table:")
print("  #{} =", #{})

-- Table with nil holes
print("\nTable with nil:")
local holey = {1, 2, nil, 4, 5}
print("  #{1,2,nil,4,5} =", #holey)

-- Table with only hash keys
print("\nHash-only table:")
local hash = {a = 1, b = 2}
print("  #{a=1, b=2} =", #hash)

-- Mixed table
print("\nMixed table:")
local mixed = {1, 2, 3, x = 10}
print("  #{1,2,3,x=10} =", #mixed)

-- After removing last element
print("\nAfter removing last:")
local arr2 = {1, 2, 3}
arr2[3] = nil
print("  After arr[3]=nil, #arr =", #arr2)

-- After adding element
print("\nAfter adding:")
local arr3 = {1, 2, 3}
arr3[4] = 4
print("  After arr[4]=4, #arr =", #arr3)

-- Large array
print("\nLarge array:")
local large = {}
for i = 1, 100 do
  large[i] = i
end
print("  #(array with 100 elements) =", #large)

-- Sparse array
print("\nSparse array:")
local sparse = {}
sparse[1] = "a"
sparse[100] = "b"
print("  #{[1]='a', [100]='b'} =", #sparse)

print("\n=== Length operator tests complete! ===")
