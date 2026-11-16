# Luau: scripts, data, memory, and garbage

## Design decisions

- **React to events instead of polling.** Per-frame code is the right tool only for things that
  change every frame. `[docs]`
- **One loop over many entities, not one thread or connection per entity.** The scheduler does
  not throttle: resume 5,000 threads in a frame and it runs 5,000 threads. A `task.spawn` costs
  about 1.7 us against 8 ns for a direct call. `[docs]` `[measured]`
- **Pick the data structure for the access pattern.**
  - Membership tests go in a set (`set[item] = true`). A set lookup took 25 ns where
    `table.find` over 1,000 items took 1,723 ns, 70x. `[measured]`
  - Remove from an unordered array by swapping in the last element. `table.remove(t, i)` from
    the middle shifts the tail, and `table.remove(t, 1)` makes a queue quadratic. `[docs]`
  - "What is near X" goes in a spatial index. A uniform grid keyed by `Vector3` cell coordinates
    is the cheapest useful one: vectors hash by value with no allocation (numbers in
    `physics.md`, "Spatial queries"). `[docs]` `[measured]`
  - Build a long string by collecting pieces and calling `table.concat` once. Appending to one
    string in a loop is quadratic. A single `a .. b .. c` expression is fine. `[docs]`
- **Skip work whose inputs did not change.** Keep a dirty flag or compare with last frame's
  input before an expensive call. Idle entities should cost nearly nothing. `[docs]`
- **Announce a bulk operation once, with the whole list.** N single-item events multiply by
  every listener: in one shipped game a 30-item fill fired 30 signals into about 110 connections
  each and cost a 65 ms frame. Give bulk operations a bulk signal, and dispatch by owner instead
  of one global signal that every listener filters. `[reported]`
- **Run a repeated recompute once per cycle.** When many events in one frame each trigger the
  same derived update, set a flag and do it once after they have all arrived. N events
  re-stacking a pile N times was a 204 ms client spike in one shipped game. `[reported]`
- **Accumulate in locals, then write an observed or replicated value once.** Every write to a
  property, attribute, or reactive store runs its listeners. A 1,500-item sale that updated
  totals per item made about 11,600 store writes in one frame, 160 ms of a 222 ms spike. Sum
  first, write the result. `[reported]`
- **Slice long jobs across frames with an explicit allowance.** Process items until an item
  count or an `os.clock()` allowance (1 to 5 ms) runs out, save the cursor, continue next frame.
  Check the clock every N items, not every item. `task.defer` and deferred signals run later in
  the same frame, so they do not spread work. `[docs]`
  - Count the allowance in a unit that tracks cost. "Ten containers per frame" means nothing
    when one container holds five instances and another five thousand. `[reported]`
  - Decide whether to yield before taking the next unit, not after it. `[reported]`
  - When several coroutines share one allowance, reset it from a frame counter, not when one of
    them runs out. `[reported]`
  - Slicing changes behavior, so raise it with the user first: for several frames the job is
    half done. Snapshot what the job will touch before the first yield, record the logical
    result (sold, consumed, saved) before the slow part, and keep paths that must be atomic free
    of yields. Shipped games have had item duplication and half-built state from exactly this.
    `[reported]`
- **Keep state in Luau tables.** Crossing into the engine costs 8x to 50x a table access (see
  below), and instances carry memory and replication cost (`instances-pooling.md`). `[measured]`
- **Parallel Luau is for many small per-frame jobs.** It cannot run a long job in the
  background: the frame waits for every parallel section. It pays only when each job is large
  next to the cost of dispatching it and moving its data. It needs many Actors (dozens or more),
  each with its own script, which the `game-architecture` skill treats as the user's decision.
  Each Actor is its own VM: messages are copied, modules load again per Actor, a `SharedTable`
  is about 10x slower than a table, and a buffer cannot be shared. No break-even figure is
  published, so measure. `[docs]`
- **Native code generation is for number crunching.** `@native` on a hot function gave 2x on a
  call-heavy loop and 5.5x on a math loop. It does nothing for code that mostly calls engine
  APIs. It costs compile time and memory against a limit shared by the whole game, so put it on
  the few functions a profile names, annotate their parameters (especially `Vector3`, `buffer`,
  and engine types), and confirm the result with the Script Profiler. Any use of `getfenv` or
  `setfenv` in a script switches it off, along with the compiler's other fast paths. `[docs]`
  `[measured]`

  Treat native code as a server feature. It ran on the Studio playtest client, but the docs
  support it only for server scripts and for client scripts on Android, and one developer saw an
  effect run 6x slower on a live client than in Studio because the native build did not apply
  there. `[docs]` `[reported]`

## The engine boundary

Costs on a playtest server, in nanoseconds (loop overhead included). `[measured]`

