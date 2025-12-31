-- Test comparison operations
local a = 10
local b = 20

if a < b then
  print("10 < 20: true")
end

if a <= 10 then
  print("10 <= 10: true")
end

if b > a then
  print("20 > 10: true")
end

if b >= 20 then
  print("20 >= 20: true")
end

if a == 10 then
  print("10 == 10: true")
end

if a ~= b then
  print("10 ~= 20: true")
end
