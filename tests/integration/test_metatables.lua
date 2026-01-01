-- Test metatable functionality
-- CRITICAL BUG: Metatables are NOT IMPLEMENTED
-- setmetatable() and getmetatable() do not exist
-- All metatable functionality will fail with "Failed to get global 'setmetatable'"
print("=== Metatables ===")

-- Basic metatable
-- NOTE: This will error because setmetatable is not available
print("Basic metatable:")
local t = {value = 10}
local mt = {
  __tostring = function(self)
    return "Table with value: " .. self.value
  end
}
setmetatable(t, mt)
print("  tostring(t) =", tostring(t))

-- Arithmetic metamethods
print("\nArithmetic metamethods:")
local vec1 = {x = 1, y = 2}
local vec2 = {x = 3, y = 4}
local vec_mt = {
  __add = function(a, b)
    return {x = a.x + b.x, y = a.y + b.y}
  end,
  __sub = function(a, b)
    return {x = a.x - b.x, y = a.y - b.y}
  end
}
setmetatable(vec1, vec_mt)
setmetatable(vec2, vec_mt)

local sum = vec1 + vec2
print("  vec1 + vec2 =", sum.x, sum.y)

local diff = vec1 - vec2
print("  vec1 - vec2 =", diff.x, diff.y)

-- __index metamethod
print("\n__index metamethod:")
local defaults = {name = "Unknown", age = 0}
local person = {}
setmetatable(person, {__index = defaults})
print("  person.name =", person.name)
print("  person.age =", person.age)

person.name = "Alice"
print("  After setting name =", person.name)

-- __newindex metamethod
print("\n__newindex metamethod:")
local readonly = {}
local data = {value = 42}
setmetatable(readonly, {
  __index = data,
  __newindex = function(t, k, v)
    print("  Attempt to modify readonly table blocked!")
  end
})
print("  readonly.value =", readonly.value)
readonly.value = 100  -- Should be blocked
print("  readonly.value still =", readonly.value)

-- __call metamethod
print("\n__call metamethod:")
local callable = {count = 0}
setmetatable(callable, {
  __call = function(self, ...)
    self.count = self.count + 1
    print("  Called", self.count, "times")
  end
})
callable()
callable()

-- getmetatable
print("\ngetmetatable:")
print("  getmetatable(t) exists =", getmetatable(t) ~= nil)

-- __eq metamethod
print("\n__eq metamethod:")
local a = {val = 5}
local b = {val = 5}
local eq_mt = {
  __eq = function(x, y)
    return x.val == y.val
  end
}
setmetatable(a, eq_mt)
setmetatable(b, eq_mt)
print("  a == b =", a == b)

print("\n=== Metatable tests complete! ===")
