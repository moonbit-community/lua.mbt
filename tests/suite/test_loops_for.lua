-- Test: For loops (numeric)
-- Tests for loop with different ranges and steps

-- Basic for loop
local sum = 0
for i = 1, 5 do
  sum = sum + i
end
-- sum should be 15

-- For loop with step
local sum2 = 0
for i = 0, 10, 2 do
  sum2 = sum2 + i
end
-- sum2 should be 0+2+4+6+8+10 = 30

-- For loop counting down
local sum3 = 0
for i = 5, 1, -1 do
  sum3 = sum3 + i
end
-- sum3 should be 15

-- For loop with single iteration
for i = 5, 5 do
  local x = i
end

-- Nested for loops
local total = 0
for i = 1, 3 do
  for j = 1, 2 do
    total = total + 1
  end
end
-- total should be 6

-- For loop with local variables in body
for i = 1, 3 do
  local x = i * 2
  local y = x + 1
end

-- For loop in function
function sum_range(start, stop)
  local s = 0
  for i = start, stop do
    s = s + i
  end
  return s
end

local r = sum_range(1, 10)
-- r should be 55
