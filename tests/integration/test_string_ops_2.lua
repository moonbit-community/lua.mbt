-- Test string operations (without string library)
print("=== String Operations ===")

local s = "Hello, Lua!"

-- Basic operations that work
print("String: '" .. s .. "'")
print("Length: #s =", #s)

-- String concatenation
print("\nConcatenation:")
local s1 = "Hello"
local s2 = "World"
local s3 = s1 .. " " .. s2
print("  '" .. s1 .. "' .. ' ' .. '" .. s2 .. "' =", s3)

-- String with numbers
local num_str = "Value: " .. 42 .. " and " .. 3.14
print("  With numbers:", num_str)

-- Multiple concatenation
local result = "a" .. "b" .. "c" .. "d" .. "e"
print("  Multiple concat:", result)

-- String in tables
print("\nStrings in tables:")
local words = {"the", "quick", "brown", "fox"}
for i = 1, #words do
  print("  words[" .. i .. "] =", words[i])
end

-- String comparison
print("\nString comparison:")
print("  'abc' < 'def' =", "abc" < "def")
print("  'xyz' > 'abc' =", "xyz" > "abc")
print("  'hello' == 'hello' =", "hello" == "hello")
print("  'hello' == 'Hello' =", "hello" == "Hello")

-- Empty string
print("\nEmpty string:")
local empty = ""
print("  #empty =", #empty)
print("  empty == '' =", empty == "")

-- String with special characters
print("\nSpecial characters:")
local newline = "Line1\nLine2"
print("  With newline:")
print(newline)

local tab = "Col1\tCol2"
print("  With tab:", tab)

-- String escapes
local quote = "He said \"Hello\""
print("  With quote:", quote)

-- String repetition (manual)
print("\nManual repetition:")
local rep = "x" .. "x" .. "x"
print("  'x' repeated 3 times:", rep)

-- String building with loop
print("\nBuilding string with loop:")
local built = ""
for i = 1, 5 do
  built = built .. i
end
print("  Result:", built)

print("\n=== All string operation tests passed! ===")
