-- Test table as dictionary/map
print("=== Table as Dictionary ===")

-- Create dictionary/map
local person = {
  name = "Alice",
  age = 30,
  city = "NYC"
}

print("person.name =", person.name)
print("person['age'] =", person["age"])

-- Add new fields
person.job = "Engineer"
person["hobby"] = "Reading"

print("person.job =", person.job)
print("person.hobby =", person.hobby)

-- Modify existing fields
person.age = 31
print("Updated age:", person.age)

-- Delete field (set to nil)
person.city = nil
print("After deleting city:", person.city)

-- Table with computed keys
local key = "favorite_color"
person[key] = "blue"
print("person.favorite_color =", person.favorite_color)

-- Dictionary of dictionaries
print("\nNested dictionaries:")
local contacts = {
  alice = {name = "Alice", phone = "123-4567"},
  bob = {name = "Bob", phone = "987-6543"}
}

print("contacts.alice.name =", contacts.alice.name)
print("contacts.bob.phone =", contacts.bob.phone)

-- Array vs dictionary
print("\nArray vs Dictionary:")
local arr = {10, 20, 30}  -- Array
local dict = {x = 10, y = 20, z = 30}  -- Dictionary

print("arr[1] =", arr[1])
print("dict.x =", dict.x)

-- Mixed array and dictionary (valid in Lua)
local mixed = {10, 20, x = "value"}
print("\nMixed table:")
print("mixed[1] =", mixed[1])
print("mixed.x =", mixed.x)

print("\n=== All table dictionary tests passed! ===")
