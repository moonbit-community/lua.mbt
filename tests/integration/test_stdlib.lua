-- Test standard library functions

print("=== Standard Library Functions ===")

-- print function (already extensively tested)
print("\n1. print:")
print("Hello", "World", 42, true, nil)

-- type function
print("\n2. type:")
print("type(42) =", type(42))
print("type('hello') =", type("hello"))
print("type(true) =", type(true))
print("type(nil) =", type(nil))
print("type({}) =", type({}))

-- tostring function
print("\n3. tostring:")
print("tostring(42) =", tostring(42))
print("tostring(3.14) =", tostring(3.14))
print("tostring(true) =", tostring(true))
print("tostring(false) =", tostring(false))
print("tostring(nil) =", tostring(nil))

-- tonumber function
print("\n4. tonumber:")
print("tonumber('42') =", tonumber("42"))
print("tonumber('3.14') =", tonumber("3.14"))
print("tonumber('invalid') =", tonumber("invalid"))

-- assert function
print("\n5. assert:")
assert(true, "This should pass")
print("assert(true) passed")
assert(42, "Numbers are truthy")
print("assert(42) passed")
assert("hello", "Strings are truthy")
print("assert('hello') passed")

print("\n=== All standard library tests passed! ===")
