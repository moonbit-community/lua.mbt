// Basic tests for Lua state management

///|
test "create new state" {
  let state = LuaState::new()
  inspect(state.stack_size(), content="0")
}

///|
test "push and pop values" {
  let state = LuaState::new()
  state.push(@value.TValue::integer(42L))
  inspect(state.stack_size(), content="1")
  let val = try! state.pop()
  assert_true(val.is_integer())
  inspect(state.stack_size(), content="0")
}

///|
test "stack indexing" {
  let state = LuaState::new()
  state.push(@value.TValue::integer(1L))
  state.push(@value.TValue::integer(2L))
  state.push(@value.TValue::integer(3L))

  // Positive indices (1-based from bottom)
  let val1 = try! state.get(1)
  inspect(try? val1.to_integer(), content="Ok(1)")

  // Negative indices (from top)
  let val_top = try! state.get(-1)
  inspect(try? val_top.to_integer(), content="Ok(3)")
}

///|
test "global variables" {
  let state = LuaState::new()
  state.set_global("x", @value.TValue::integer(100L))
  assert_true(state.has_global("x"))
  let val = try! state.get_global("x")
  inspect(try? val.to_integer(), content="Ok(100)")
}

///|
test "stack overflow error" {
  let state = LuaState::new()
  let result = try? state.get(100)
  guard result is Err(StateError::InvalidStackIndex(_)) else {
    fail("Expected InvalidStackIndex error")
  }
}
