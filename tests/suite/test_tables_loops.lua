-- Test: Tables with loops
-- Tests iteration over tables and table manipulation in loops

-- Build table with for loop
local t1 = {}
for i = 1, 5 do
  t1[i] = i * 10
end
-- t1 should be {10, 20, 30, 40, 50}

-- Sum table elements with for loop
local t2 = {1, 2, 3, 4, 5}
local sum = 0
for i = 1, 5 do
  sum = sum + t2[i]
end
-- sum should be 15

-- Modify table elements in loop
local t3 = {1, 2, 3, 4, 5}
for i = 1, 5 do
  t3[i] = t3[i] * 2
end
-- t3 should be {2, 4, 6, 8, 10}

-- Table with while loop
local t4 = {}
local i = 1
while i <= 3 do
  t4[i] = i * i
  i = i + 1
end
-- t4 should be {1, 4, 9}

-- Nested loops with tables
local matrix = {{1, 2}, {3, 4}, {5, 6}}
local total = 0
for i = 1, 3 do
  for j = 1, 2 do
    total = total + matrix[i][j]
  end
end
-- total should be 21

-- Find element in table
local t5 = {10, 20, 30, 40, 50}
local target = 30
local found_index = 0
for i = 1, 5 do
  if t5[i] == target then
    found_index = i
  end
end
-- found_index should be 3

-- Copy table
local t6 = {1, 2, 3}
local t7 = {}
for i = 1, 3 do
  t7[i] = t6[i]
end
