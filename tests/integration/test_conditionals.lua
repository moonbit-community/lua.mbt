-- Test conditional patterns and edge cases
print("=== Conditional Patterns ===")

-- Truthiness tests
print("Truthiness:")
print("  0 is truthy:", 0 and true or false)
print("  '' is truthy:", "" and true or false)
print("  false is falsy:", false and true or false)
print("  nil is falsy:", nil and true or false)

-- Ternary-like pattern
print("\nTernary pattern (cond and val1 or val2):")
local age = 20
local status = age >= 18 and "adult" or "minor"
print("  age=" .. age .. " -> status:", status)

age = 15
status = age >= 18 and "adult" or "minor"
print("  age=" .. age .. " -> status:", status)

-- Default values pattern
print("\nDefault values (val or default):")
local x = nil
local result = x or 42
print("  nil or 42 =", result)

x = 10
result = x or 42
print("  10 or 42 =", result)

x = false
result = x or 42
print("  false or 42 =", result)

x = 0
result = x or 42
print("  0 or 42 =", result)

-- Guard pattern
print("\nGuard pattern (cond and action):")
local enabled = true
local msg = enabled and "Feature enabled" or "Feature disabled"
print("  enabled=" .. tostring(enabled) .. " ->", msg)

-- Chained conditions
print("\nChained conditions:")
local a, b, c = 1, 2, 3
if a < b and b < c then
  print("  a < b < c: true")
end

if a < b or b > c then
  print("  a < b or b > c: true")
end

-- Not with various types
print("\nNot operator with different types:")
print("  not nil =", not nil)
print("  not false =", not false)
print("  not true =", not true)
print("  not 0 =", not 0)
print("  not '' =", not "")
print("  not {} =", not {})

print("\n=== All conditional pattern tests passed! ===")
