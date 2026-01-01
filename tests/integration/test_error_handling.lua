-- Test error handling with pcall and xpcall
-- CRITICAL BUG: Error handling is NOT IMPLEMENTED
-- pcall(), xpcall(), and error() do not exist
-- All error handling will fail with "Failed to get global 'pcall'"
-- Note: assert() may or may not be implemented
print("=== Error Handling ===")

-- Basic pcall success
-- NOTE: This will error because pcall is not available
print("pcall success:")
local status, result = pcall(function()
  return 42
end)
print("  status =", status)
print("  result =", result)

-- Basic pcall error
print("\npcall error:")
status, err = pcall(function()
  error("Test error")
end)
print("  status =", status)
print("  error =", err)

-- pcall with arguments
print("\npcall with arguments:")
local function divide(a, b)
  if b == 0 then
    error("Division by zero")
  end
  return a / b
end

status, result = pcall(divide, 10, 2)
print("  divide(10, 2): status =", status, "result =", result)

status, err = pcall(divide, 10, 0)
print("  divide(10, 0): status =", status, "error =", err)

-- Nested pcall
print("\nNested pcall:")
status, result = pcall(function()
  local inner_status, inner_result = pcall(function()
    error("Inner error")
  end)
  return inner_status
end)
print("  Outer status =", status)
print("  Inner status (as result) =", result)

-- xpcall with error handler
print("\nxpcall with error handler:")
local function errorHandler(err)
  return "Caught: " .. err
end

status, result = xpcall(function()
  error("Test xpcall error")
end, errorHandler)
print("  status =", status)
print("  handled error =", result)

-- assert function
print("\nassert:")
local val = assert(42, "This should not error")
print("  assert(42) =", val)

status, err = pcall(function()
  assert(false, "Assert failed message")
end)
print("  assert(false): status =", status)

-- error levels
print("\nerror levels:")
local function level1()
  error("Error from level1", 2)
end

local function level2()
  level1()
end

status, err = pcall(level2)
print("  error with level 2: status =", status)

print("\n=== Error handling tests complete! ===")
