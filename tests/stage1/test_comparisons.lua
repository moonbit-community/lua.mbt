-- Test comparison operators
local a = 10
local b = 5

-- Test less than
if a < b then
  a = 0
end

-- Test less than or equal
if b <= 5 then
  b = b + 1
end

-- Test greater than
if a > b then
  a = a + 1
end

-- Test greater than or equal
if a >= 10 then
  a = a + 5
end

-- Test equality
if a == 16 then
  a = 100
end

-- Test not equal
if a ~= 50 then
  a = a + 1
end
