-- Test: Basic table operations
-- Tests table creation, indexing, and assignment

-- Empty table
local t1 = {}

-- Table with numeric indices (array-like)
local t2 = {10, 20, 30}
local a = t2[1]  -- Should be 10
local b = t2[2]  -- Should be 20
local c = t2[3]  -- Should be 30

-- Table assignment
local t3 = {}
t3[1] = 100
t3[2] = 200
t3[3] = 300

-- Reading and writing in sequence
local t4 = {1, 2, 3}
local x = t4[1]
t4[1] = x * 10

-- Table with mixed operations
local t5 = {5, 10, 15}
local sum = t5[1] + t5[2] + t5[3]
-- sum should be 30

-- Table in function parameter
function get_first(tbl)
  return tbl[1]
end

local t6 = {42, 43, 44}
local first = get_first(t6)
-- first should be 42

-- Table modification in function
function set_value(tbl, index, value)
  tbl[index] = value
end

local t7 = {1, 2, 3}
set_value(t7, 2, 999)
local val = t7[2]
-- val should be 999

-- Table with expressions as indices
local t8 = {100, 200, 300}
local i = 1
local j = i + 1
local v1 = t8[i]      -- Should be 100
local v2 = t8[j]      -- Should be 200
local v3 = t8[i + 2]  -- Should be 300
