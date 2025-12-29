// Basic tests for Lua value system

///|
test "create nil value" {
  let val = TValue::nil()
  assert_true(val.is_nil())
  @json.inspect(val.type_of(), content="Nil")
  assert_false(val.to_boolean()) // nil is falsy in Lua
}

///|
test "create boolean values" {
  let val_true = TValue::boolean(true)
  let val_false = TValue::boolean(false)
  assert_true(val_true.is_boolean())
  assert_true(val_false.is_boolean())
  @json.inspect(val_true.type_of(), content="Boolean")
  assert_true(val_true.to_boolean())
  assert_false(val_false.to_boolean())
}

///|
test "create integer values" {
  let val = TValue::integer(42L)
  assert_true(val.is_number())
  assert_true(val.is_integer())
  @json.inspect(val.type_of(), content="Number")
  let result = try? val.to_integer()
  inspect(result, content="Ok(42)")
}

///|
test "create float values" {
  let val = TValue::number(3.14)
  assert_true(val.is_number())
  assert_false(val.is_integer())
  @json.inspect(val.type_of(), content="Number")
  let result = try? val.to_number()
  inspect(result, content="Ok(3.14)")
}

///|
test "value equality" {
  let nil1 = TValue::nil()
  let nil2 = TValue::nil()
  assert_true(nil1.equal(nil2))
  let num1 = TValue::integer(10L)
  let num2 = TValue::integer(10L)
  let num3 = TValue::integer(20L)
  assert_true(num1.equal(num2))
  assert_false(num1.equal(num3))
  let bool1 = TValue::boolean(true)
  let bool2 = TValue::boolean(true)
  assert_true(bool1.equal(bool2))
}

///|
test "type mismatch errors" {
  let val = TValue::boolean(true)
  let result = try? val.to_integer()
  guard result is Err(ValueError::TypeMismatch(_)) else {
    fail("Expected TypeMismatch error")
  }
}

///|
test "comparison operations" {
  let num1 = TValue::integer(5L)
  let num2 = TValue::integer(10L)
  let lt_result = try? num1.less_than(num2)
  inspect(lt_result, content="Ok(true)")
  let le_result = try? num1.less_equal(num2)
  inspect(le_result, content="Ok(true)")
}
