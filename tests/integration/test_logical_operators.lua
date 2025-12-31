-- Test logical operators with proper Lua semantics

-- Test basic boolean and/or/not
print("Boolean operations:")
print("true and true:", true and true)
print("true and false:", true and false)
print("false or true:", false or true)
print("not true:", not true)
print("not false:", not false)

-- Test and/or with truthy values (numbers, strings)
print("\nTruthy value operations:")
local x = 5 and 10
print("5 and 10 =", x)  -- Should be 10

local y = 3 or 7
print("3 or 7 =", y)  -- Should be 3

local z = "hello" and "world"
print('"hello" and "world" =', z)  -- Should be "world"

-- Test and/or with falsy values (nil, false)
print("\nFalsy value operations:")
local a = nil and 100
print("nil and 100 =", a)  -- Should be nil

local b = nil or 100
print("nil or 100 =", b)  -- Should be 100

local c = false and 200
print("false and 200 =", c)  -- Should be false

local d = false or 200
print("false or 200 =", d)  -- Should be 200

-- Test short-circuit evaluation
print("\nShort-circuit behavior:")
print("0 and 42:", 0 and 42)  -- 0 is truthy in Lua, should be 42
print("1 or 99:", 1 or 99)    -- 1 is truthy, should be 1
