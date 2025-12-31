-- Test control flow: elseif chains

print("=== Testing elseif ===")

-- Simple elseif
local x = 10

if x < 5 then
  print("FAIL: x < 5")
elseif x < 15 then
  print("PASS: 5 <= x < 15")
elseif x < 20 then
  print("FAIL: 15 <= x < 20")
else
  print("FAIL: x >= 20")
end

-- Multiple elseif for grading
print("\n=== Grading system ===")
local scores = {95, 85, 75, 65, 55}
local grades = {"A", "B", "C", "D", "F"}

for i = 1, #scores do
  local score = scores[i]
  local expected = grades[i]
  local result

  if score >= 90 then
    result = "A"
  elseif score >= 80 then
    result = "B"
  elseif score >= 70 then
    result = "C"
  elseif score >= 60 then
    result = "D"
  else
    result = "F"
  end

  print("Score " .. score .. " -> " .. result .. " (expected " .. expected .. ")")
end

-- Nested if-elseif-else
print("\n=== Nested conditions ===")
local age = 25
local hasLicense = true

if age < 16 then
  print("Too young to drive")
elseif age < 18 then
  if hasLicense then
    print("Can drive with restrictions")
  else
    print("Need to get license")
  end
else
  if hasLicense then
    print("Can drive freely")
  else
    print("Should get license")
  end
end

print("\n=== All elseif tests passed! ===")
