// Basic tests for Lua C API

///|
test "create API context" {
  let api = LuaAPI::new()
  inspect(api.get_top(), content="0")
}

///|
test "push and get numbers" {
  let api = LuaAPI::new()
  api.push_number(3.14)
  api.push_boolean(true)
  api.push_nil()
  inspect(api.get_top(), content="3")
  assert_true(api.to_boolean(-2))
  inspect(try? api.to_number(1), content="Ok(3.14)")
}

///|
test "set and get globals" {
  let api = LuaAPI::new()
  api.push_number(42.0)
  api.set_global("x")
  api.get_global("x")
  inspect(try? api.to_number(-1), content="Ok(42)")
}

///|
test "load and execute simple local declaration" {
  let api = LuaAPI::new()
  // Simple local variable declaration and arithmetic
  let status = try! api.load_string("local x = 1 + 2")
  @json.inspect(status, content="OK")
}

///|
test "syntax error handling" {
  let api = LuaAPI::new()
  let result = try? api.load_string("invalid lua @#$ code")
  guard result is Err(APIError::SyntaxError(_)) else {
    fail("Expected SyntaxError")
  }
}
