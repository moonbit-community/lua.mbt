-- Test various string operations
print("=== String Operations ===")

-- Basic concatenation
local s1 = "Hello"
local s2 = "World"
local s3 = s1 .. " " .. s2
print("Concatenation:", s3)

-- String with numbers
local msg = "Count: " .. 42
print(msg)

-- Multiple concatenations
local result = "a" .. "b" .. "c" .. "d"
print("Multiple concat:", result)

-- String length
local text = "Hello, Lua!"
print("\nString length:")
print("#text =", #text)

-- String comparison
print("\nString comparison:")
print('"abc" < "def" =', "abc" < "def")
print('"xyz" > "abc" =', "xyz" > "abc")
print('"hello" == "hello" =', "hello" == "hello")

-- String escape sequences
local newline = "Line 1\nLine 2"
print("\nEscape sequences:")
print(newline)

local tab = "Col1\tCol2"
print(tab)

print("\n=== All string tests passed! ===")
