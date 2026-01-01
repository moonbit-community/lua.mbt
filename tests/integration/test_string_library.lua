-- Test string library functions
-- CRITICAL BUG: string library is NOT IMPLEMENTED
-- Global 'string' does not exist
-- All string.* functions will fail with "Failed to get global 'string'"
-- Note: The stdlib functions (string_len, string_sub, etc.) work when called
-- directly from Lua via the API, but the string library table is not exposed
print("=== String Library Functions ===")

-- string.len
-- NOTE: This will error because string library table is not available
print("string.len:")
print("  len('hello') =", string.len("hello"))
print("  len('') =", string.len(""))

-- string.sub
print("\nstring.sub:")
local text = "Hello World"
print("  sub('Hello World', 1, 5) =", string.sub(text, 1, 5))
print("  sub('Hello World', 7) =", string.sub(text, 7))
print("  sub('Hello World', -5) =", string.sub(text, -5))

-- string.upper and string.lower
print("\nstring.upper and string.lower:")
print("  upper('hello') =", string.upper("hello"))
print("  lower('WORLD') =", string.lower("WORLD"))

-- string.rep
print("\nstring.rep:")
print("  rep('*', 5) =", string.rep("*", 5))
print("  rep('ab', 3) =", string.rep("ab", 3))

-- string.reverse
print("\nstring.reverse:")
print("  reverse('hello') =", string.reverse("hello"))

-- string.char and string.byte
print("\nstring.char and string.byte:")
print("  char(65, 66, 67) =", string.char(65, 66, 67))
print("  byte('ABC') =", string.byte("ABC"))
print("  byte('ABC', 2) =", string.byte("ABC", 2))
print("  byte('ABC', 1, 3) =", string.byte("ABC", 1, 3))

-- string.format
print("\nstring.format:")
print("  format('%d', 42) =", string.format("%d", 42))
print("  format('%s', 'test') =", string.format("%s", "test"))
print("  format('%d %s', 10, 'items') =", string.format("%d %s", 10, "items"))

-- string.find
print("\nstring.find:")
local s, e = string.find("hello world", "world")
print("  find('hello world', 'world') =", s, e)

-- string.gsub (substitution)
print("\nstring.gsub:")
local result, count = string.gsub("hello hello", "hello", "hi")
print("  gsub('hello hello', 'hello', 'hi') =", result)
print("  count =", count)

-- string.match
print("\nstring.match:")
local match = string.match("the number is 42", "%d+")
print("  match('the number is 42', '%d+') =", match)

print("\n=== String library tests complete! ===")
