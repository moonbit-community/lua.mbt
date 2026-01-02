-- Test load() function for dynamic code compilation

-- Test 1: Load and execute simple expression
local f1 = load("return 2 + 3")
print(f1())  -- Should print 5

-- Test 2: Load code with variables
local f2 = load("local x = 10; return x * 2")
print(f2())  -- Should print 20

-- Test 3: Load code with print
local f3 = load("print('Hello from loaded code')")
f3()  -- Should print "Hello from loaded code"

-- Test 4: Load code that creates a function
local f4 = load([[
  local function add(a, b)
    return a + b
  end
  return add(7, 8)
]])
print(f4())  -- Should print 15

-- Test 5: Error handling - syntax error
local f5, err = load("return 2 +")
if f5 == nil then
  print("Error:", err)
else
  print("Unexpected success")
end

-- Test 6: Load code that uses globals
x = 100
local f6 = load("return x + 50")
print(f6())  -- Should print 150

-- Test 7: Load code that sets globals
local f7 = load("y = 42")
f7()
print(y)  -- Should print 42