| Read or call | ns | | Write | ns |
|---|---|---|---|---|
| Luau table field | 7 | | Luau table field | 11 |
| `part.Transparency` | 55 | | Property, same value as before | 75 |
| `numberValue.Value` | 59 | | `NumberValue.Value`, detached | 93 |
| `part.Position.X` | 62 | | Property, detached instance | 107 |
| `part:IsA("BasePart")` | 65 | | Attribute, detached instance | 309 |
| `part:HasTag(tag)` | 87 | | `NumberValue.Value`, parented | 548 |
| `folder.Child` | 87 | | Property, parented | 585 |
| `part.CFrame.X` | 91 | | Attribute, parented | 1,532 |
| `part:GetAttribute("X")` | 102 | | `part.CFrame`, parented | 2,366 |
| `folder:FindFirstChild("Child")` | 122 | | | |
| `game:GetService("RunService")` | 203 | | | |
| `folder:GetChildren()`, 22 children | 469 | | | |

What follows from it:

- None of this matters at tens or hundreds of calls per frame. It matters when a per-frame loop
  touches thousands of instances.
- In a hot loop, read a property once into a local, and hold instance references in variables
  instead of looking them up.
- `GetChildren`, `GetDescendants`, and `GetTagged` build a new array on every call. For a set
  that is read every frame, keep a Luau array updated from `ChildAdded` and `ChildRemoved` or the
  tag's added and removed signals. `[docs]`
- **A same-value write to a plain property is cheap (75 ns): the engine detects it.** Compare
  first when the write is more than a plain property (toggling a weld, `PivotTo`, a method
  call), or when the check lets you skip computing the value. Redundant weld toggles were 72% of
  the per-item cost in one profiled path. `[measured]` `[reported]`
- Prefer one call that moves a lot of data over many small calls. `[docs]`
- `GetAttribute` per entity per frame adds up (about 100 ns each). Mirror the value into Luau
  state and update it from `GetAttributeChangedSignal`. `[measured]`
- Keep engine reads out of sort comparators. A comparator that read an attribute on both sides
  made about 4,900 engine calls to sort 300 items. Read each key once into a plain table and
  sort that. `[reported]`
- A `warn` or `print` inside a per-frame path can cost more than the problem it reports.
  Rate-limit it. `[reported]`

## Data layout

N entities with four numeric fields, updating one field from another. Nanoseconds per entity,
visited in allocation order / in a shuffled order. `[measured]`

| N | Mode | Array of tables | Parallel arrays | `f32` buffer | `Vector3` arrays |
|---|---|---|---|---|---|
| 1,000 | interpreted | 22 / 27 | 15 / 15 | 25 / 27 | 17 / 17 |
| 1,000 | native | 17 / 19 | 10 / 10 | 13 / 13 | 9 / 8 |
| 100,000 | interpreted | 36 / 345 | 16 / 24 | 25 / 36 | 16 / 30 |
| 100,000 | native | 26 / 186 | 10 / 16 | 13 / 13 | 10 / 14 |

Bytes per entity: array of tables 192, parallel arrays 64, `f32` buffer 16, two `Vector3` arrays
32.

- **Default to an array of tables with named fields.** It is the readable layout, and at
  hundreds or a few thousand entities the difference is a few microseconds per frame. Named
  fields are as fast as numeric indexes for a small record, so there is nothing to gain from
  `t[1]`, `t[2]`. `[reported]`
- **Switch to parallel arrays** when a profiled loop walks tens of thousands of entities, or
  when memory per entity matters. They were 1.5x to 2.5x faster at every size and 3x smaller.
- **Cache locality is real only at scale.** At 1,000 entities visit order made no difference. At
  100,000 a scattered walk over an array of tables was 10x slower than an in-order one. Entities
  created at different times end up scattered, so large long-lived sets are where compact
  layouts pay.
- **Buffers are for memory and bytes**, and no faster than parallel arrays
  (`buffers-serialization.md`).
- Keep an object's set of fields fixed for its life: field access is cached by shape. `[docs]`

## Allocation and garbage collection

Luau's collector is incremental and not generational: every cycle re-marks everything that is
alive. So garbage costs twice, by how fast you allocate (how often cycles run) and by how much
is alive (how long each cycle takes). `[docs]`

What allocates, and what does not. `[measured]` (closure and coroutine sizes are from the Luau
source)

| Value | Time to create | Heap bytes |
|---|---|---|
| `Vector3.new` | 22 ns | 0 (stored in the value itself) |
| `Vector2.new` | 45 ns | 22 |
| `Color3.new` | 49 ns | 26 |
| `CFrame.new` | 53 ns | 62 |
| `UDim2.new` | 58 ns | 30 |
| `{ X =, Y =, Z = }` | 58 ns | 175 |
| A closure that captures a per-call local | 32 ns | 32 plus 16 per captured variable |
| A closure that captures nothing | 7 ns | 0 (created once and reused) |
| `task.spawn(fn)` | 1,741 ns | about 1 KB (a new coroutine) |

