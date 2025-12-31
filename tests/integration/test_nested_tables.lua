-- Test nested tables and complex table operations
print("=== Nested Tables ===")

-- Simple nested table
local matrix = {
  {1, 2, 3},
  {4, 5, 6},
  {7, 8, 9}
}

print("matrix[2][2] =", matrix[2][2])
print("matrix[1][3] =", matrix[1][3])

-- Table with mixed types
local person = {
  name = "Alice",
  age = 30,
  hobbies = {"reading", "coding", "music"}
}

print("\nPerson:", person.name)
print("First hobby:", person.hobbies[1])
print("Second hobby:", person.hobbies[2])

-- Modifying nested tables
matrix[1][1] = 99
print("\nAfter modification:")
print("matrix[1][1] =", matrix[1][1])

-- Creating tables dynamically
local data = {}
data.x = 10
data.y = 20
data.point = {x = 5, y = 15}

print("\nDynamic table:")
print("data.x =", data.x)
print("data.point.x =", data.point.x)
print("data.point.y =", data.point.y)

print("\n=== All nested table tests passed! ===")
