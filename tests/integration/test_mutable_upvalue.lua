-- Test mutable upvalue support

-- Test 1: Simple counter closure with mutable upvalue
local function make_counter()
  local count = 0
  return function()
    count = count + 1  -- Modify captured variable
    return count
  end
end

local c = make_counter()
print(c())  -- Should print 1
print(c())  -- Should print 2
print(c())  -- Should print 3

-- Test 2: Multiple closures sharing same upvalue
local function make_inc_dec()
  local value = 10
  local function inc()
    value = value + 1
    return value
  end
  local function dec()
    value = value - 1
    return value
  end
  return inc, dec
end

local inc, dec = make_inc_dec()
print(inc())  -- Should print 11
print(inc())  -- Should print 12
print(dec())  -- Should print 11
print(dec())  -- Should print 10

-- Test 3: Nested closures
local function outer()
  local x = 5
  return function()
    local y = 10
    return function()
      x = x + y  -- Modify upvalue from outer scope
      return x
    end
  end
end

local make_inner = outer()
local inner = make_inner()
print(inner())  -- Should print 15
print(inner())  -- Should print 25