Numbers, booleans, and `Vector3` are free. Strings built in a loop, tables, capturing closures,
and every other datatype allocate.

- **Reuse a scratch table inside a hot loop** when a profile shows the `GC` label or the loop's
  own allocation. One reused table cost 31 ns per entity against 56 ns for a fresh one, and a
  `Vector3` cost 20 ns. At 10,000 entities per frame that is 0.3 ms saved: worth it there, noise
  anywhere smaller. `[measured]`
- **Refill with `table.clear(t)`** instead of assigning `{}` when the size stays about the same.
  It keeps the capacity. `[docs]`
- **A big live heap makes all allocation slower.** With 400,000 extra tables alive, the same
  fresh-table loop cost 118 ns instead of 56. Idle object pools, oversized caches, and tables
  that only grow are a standing tax, not free memory. `[measured]`
- **Pool Luau objects only when a profile shows allocation or `GC` in that path.** A pool adds
  bookkeeping, stale-state bugs, and live heap. Pooling instances is a separate question
  (`instances-pooling.md`). `[docs]`
- **Keep megabytes of long-lived numbers in a buffer.** The collector scans every slot of a
  table and skips a buffer's contents. `[docs]`
- **Sources of GC hitches**: very large weak tables, very large single tables, and thousands of
  live coroutines are processed in one indivisible step. `[docs]`
- Measure with `gcinfo()` (kilobytes, fluctuates as the collector runs), the `LuaHeap` memory
  tag, and the MicroProfiler `GC` label. A forced full collection is not available. `[docs]`

## Leaks

Memory that grows over a session is usually one of these. `[docs]`

- **A connection whose handler references the instance it is connected to.** The engine holds
  the handler, the handler holds the instance, and the collector cannot see through that cycle.
  Disconnect, or `Destroy` the instance.
- **`Parent = nil` instead of `Destroy()`.** Only `Destroy` disconnects connections and recurses
  into descendants. After destroying, drop your own references too: a destroyed instance stays
  in memory while any variable, table, or closure still holds it.
- **Characters and departed players.** `Workspace.PlayerCharacterDestroyBehavior` has to be set
  to `Enabled` by hand: the planned default change was suspended, and places still ship without
  it. Propose setting it, since it changes when characters are destroyed.
- **Per-player and per-entity tables that are never cleared.** Remove the entry in
  `PlayerRemoving` or the entity's teardown.
- **Weak tables keyed by instances** do not follow instance lifetime (the style guide's "Weak
  tables", in `references/classes.md`). Clean up on `Destroying` or the owning system's teardown.
- **Threads parked forever**, such as a `task.wait(math.huge)` or a wait on a signal that never
  fires, pin everything on their stack.
- **`AnimationTrack` and `Animation` references kept after the model is gone**, and sounds that
  stay referenced.

Find them with Luau heap snapshots in the Developer Console (the Unique References view lists
instances held only by scripts), Studio's Scene Analysis (unparented instances), and
`Stats.InstanceCount` sampled over time.

## Line-level habits: only in a measured hot path

Each of these is small. Apply them inside a loop a profile has named.

- Leave `assert` out of the loop and check the inputs once before it (the style guide's
  "Error handling" section). A constant-message `assert` cost 5 to 9 ns per call, and one that
  builds its message cost 130 ns. `[measured]`
- Append with `table.insert(t, v)`, or preallocate with `table.create(n)` when the count is
  known. `[docs]`
- Call string builtins as functions: `string.byte(s, i)`, not `s:byte(i)`. `[docs]`
- `pcall` adds about 45 ns on the success path. It is fine around real work and wasteful around
  every item of a huge loop. `[measured]`
- Keep data in `Vector3` form when the math is vector math. Packing three loose numbers into a
  vector just to call `.Magnitude` is slower than doing the arithmetic. `[docs]`
- Only `local` functions in the same module can be inlined, and only at `--!optimize 2`. `[docs]`

## Myths

Do not apply these. They cost readability and gain nothing.

- **Caching methods in locals** (`local m = obj.Method`). Method calls already have a fast path.
  `[docs]`
- **A hand-kept length counter because `#t` is slow.** `#t` is cached. `[docs]`
- **`t[#t + 1] = v` over `table.insert`.** Reversed since 2021. `[docs]`
- **Type annotations make interpreted code faster.** They feed native code generation only.
  `[docs]`
- **Hand-written `sqrt` or `sin` approximations.** The builtins are fast paths; a Luau
  approximation runs more bytecode. `[reported]`
- **`BindableEvent` as the fast way to signal inside one VM.** A pure-Luau signal was 4x to 15x
  faster per operation in one published benchmark, and bindables copy table arguments.
  `[reported]`
- **"Buffers and pools eliminate garbage collection."** The buffer or pool is itself collected,
  wrappers allocate, and a long-lived pool is re-marked every cycle. `[docs]`
