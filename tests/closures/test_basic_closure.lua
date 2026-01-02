-- Test basic closure capturing a local variable (read-only)

function makeCounter()
  local count = 0
  return function()
    return count  -- Read captured variable
  end
end

local counter = makeCounter()
print(counter())  -- Should print 0
print(counter())  -- Should print 0 (cannot increment without SetUpval)
