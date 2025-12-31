-- Test while loop
print("While loop:")
local i = 1
while i <= 5 do
  print("i =", i)
  i = i + 1
end

-- Test for loop
print("For loop:")
for j = 1, 5 do
  print("j =", j)
end

-- Test for loop with step
print("For loop with step 2:")
for k = 0, 10, 2 do
  print("k =", k)
end

-- Test repeat-until
print("Repeat-until:")
local n = 1
repeat
  print("n =", n)
  n = n + 1
until n > 3
