-- Test boolean operations and truthiness
print("=== Boolean Operations ===")

-- Boolean literals
print("Boolean literals:")
print("  true =", true)
print("  false =", false)

-- Boolean operations
print("\nBoolean AND:")
print("  true and true =", true and true)
print("  true and false =", true and false)
print("  false and true =", false and true)
print("  false and false =", false and false)

print("\nBoolean OR:")
print("  true or true =", true or true)
print("  true or false =", true or false)
print("  false or true =", false or true)
print("  false or false =", false or false)

print("\nBoolean NOT:")
print("  not true =", not true)
print("  not false =", not false)

-- Truthiness of all types
print("\nTruthiness (all truthy except nil and false):")
print("  0 is truthy:", 0 and true or false)
print("  1 is truthy:", 1 and true or false)
print("  -1 is truthy:", -1 and true or false)
print("  '' is truthy:", "" and true or false)
print("  'a' is truthy:", "a" and true or false)
print("  {} is truthy:", {} and true or false)
print("  false is falsy:", false and true or false)
print("  nil is falsy:", nil and true or false)

-- Short-circuit behavior
print("\nShort-circuit evaluation:")
print("  false and 'never' =", false and "never")
print("  true or 'never' =", true or "never")
print("  nil and 'never' =", nil and "never")
print("  nil or 'always' =", nil or "always")

-- Boolean in tables
print("\nBooleans in tables:")
local flags = {active = true, disabled = false, enabled = true}
print("  flags.active =", flags.active)
print("  flags.disabled =", flags.disabled)

-- Boolean from comparisons
print("\nFrom comparisons:")
local is_greater = 5 > 3
local is_equal = 10 == 10
print("  5 > 3 ->", is_greater)
print("  10 == 10 ->", is_equal)

-- Boolean variables
print("\nBoolean variables:")
local ready = true
local done = false
print("  ready =", ready)
print("  done =", done)
print("  ready and not done =", ready and not done)

-- Double negation
print("\nDouble negation (convert to boolean):")
print("  not not true =", not not true)
print("  not not 5 =", not not 5)
print("  not not nil =", not not nil)
print("  not not false =", not not false)

print("\n=== All boolean operation tests passed! ===")
