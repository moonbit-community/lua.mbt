-- Test: Comparison operations
-- Tests ==, <, <=, >, >= operations and their use in conditionals

-- Equality
local a = 5
local b = 5
local c = 3
if a == b then
  local x = 1  -- Should execute
end
if a == c then
  local y = 2  -- Should NOT execute
else
  local z = 3  -- Should execute
end

-- Less than
if 3 < 5 then
  local x = 1  -- Should execute
end
if 5 < 3 then
  local y = 2  -- Should NOT execute
end

-- Less than or equal
if 5 <= 5 then
  local x = 1  -- Should execute
end
if 5 <= 10 then
  local y = 2  -- Should execute
end
if 10 <= 5 then
  local z = 3  -- Should NOT execute
end

-- Multiple comparisons in conditions
local x = 10
if x > 5 then
  if x < 15 then
    local y = 1  -- Should execute (x is between 5 and 15)
  end
end

-- Comparison results in expressions
local a = 1
local b = 2
if a < b then
  local result = 100
else
  local result = 200
end
