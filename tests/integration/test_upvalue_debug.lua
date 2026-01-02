-- Simple upvalue test
local function make_counter()
  local count = 0
  print("Initial count:", count)
  return function()
    print("Before increment, count type:", type(count))
    print("Before increment, count value:", count)
    count = count + 1
    print("After increment, count:", count)
    return count
  end
end

local c = make_counter()
c()
c()
