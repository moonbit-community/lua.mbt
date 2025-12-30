-- Test: While loops
-- Tests while loop functionality, conditions, and loop variables

-- Simple while loop
local i = 0
while i < 5 do
  i = i + 1
end
-- i should be 5

-- While loop with more complex condition
local sum = 0
local n = 1
while n <= 10 do
  sum = sum + n
  n = n + 1
end
-- sum should be 55 (1+2+3+...+10)

-- Nested while loops
local outer = 0
while outer < 3 do
  local inner = 0
  while inner < 2 do
    inner = inner + 1
  end
  outer = outer + 1
end

-- While loop with break condition
local count = 0
while count < 100 do
  count = count + 1
  if count == 10 then
    count = 100  -- Effectively break by making condition false
  end
end

-- While loop in function
function countdown(n)
  local i = n
  while i > 0 do
    i = i - 1
  end
  return i
end

local result = countdown(5)
-- result should be 0
