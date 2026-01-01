-- Test concatenation edge cases
print("=== Concatenation (..) ===")

-- Basic string concatenation
print("Basic concatenation:")
print("  'hello' .. ' world' =", "hello" .. " world")
print("  'a' .. 'b' .. 'c' =", "a" .. "b" .. "c")

-- Number concatenation
print("\nNumber concatenation:")
print("  1 .. 2 =", 1 .. 2)
print("  10 .. 20 .. 30 =", 10 .. 20 .. 30)

-- Mixed types
print("\nMixed concatenation:")
print("  'hello' .. 5 =", "hello" .. 5)
print("  10 .. ' items' =", 10 .. " items")
print("  'count: ' .. 42 =", "count: " .. 42)

-- Float concatenation
print("\nFloat concatenation:")
print("  3.14 .. ' pi' =", 3.14 .. " pi")
print("  'value: ' .. 2.5 =", "value: " .. 2.5)

-- Empty string concatenation
print("\nEmpty string:")
print("  '' .. 'hello' =", "" .. "hello")
print("  'hello' .. '' =", "hello" .. "")
print("  '' .. '' =", "" .. "")

-- Boolean concatenation (may not work)
print("\nBoolean concatenation:")
-- print("  'value: ' .. true =", "value: " .. true)
print("  (SKIPPED: boolean concat may not work)")

-- Nil concatenation (should error)
print("\nNil concatenation:")
-- print("  'value: ' .. nil =", "value: " .. nil)
print("  (SKIPPED: nil concat would error)")

-- Concatenation in expressions
print("\nIn expressions:")
local result = "The answer is " .. (40 + 2)
print("  result =", result)

-- Concatenation with parentheses
print("\nWith parentheses:")
print("  ('a' .. 'b') .. 'c' =", ("a" .. "b") .. "c")
print("  'a' .. ('b' .. 'c') =", "a" .. ("b" .. "c"))

-- Long concatenation chain
print("\nLong chain:")
local long = "a" .. "b" .. "c" .. "d" .. "e" .. "f"
print("  'a'..'b'..'c'..'d'..'e'..'f' =", long)

-- Concatenation with variables
print("\nWith variables:")
local name = "Lua"
local version = 5.4
print("  name .. ' ' .. version =", name .. " " .. version)

-- Concatenation in table
print("\nIn table:")
local t = {
  msg = "Hello" .. " " .. "World"
}
print("  t.msg =", t.msg)

print("\n=== Concatenation tests complete! ===")
