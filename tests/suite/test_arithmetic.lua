-- Test: Basic arithmetic operations
-- Tests addition, subtraction, multiplication, division
-- and proper operator precedence

-- Basic operations
local a = 5 + 3
local b = 10 - 4
local c = 6 * 7
local d = 20 / 4

-- Operator precedence
local e = 2 + 3 * 4       -- Should be 14, not 20
local f = (2 + 3) * 4     -- Should be 20
local g = 10 - 2 - 3      -- Should be 5 (left associative)
local h = 10 / 2 / 5      -- Should be 1.0 (left associative)

-- Mixed operations
local i = 1 + 2 * 3 - 4   -- Should be 3
local j = 10 / 2 + 5 * 2  -- Should be 15

-- Negative numbers
local k = -5
local l = -k              -- Should be 5
local m = 3 + -2          -- Should be 1
local n = -3 * 4          -- Should be -12

-- Parentheses
local o = (10 + 5) / (3 - 2)  -- Should be 15
