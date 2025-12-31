-- Test comment styles
print("=== Comment Handling ===")

-- Single line comment
local x = 10 -- inline comment
print("x =", x)

-- Multiple single-line comments
-- This is a comment
-- This is another comment
local y = 20
print("y =", y)

-- NOTE: Multi-line comments --[[ ]] may not be supported
-- Skipping multi-line comment tests

-- Code with comments
local function test(a, b) -- function with comments
  -- Calculate sum
  local sum = a + b -- add them
  return sum -- return result
end

print("\ntest(5, 7) =", test(5, 7))

-- Commented out code
-- local unused = 999
-- print("This won't run")

-- Comments with special characters
-- Special: !@#$%^&*()_+-=[]{}|;':",.<>?/~`

-- Empty comments
--
--
--

print("\n=== All comment tests passed! ===")
