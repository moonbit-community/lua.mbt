-- Test print function and output formatting
print("=== Print Function ===")

-- Basic print
print("Basic print:")
print("  Hello, World!")

-- Multiple arguments
print("\nMultiple arguments:")
print("  Multiple:", 1, 2, 3)
print("  Mixed types:", 42, "hello", true, nil)

-- Printing variables
print("\nPrinting variables:")
local x = 10
local y = "test"
print("  x, y =", x, y)

-- Printing expressions
print("\nPrinting expressions:")
print("  5 + 3 =", 5 + 3)
print("  'a' .. 'b' =", "a" .. "b")

-- Printing tables
print("\nPrinting tables:")
local t = {1, 2, 3}
print("  table:", t)  -- Will print address

-- Printing functions
print("\nPrinting functions:")
local f = function() end
print("  function:", f)  -- Will print address

-- Empty print
print("\nEmpty print:")
print()
print("  (empty line above)")

-- Nil in print
print("\nNil in print:")
print("  Before nil:", nil, "after nil")

-- Boolean in print
print("\nBoolean in print:")
print("  true =", true)
print("  false =", false)

-- Number formats in print
print("\nNumber formats:")
print("  Integer:", 42)
print("  Float:", 3.14)
print("  Scientific:", 1e3)
print("  Negative:", -5)

-- Long string in print
print("\nLong string:")
print("  This is a longer string to test how print handles it")

-- Special characters
print("\nSpecial characters:")
print("  Tab:\there")
print("  Newline on\nnext line")
print("  Quote: 'single' and \"double\"")

-- Concatenation in print
print("\nConcatenation:")
print("  Result: " .. (10 + 20))

-- Nested calls
print("\nNested:")
print("  Inner:", tostring(42))

print("\n=== Print tests complete! ===")
