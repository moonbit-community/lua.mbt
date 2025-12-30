-- Test: If/else conditionals
-- Tests various conditional patterns and nesting

-- Simple if
local x = 5
if x == 5 then
  local y = 10
end

-- If-else
if x == 3 then
  local a = 1
else
  local b = 2
end

-- Nested conditionals
if x > 0 then
  if x < 10 then
    local z = 100
  else
    local z = 200
  end
else
  local z = 300
end

-- Multiple if statements
if 1 < 2 then
  local a = 1
end
if 2 < 3 then
  local b = 2
end
if 3 < 4 then
  local c = 3
end

-- Conditionals with complex expressions
local a = 10
local b = 20
if a + b == 30 then
  local c = 1
end

if a * 2 == b then
  local d = 1
end

-- Conditionals in functions
function test(n)
  if n == 0 then
    return 1
  else
    return 2
  end
end

local r1 = test(0)
local r2 = test(5)
