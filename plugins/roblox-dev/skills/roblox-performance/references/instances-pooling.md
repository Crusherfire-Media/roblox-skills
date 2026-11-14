# Instances and pooling

## Design decisions

- **Treat instance count as a budget** (`measuring.md`, "Budgets"). Every instance costs memory,
  is serialized to joining clients, and adds to join time. Measured on a server: `[measured]`

  | Instance | Bytes |
  |---|---|
  | `Folder`, `Configuration`, `NumberValue`, `StringValue` | about 600 |
  | `Attachment` | about 770 |
  | `Part` in `ServerStorage` | about 1,600 or more |
  | Anchored `Part` in `Workspace` | 3,000 to 6,000 |
  | One tag on an instance | 128 |
  | A value in a Luau table | 16 to 32 |

  The "40 bytes per part" figure sometimes quoted is only the Luau-side handle.
- **Keep state in Luau tables and use instances for what the engine must render, simulate, or
  replicate.** A design that stores each entity's data or components as a tree of `Folder`,
  `Configuration`, and value objects pays 20x or more the memory per value, replicates all of
  it, has to wait for it on the client, and reads it through the engine boundary. Decide where
  state lives before building the system.

  In one shipped game that stored items and their components as instances, 13% of a
  15,000-instance template was data-only instances, and every bulk change became a burst of
  replicated creation or destruction. That forced pacing code, caches beside the instance tree
  that lag it by a cycle, and manual eviction of instance-keyed tables. Most of the game's later
  optimizations treat symptoms of that one choice. `[reported]`
- **Create purely visual instances on clients** (`networking.md`).
- **Mark short-lived states with an attribute or a table entry**, not by creating and destroying
  a marker instance such as a `Folder` named "Stunned". `[docs]`
- **Pool only what a profile shows being created often.** See "Pooling".

## Creating instances

- **Set every property, then `Parent`, then connect signals.** Once an instance is in the
  DataModel, each property write notifies replication, physics, and rendering: one write cost 5x
  as much on a parented instance as on a detached one. `[docs]` `[measured]`
- **Build a tree detached and parent its root once.** For 2,000 parts with six properties:
  `[measured]`

  | Order | ms |
  |---|---|
  | Build under a detached `Model`, parent the model once | 23 to 25 |
  | Set properties, then parent each part | 33 to 43 |
  | Parent first (or `Instance.new("Part", parent)`), then set properties | 56 to 67 |

  Parenting first cost about 1.6x parenting last and 2.5x the detached build. The 40x to 100x
  figures in circulation are from 2016. The second argument of `Instance.new` is not special: it
  is slow only because it parents before the properties are set. `[docs]`
- **A helper that builds from a property table must assign `Parent` last.** Table iteration
  order is not defined. `[docs]`
- **`Instance.new`, `Clone`, and `Instance.fromExisting` are within about 2x of each other** for
  a simple instance. Choose by behavior. `[reported]`
- **Cut the instances you do not need before spreading the ones you do.** One shipped game
  cloned a 15,000-instance template and destroyed 10,400 of them in the same frame only to read
  their positions. Storing those positions as data ahead of time removed 70% of the clone, which
  was a bigger win than any pacing. `[reported]`
- **Spread large trees across frames.** Cloning a map or spawning hundreds of models lands in
  one frame on the server and again on every client. Build detached, then parent a fixed number
  of instances per frame from a queue (the same game used 400 to 800 per frame), never
  splitting one model across frames. For work that can be predicted, pre-build during quiet
  moments. The slicing rules, and why this is a behavior change to raise with the user, are in
  `luau.md` under "Design decisions". `[docs]` `[reported]`
- **Models with a Humanoid or skinned meshes are expensive to create and to change.** They
  render as one cluster that is rebuilt on creation and on many changes (scale, hierarchy),
  worst with layered clothing. `updateInvalidatedFastClusters` over 4 ms in the MicroProfiler is
  the signal. Pool them instead of respawning, and attach extra parts outside the avatar model.
  `[docs]`

## Removing instances

- **`Destroy()` is the disposal call.** It unparents, locks, disconnects every connection, and
  recurses. Then drop your own references, since a destroyed instance stays in memory while Luau
  still holds it. `[docs]`
- **Destroying hundreds of instances in one frame spikes.** Hide or unparent them at once and
  destroy a fixed number per frame from a queue. For those frames "gone" and "destroyed"
  disagree, so follow the slicing rules in `luau.md`. `[reported]`
- **Prefer `task.delay(seconds, instance.Destroy, instance)` to `Debris:AddItem`.** `Debris`
  destroys the oldest item early once 1,000 are queued, and Roblox staff describe it as slower
  than the Luau equivalent. Use `Debris` only when the cleanup must outlive the calling script.
  (Passing the method this way avoids creating a closure per call.) `[docs]`

## Pooling

