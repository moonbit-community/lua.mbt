-- Test: Basic function calls
-- Tests function definition, calling, and parameters

-- Function with no parameters
function greet()
  local x = 42
  return x
end
local g = greet()

-- Function with one parameter
function double(x)
  return x * 2
end
local d = double(5)
-- d should be 10

-- Function with multiple parameters
function add(a, b)
  return a + b
end
local sum = add(3, 7)
-- sum should be 10

-- Function calling another function
function helper()
  return 100
end

function caller()
  local x = helper()
  return x + 1
end

local result = caller()
-- result should be 101

-- Function with local variables
function compute(x)
  local y = x * 2
  local z = y + 5
  return z
end

local c = compute(10)
-- c should be 25

-- Nested function calls
function f1(x)
  return x + 1
end

function f2(x)
  return f1(x) + 2
end

function f3(x)
  return f2(x) + 3
end

local r = f3(10)
-- r should be 16 (10+1+2+3)

-- Function assigned to variable
local func = double
local x = func(20)
-- x should be 40
