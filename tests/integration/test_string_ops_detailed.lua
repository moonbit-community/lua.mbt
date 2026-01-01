-- Test string operations in detail
print("=== String Operations ===")

-- String literals
print("String literals:")
print("  'single' =", 'single')
print("  \"double\" =", "double")

-- Empty string
print("\nEmpty string:")
print("  '' =", '')
print("  \"\" =", "")
print("  type('') =", type(""))

-- String length
print("\nString length:")
print("  #'hello' =", #"hello")
print("  #'a' =", #"a")
print("  #'' =", #"")
print("  #'multi word string' =", #"multi word string")

-- String concatenation
print("\nConcatenation:")
print("  'a' .. 'b' =", "a" .. "b")
print("  'hello' .. ' ' .. 'world' =", "hello" .. " " .. "world")
print("  '' .. 'x' =", "" .. "x")
print("  'x' .. '' =", "x" .. "")

-- Number concatenation
print("\nWith numbers:")
print("  'count: ' .. 42 =", "count: " .. 42)
print("  10 .. 20 =", 10 .. 20)
print("  3.14 .. ' pi' =", 3.14 .. " pi")

-- String comparison
print("\nComparison:")
print("  'a' == 'a' =", "a" == "a")
print("  'a' == 'b' =", "a" == "b")
print("  'a' < 'b' =", "a" < "b")
print("  'b' > 'a' =", "b" > "a")
print("  'abc' < 'abd' =", "abc" < "abd")
print("  'hello' <= 'hello' =", "hello" <= "hello")

-- Lexicographic comparison
print("\nLexicographic:")
print("  'Apple' < 'apple' =", "Apple" < "apple")
print("  'z' > 'a' =", "z" > "a")
print("  '10' < '2' =", "10" < "2")

-- String equality
print("\nEquality:")
print("  'test' == 'test' =", "test" == "test")
print("  'test' ~= 'Test' =", "test" ~= "Test")

-- String with numbers
print("\nString vs number:")
print("  '5' == 5 =", "5" == 5)
print("  '5' ~= 5 =", "5" ~= 5)
print("  type('5') =", type("5"))

-- String escapes
print("\nEscapes:")
print("  'line1\\nline2':")
print("line1\nline2")
print("  'tab\\there' =", "tab\there")
print("  'quote: \\'x\\'' =", "quote: 'x'")

-- String in table
print("\nIn table:")
local t = {"first", "second", "third"}
print("  t[1], t[2], t[3] =", t[1], t[2], t[3])

-- String as key
print("\nAs table key:")
local dict = {
  name = "value",
  ["key"] = "data"
}
print("  dict.name =", dict.name)
print("  dict['key'] =", dict["key"])

-- Multiline string (using escapes)
print("\nMultiline:")
local multi = "line 1\nline 2\nline 3"
print(multi)

-- String with special chars
print("\nSpecial characters:")
print("  '!@#$%' =", "!@#$%")
print("  '()[]{}<>' =", "()[]{}<>")
print("  '&*^' =", "&*^")

-- Long string
print("\nLong string:")
local long = "This is a longer string with multiple words and characters to test handling"
print("  Length:", #long)
print("  Content:", long)

-- String concatenation in loop
print("\nConcat in loop:")
local result = ""
for i = 1, 5 do
  result = result .. i
end
print("  result =", result)

-- String repeat (manual)
print("\nString repeat:")
local repeated = ""
for i = 1, 3 do
  repeated = repeated .. "x"
end
print("  'x' * 3 =", repeated)

-- String in expression
print("\nIn expression:")
local prefix = "Hello"
local suffix = "World"
local combined = prefix .. " " .. suffix
print("  combined =", combined)

-- String with numbers in table
print("\nMixed table:")
local mixed = {1, "two", 3, "four"}
print("  mixed:", mixed[1], mixed[2], mixed[3], mixed[4])

-- String conversion
print("\nConversion:")
print("  tostring('hello') =", tostring("hello"))
print("  tonumber('123') =", tonumber("123"))
print("  tonumber('abc') =", tonumber("abc"))

-- String type check
print("\nType check:")
local s = "test"
if type(s) == "string" then
  print("  s is a string ✓")
end

-- Empty vs nil
print("\nEmpty vs nil:")
local empty = ""
local nothing = nil
print("  empty == nil =", empty == nil)
print("  type(empty) =", type(empty))
print("  #empty =", #empty)

-- String in condition
print("\nIn condition:")
-- BUG: Strings not truthy
if "" then
  print("  '' is truthy")
else
  print("  BUG: '' is falsy (should be truthy)")
end

-- Case sensitivity
print("\nCase sensitive:")
print("  'Hello' == 'hello' =", "Hello" == "hello")
print("  'ABC' == 'abc' =", "ABC" == "abc")

-- String with unicode (ASCII only)
print("\nASCII characters:")
print("  'Hello123!@#' =", "Hello123!@#")

-- Concatenate many strings
print("\nMany concat:")
local many = "a" .. "b" .. "c" .. "d" .. "e"
print("  a..b..c..d..e =", many)

-- String comparison with length
print("\nLength comparison:")
local s1 = "short"
local s2 = "much longer string"
print("  #s1 < #s2 =", #s1 < #s2)

print("\n=== String operation tests complete! ===")
