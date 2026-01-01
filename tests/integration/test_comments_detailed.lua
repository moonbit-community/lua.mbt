-- Test comment parsing and edge cases
print("=== Comments ===")

-- Single line comment
print("Single line comments:")
-- This is a comment
print("  After comment line")

local x = 10 -- Inline comment
print("  x with inline comment =", x)

-- Multiple consecutive comments
print("\nMultiple comments:")
-- Comment 1
-- Comment 2
-- Comment 3
print("  After multiple comments")

-- Comment with special characters
print("\nComments with special chars:")
-- !@#$%^&*()_+-={}[]|:";'<>?,./
print("  After special char comment")

-- Empty comment
print("\nEmpty comment:")
--
print("  After empty comment")

-- Comment with code
print("\nCommented code:")
-- local commented = "This is commented"
-- print("This won't execute")
print("  After commented code")

-- Multiline comments (if supported)
-- BUG: Multiline comments not supported
print("\nMultiline comments:")
-- --[[
-- This would be a multiline comment
-- spanning multiple lines
-- ]]
print("  (Multiline --[[ ]] not supported)")

-- Comment at end of file
print("\nComments in code:")
local function f()
  -- Comment in function
  return 42
end
print("  f() =", f())

-- Comment in blocks
print("\nComments in blocks:")
if true then
  -- Comment in if
  print("  In if block")
end

for i = 1, 2 do
  -- Comment in loop
  print("  Loop iteration", i)
end

-- Comment between statements
print("\nComment between statements:")
local a = 1
-- Between assignments
local b = 2
print("  a, b =", a, b)

-- Comment with operators
print("\nComment near operators:")
local result = 5 + -- Comment in expression
  3
print("  5 + 3 =", result)

-- Comment in table
print("\nComment in table:")
local t = {
  -- Comment before field
  x = 10,
  -- Comment between fields
  y = 20
  -- Comment after field
}
print("  t.x, t.y =", t.x, t.y)

-- Comment in function
print("\nComment in function:")
local function commented()
  -- Start of function
  local val = 5
  -- Middle of function
  val = val * 2
  -- Before return
  return val
  -- After return (unreachable)
end
print("  commented() =", commented())

-- Comments with strings
print("\nComments vs strings:")
local s = "-- This is NOT a comment"
print("  String:", s)

-- Comment symbols in strings
local s2 = "The symbol -- is used for comments"
print("  String with --:", s2)

-- Very long comment
print("\nLong comment:")
-- This is a very long comment that goes on and on and on and on and on and on and on and on and on and on
print("  After long comment")

-- Comment with numbers
print("\nComment with numbers:")
-- 123456789 0.123 -45 0xFF 1e10
print("  After numeric comment")

-- Comment with quotes
print("\nComment with quotes:")
-- Comment with "quotes" and 'apostrophes'
print("  After quoted comment")

-- Nested comment symbols
print("\nNested comment symbols:")
-- This comment has -- nested comment symbols
print("  After nested comment symbols")

print("\n=== Comment tests complete! ===")

-- Final comment at end of file