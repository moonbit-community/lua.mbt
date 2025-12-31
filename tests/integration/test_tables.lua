-- Test table operations
local t = {10, 20, 30}
print("t[1] =", t[1])
print("t[2] =", t[2])
print("t[3] =", t[3])

-- Test table with string keys
local person = {name = "John", age = 30}
print("Name:", person.name)
print("Age:", person.age)

-- Test table length
print("Length of t:", #t)

-- Test table assignment
t[1] = 100
print("After t[1] = 100, t[1] =", t[1])
