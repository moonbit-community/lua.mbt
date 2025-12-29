-- Test: Mixed table (array + hash)
local mixed = {10, 20, x = 100, y = 200}
local first = mixed[1]
local second = mixed[2]
local xval = mixed.x
local yval = mixed.y
