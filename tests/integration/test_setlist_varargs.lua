-- Test SetList opcode with varargs in table constructors

function test_varargs(...)
  -- Basic vararg table constructor
  local t = {1, 2, ...}
  print("Table with varargs:")
  for i = 1, 5 do
    print(i, t[i])
  end
end

-- Test with 3 varargs (should result in table {1, 2, 3, 4, 5})
test_varargs(3, 4, 5)

-- Test with no varargs (should result in table {1, 2})
print("\nTable with no varargs:")
function test_no_varargs()
  local t = {1, 2}
  for i = 1, 3 do
    print(i, t[i])
  end
end
test_no_varargs()
