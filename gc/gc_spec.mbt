// Lua Garbage Collector Specification
// Based on Lua 5.4's lgc.h
// Manages memory and garbage collection for Lua values

///|
/// GC errors
pub(all) suberror GCError {
  OutOfMemory
  InvalidObject
} derive(Eq, Show, ToJson)

///|
/// GC object colors (tri-color marking)
pub(all) enum GCColor {
  White
  Gray
  Black
} derive(Eq, Show, ToJson)

///|
/// GC statistics
pub(all) struct GCStats {
  total_bytes : Int
  gc_threshold : Int
  num_objects : Int
  num_collections : Int
} derive(Eq, Show, ToJson)

///|
/// Garbage collector state
#declaration_only
pub type GC

///|
/// Create a new GC
#declaration_only
pub fn GC::new() -> GC {
  ...
}

///|
/// Allocate a new GC object (for strings, tables, etc.)
#declaration_only
pub fn GC::allocate(self : GC, size : Int) -> Int raise GCError {
  ...
}

///|
/// Mark an object as reachable
#declaration_only
pub fn GC::mark(self : GC, object_id : Int) -> Unit {
  ...
}

///|
/// Run a garbage collection cycle
#declaration_only
pub fn GC::collect(self : GC) -> Int {
  ...
}

///|
/// Get GC statistics
#declaration_only
pub fn GC::stats(self : GC) -> GCStats {
  ...
}

///|
/// Set GC pause (how long GC waits before collecting)
#declaration_only
pub fn GC::set_pause(self : GC, pause : Int) -> Unit {
  ...
}

///|
/// Set GC step multiplier (how much work GC does per step)
#declaration_only
pub fn GC::set_step_mul(self : GC, mul : Int) -> Unit {
  ...
}

///|
/// Force a full garbage collection
#declaration_only
pub fn GC::full_collect(self : GC) -> Int {
  ...
}