A pool trades memory and reset logic for skipping creation and teardown. For plain parts,
returning one to a pool by moving it cost about a third of destroying and re-cloning it: a real
gain, not orders of magnitude. `[measured]`

**When it is worth it.** A profile shows instance creation or destruction in the frame (hundreds
per second, or a `ModelCompleteness` or cluster-rebuild label), or NPC models respawn often
(the one case Roblox's docs recommend outright). Bullets, hit effects, damage numbers, and list
rows are the usual candidates. `[docs]`

**How to hide a pooled part.** 4,000 parts hidden and shown on alternate frames: `[measured]`

| Method | Script per part | Frame, ms |
|---|---|---|
| `Transparency` or `LocalTransparencyModifier`, 0 and 1 | 0.8 us | 6.4 to 7.0 |
| `Transform` on a kinematic joint, far away and back | 0.3 us | 8.3 to 8.9 |
| `BulkMoveTo` far away and back | 4.3 us | 20 to 21 |
| `.CFrame` far away and back | 5.3 us | 24 |
| `Parent = nil` and back | 6.8 us | 35 |
| `Destroy`, then `Clone` and parent | 29 us per cycle | 68 |

- **Toggling transparency is the cheapest for the whole frame.** `Transparency` and
  `LocalTransparencyModifier` cost the same. The part stays where it is, so it still collides
  and still answers queries: use this for parts with `CanCollide`, `CanQuery`, and `CanTouch`
  off, or switch those along with it.
- **Parking by `Transform` is the cheapest way to move a pooled part out of the world**, about
  2.4x cheaper than `BulkMoveTo` and close to the transparency toggle (25% more frame time, a
  third of the script time). The part must be unanchored and joined to an anchored part by a
  `Motor6D` or a kinematic `AnimationConstraint`, and it works on clients only (the conditions
  are in `physics.md`, "Moving things").
- Without a joint, park with `BulkMoveTo` and `Enum.BulkMoveMode.FireCFrameChanged`. It beat
  reparenting by about 1.7x.
- These are plain `Part`s. Meshes with textures and multi-part models may rank the reparenting
  rows differently, so measure with the real object.
- For a multi-part object, weld it to one root and move the root (`physics.md`).

**Rules for a correct pool.**

- **A parked instance is still live.** On return: anchor it, zero its velocities, disconnect
  what the last user connected, and disable trails before the move. On fetch: set every property
  the last user could have changed. Stale state is the classic pool bug. `[reported]`
- **Park outside the map, not at extreme coordinates.** Parts parked very far away (1e8 studs
  and beyond in the reports) have caused lighting, shadow, and rendering flicker across the
  whole scene in several games. Park just far enough to be out of sight and out of reach, a few
  thousand studs past the map's edge, and have the user check for flicker in a playtest after
  any change to the parking spot. `[reported]`
- **Keep visual pools on the client.** A server-side pool parked far away sits outside every
  client's streaming radius, so fetched parts have to stream in first, and the pool itself
  replicates. `[reported]`
- **Size the pool to the measured peak.** Growing at runtime is the same creation burst the pool
  exists to avoid.
- **Fill it from `Start` or a spawned thread, never at require time** (the `game-architecture`
  skill's lifecycle rules), building its container detached and parenting it once.

**Other things worth reusing.**

- **Particle effects**: keep the emitter, move its attachment, and call `:Emit(count)`
  (`rendering.md`, "Particles, beams, and effects").
- **UI rows and popups**: reuse them (`ui.md`, "Design decisions").
- **Luau tables**: only when a profile shows `GC` or allocation in that path (`luau.md`).

**When a pool hurts.**

- Idle instances hold memory, and each one is 0.6 to 6 KB.
- Parked parts stay in physics and render bookkeeping.
- A server-side pool adds to join-time replication.
- Reset code is a permanent source of bugs.
- For objects created a few times a second, there is nothing to save.

## Data on instances: attributes, value objects, tags

Cost per operation (read and write costs are from the table in `luau.md`). `[measured]`

| | Read | Write (parented) | Bytes when it replicates |
|---|---|---|---|
| Luau table field | 7 ns | 11 ns | does not replicate |
| Property | 55 ns | 585 ns | varies |
| `NumberValue.Value` | 59 ns | 548 ns | 18 |
| Attribute | 102 ns | 1,532 ns | 24 |

- **State that changes every frame for many entities belongs in tables.** One developer raised
  2,000 enemies from 50 to 73 FPS by removing two `SetAttribute` calls per enemy per frame.
  `[reported]`
- **Use an attribute for occasional per-instance state that clients or Studio users need to
  see.** It adds no instance. A value object is a whole extra instance (about 600 bytes) per
  value. `[measured]`
- **Check one tag with `HasTag`**, not `GetTags`. For tagged sets read every frame, see
  `luau.md`, "The engine boundary". `[docs]`
