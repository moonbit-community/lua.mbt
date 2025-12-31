-- Test table methods and object-oriented style programming

print("=== Table Methods ===")

-- Create a table with data
local person = {
  name = "Alice",
  age = 30,
  city = "New York"
}

-- Method that takes self explicitly
function person.greet(self)
  print("Hello, my name is " .. self.name)
end

function person.getAge(self)
  return self.age
end

-- Call methods explicitly passing self
person.greet(person)
print("Age:", person.getAge(person))

-- Using colon syntax for method definition
function person:introduce()
  print("I am " .. self.name .. " and I am " .. self.age .. " years old")
end

function person:celebrateBirthday()
  self.age = self.age + 1
  print(self.name .. " is now " .. self.age .. " years old!")
end

-- Call methods using colon syntax (automatically passes self)
person:introduce()
person:celebrateBirthday()

print("\n=== Object-Oriented Style ===")

-- Create multiple "instances"
local alice = {
  name = "Alice",
  age = 25
}

local bob = {
  name = "Bob",
  age = 30
}

-- Shared method
local function sayHello(self)
  print(self.name .. " says: Hello!")
end

alice.sayHello = sayHello
bob.sayHello = sayHello

alice:sayHello()
bob:sayHello()

print("\n=== Table with Nested Methods ===")

local calculator = {
  value = 0
}

function calculator:add(n)
  self.value = self.value + n
  return self
end

function calculator:multiply(n)
  self.value = self.value * n
  return self
end

function calculator:getValue()
  return self.value
end

-- Method chaining
calculator:add(10)
calculator:multiply(5)
print("Result:", calculator:getValue())

-- Reset and chain in one line
calculator.value = 0
local result = calculator:add(3):add(7):multiply(2):getValue()
print("Chained result:", result)

print("\n=== All table method tests passed! ===")
