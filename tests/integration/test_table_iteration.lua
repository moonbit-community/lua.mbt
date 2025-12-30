-- Test: Table with for loop
local t = {10, 20, 30, 40, 50}

local sum = 0
for i = 1, 5 do
  sum = sum + t[i]
end

-- sum should be 150
