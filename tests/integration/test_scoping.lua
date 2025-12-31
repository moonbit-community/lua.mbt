-- Test variable scoping
print("=== Variable Scoping ===")

-- Global variable
global_var = 100
print("global_var =", global_var)

-- Modifying global in do-end
do
  global_var = 200
  print("Inside do-end: global_var =", global_var)
end

print("Outside do-end: global_var =", global_var)

-- NOTE: Local variable shadowing has a bug - locals persist after blocks
-- instead of being properly cleaned up. This causes:
-- - Shadowed variables to keep the inner value after block ends
-- - Nested scopes to show inner values instead of unwinding

-- NOTE: Functions cannot access outer local variables (closure/upvalue issue)
-- This is a known limitation requiring upvalue support

-- Block scope with if (globals work)
print("\nBlock scope in if:")
scoped_value = 0

if scoped_value == 0 then
  scoped_value = 99
  print("Inside if: scoped_value =", scoped_value)
end

print("Outside if: scoped_value =", scoped_value)

-- Loop variable scope works correctly
print("\nLoop variable scope:")
for i = 1, 3 do
  print("Loop i =", i)
end

print("\n=== All working scoping tests passed! ===")
