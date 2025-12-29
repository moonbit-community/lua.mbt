// Lua Garbage Collector Implementation
// Based on Lua 5.4's lgc.c
// Implements tri-color mark-and-sweep garbage collection

///|
/// Object metadata tracked by GC
struct GCObject {
  size : Int
  color : GCColor
} derive(Show)

///|
/// Garbage collector state
pub struct GC {
  // Map from object ID to object metadata
  objects : Map[Int, GCObject]

  // Next object ID to allocate
  mut next_id : Int

  // Total bytes allocated
  mut total_bytes : Int

  // GC threshold (trigger collection when total_bytes exceeds this)
  mut gc_threshold : Int

  // Number of collections performed
  mut num_collections : Int

  // Configuration parameters
  mut pause : Int // Percentage to wait before next GC (default 200%)
  mut step_mul : Int // Step multiplier (default 200%)
} derive(Show)

///|
/// Create a new GC
pub fn GC::new() -> GC {
  GC::{
    objects: {},
    next_id: 1,
    total_bytes: 0,
    gc_threshold: 1024, // Start with 1KB threshold
    num_collections: 0,
    pause: 200,
    step_mul: 200,
  }
}

///|
/// Allocate a new GC object (returns object ID)
pub fn GC::allocate(self : GC, size : Int) -> Int raise GCError {
  if size < 0 {
    raise GCError::OutOfMemory
  }
  let obj_id = self.next_id
  self.next_id = self.next_id + 1

  // Create new object with White color (unmarked)
  self.objects[obj_id] = GCObject::{ size, color: GCColor::White }
  self.total_bytes = self.total_bytes + size

  // Optionally trigger GC if threshold exceeded
  if self.total_bytes > self.gc_threshold {
    ignore(self.collect())
  }
  obj_id
}

///|
/// Mark an object as reachable (set to Black)
pub fn GC::mark(self : GC, object_id : Int) -> Unit {
  match self.objects.get(object_id) {
    Some(obj) =>
      // Mark as black (reachable and processed)
      self.objects[object_id] = GCObject::{
        size: obj.size,
        color: GCColor::Black,
      }
    None => () // Object doesn't exist, ignore
  }
}

///|
/// Run a garbage collection cycle (sweep phase)
pub fn GC::collect(self : GC) -> Int {
  let mut freed_bytes = 0

  // Sweep: remove all White (unmarked) objects
  let to_remove : Array[Int] = []
  for obj_id, obj in self.objects {
    if obj.color == GCColor::White {
      to_remove.push(obj_id)
      freed_bytes = freed_bytes + obj.size
    }
  }

  // Remove collected objects
  for obj_id in to_remove {
    self.objects.remove(obj_id)
  }

  // Update total bytes
  self.total_bytes = self.total_bytes - freed_bytes

  // Reset all remaining objects to White for next cycle
  for obj_id, obj in self.objects {
    self.objects[obj_id] = GCObject::{ size: obj.size, color: GCColor::White }
  }

  // Update statistics
  self.num_collections = self.num_collections + 1

  // Adjust threshold based on pause parameter
  // threshold = total_bytes * (pause / 100)
  self.gc_threshold = self.total_bytes * self.pause / 100
  if self.gc_threshold < 1024 {
    self.gc_threshold = 1024 // Minimum threshold
  }
  freed_bytes
}

///|
/// Get GC statistics
pub fn GC::stats(self : GC) -> GCStats {
  GCStats::{
    total_bytes: self.total_bytes,
    gc_threshold: self.gc_threshold,
    num_objects: self.objects.length(),
    num_collections: self.num_collections,
  }
}

///|
/// Set GC pause (how long GC waits before collecting)
pub fn GC::set_pause(self : GC, pause : Int) -> Unit {
  self.pause = pause
}

///|
/// Set GC step multiplier (how much work GC does per step)
pub fn GC::set_step_mul(self : GC, mul : Int) -> Unit {
  self.step_mul = mul
}

///|
/// Force a full garbage collection
pub fn GC::full_collect(self : GC) -> Int {
  // Full collection: mark all objects as White, then collect
  for obj_id, obj in self.objects {
    self.objects[obj_id] = GCObject::{ size: obj.size, color: GCColor::White }
  }
  self.collect()
}
