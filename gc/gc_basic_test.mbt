// Basic tests for Lua garbage collector

///|
test "create new GC" {
  let gc = GC::new()
  let stats = gc.stats()
  inspect(stats.num_objects, content="0")
  inspect(stats.num_collections, content="0")
}

///|
test "allocate objects" {
  let gc = GC::new()
  let obj1 = try! gc.allocate(100)
  let obj2 = try! gc.allocate(200)
  let stats = gc.stats()
  inspect(stats.num_objects, content="2")
  assert_true(stats.total_bytes >= 300)
}

///|
test "mark and sweep" {
  let gc = GC::new()
  let obj1 = try! gc.allocate(100)
  let _obj2 = try! gc.allocate(200)

  // Mark obj1 as reachable
  gc.mark(obj1)

  // Collect should free obj2
  let freed = gc.collect()
  assert_true(freed > 0)
}

///|
test "GC statistics" {
  let gc = GC::new()
  ignore(try! gc.allocate(100))
  ignore(try! gc.allocate(200))
  let stats1 = gc.stats()
  inspect(stats1.num_objects, content="2")
  ignore(gc.full_collect())
  let stats2 = gc.stats()
  inspect(stats2.num_collections, content="1")
}

///|
test "GC configuration" {
  let gc = GC::new()
  gc.set_pause(200)
  gc.set_step_mul(150)

  // Configuration should not crash
  ignore(try! gc.allocate(100))
}
