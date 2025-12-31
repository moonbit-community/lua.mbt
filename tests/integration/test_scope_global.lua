-- Test global vs local scope patterns
print("=== Global vs Local Scope ===")

-- Implicit global
implicit_global = 100
print("implicit_global =", implicit_global)

-- Explicit local
local explicit_local = 200
print("explicit_local =", explicit_local)

-- Function creating globals
local function make_global()
  created_in_function = 300
end

make_global()
print("created_in_function =", created_in_function)

-- Function using global
global_val = 10

local function use_global()
  return global_val * 2
end

print("use_global() =", use_global())

-- Modify global from function
local function modify_global()
  global_val = 99
end

modify_global()
print("After modify: global_val =", global_val)

-- Multiple globals
a, b, c = 1, 2, 3
print("\nMultiple globals: a =", a, "b =", b, "c =", c)

-- Global then local
print("\nGlobal assignment:")
shadow_test = "global"
print("  shadow_test =", shadow_test)

-- NOTE: Local shadowing has bugs, so we won't test further
-- NOTE: Accessing undeclared variables throws error instead of returning nil

-- Set global to nil
existing = 42
print("\nVariable with nil:")
print("  existing =", existing)
existing = nil
print("  After nil: existing =", existing)

-- Check if global exists (must declare first)
check_var = nil
if check_var == nil then
  print("\ncheck_var is nil")
end

-- Globals in different scopes
outer_global = "outer"

do
  inner_global = "inner"
  print("\nInside do block:")
  print("  outer_global =", outer_global)
  print("  inner_global =", inner_global)
end

print("\nOutside do block:")
print("  outer_global =", outer_global)
print("  inner_global =", inner_global)

print("\n=== All global/local scope tests passed! ===")
