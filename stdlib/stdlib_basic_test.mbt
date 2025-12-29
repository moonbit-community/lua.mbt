// Basic tests for Lua standard library

///|
test "type function" {
  inspect(type_(@value.TValue::nil()), content="nil")
  inspect(type_(@value.TValue::boolean(true)), content="boolean")
  inspect(type_(@value.TValue::integer(42L)), content="number")
}

///|
test "tostring function" {
  inspect(tostring(@value.TValue::integer(42L)), content="42")
  inspect(tostring(@value.TValue::boolean(true)), content="true")
  inspect(tostring(@value.TValue::nil()), content="nil")
}

///|
test "tonumber function" {
  let val = try! tonumber(@value.TValue::integer(42L))
  assert_true(val.is_number())
  let result = try? tonumber(@value.TValue::boolean(true))
  guard result is Err(StdlibError::TypeMismatch(_)) else {
    fail("Expected TypeMismatch error")
  }
}

///|
test "assert function" {
  let val = try! assert_(@value.TValue::boolean(true))
  assert_true(val.to_boolean())
  let result = try? assert_(
    @value.TValue::boolean(false),
    message="Test assertion",
  )
  guard result is Err(StdlibError::InvalidArgument(_)) else {
    fail("Expected InvalidArgument error for false assertion")
  }
}

///|
test "math.abs function" {
  let val = try! math_abs(@value.TValue::integer(-42L))
  inspect(try? val.to_integer(), content="Ok(42)")
  let val2 = try! math_abs(@value.TValue::number(-3.14))
  inspect(try? val2.to_number(), content="Ok(3.14)")
}

///|
test "math.floor and ceil functions" {
  let floor_val = try! math_floor(@value.TValue::number(3.7))
  inspect(try? floor_val.to_number(), content="Ok(3)")
  let ceil_val = try! math_ceil(@value.TValue::number(3.2))
  inspect(try? ceil_val.to_number(), content="Ok(4)")
}

///|
test "math.sqrt function" {
  let val = try! math_sqrt(@value.TValue::integer(16L))
  inspect(try? val.to_number(), content="Ok(4)")
}

///|
test "register stdlib in state" {
  let state = @state.LuaState::new()
  register_stdlib(state)

  // Check that basic functions are registered
  assert_true(state.has_global("print"))
  assert_true(state.has_global("type"))
  assert_true(state.has_global("tonumber"))
}
