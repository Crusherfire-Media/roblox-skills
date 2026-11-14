# Physics, moving things, NPCs, and animation

Anchoring, welding, collision settings, and Humanoid switches change how objects behave
physically. Propose those changes and let the user approve them.

## Design decisions

- **The assembly is the unit of cost.** An assembly (parts joined by welds or joints) is one
  body to the solver, the broadphase, and the sleep system. For a group that moves together,
  weld the parts and anchor only the root: anchoring every part of the group makes each one its
  own assembly, which the docs call less performant and which measured 2x slower to move.
  `[docs]` `[measured]`
- **Keep parts that change size, or come and go, out of an assembly that simulates.** Resizing
  parts of an unanchored assembly (`Size`, `Model:ScaleTo`) while joining parts to it and
  removing them made the engine rebuild the assembly's contacts about once a frame for as long as
  the changes ran (`ContactManagerOnAssemblyAdded` in the MicroProfiler). Which of these triggers
  the rebuild was not isolated. A decorative model welded or jointed to a character and animated
  by scale is the common case. Each rebuild cost more the more parts the assembly overlapped:
  about 0.7 ms with a 22-stud touch volume (a pickup radius) welded to the character, 2.4 to
  2.8 ms with a 128-stud one, whether or not the overlapped parts could be touched. A `Motor6D` or
  kinematic `AnimationConstraint` is a joint, so it keeps the model in the assembly. Anchor the
  model as its own assembly and move it every frame (see "Moving things"). `[in-game]`

  A character carrying a 128-stud touch volume, with `CanTouch` off on the parts around it so
  there are no touches, and a decorative model whose pieces scale in and out about ten times a
  second. Contact work (`Step Contacts` plus the `ContactManager` labels) in ms per frame:
  `[in-game]`

  | How the decorative model is attached | Contact work |
  |---|---|
  | `Motor6D` to a part of the character's assembly | 3.8 |
  | Kinematic `AnimationConstraint` to the same part | 3.85 |
  | Anchored as its own assembly (joint removed) | 0.64 |

- **Anchor what does not need simulating.** Anchored assemblies are never solved. Unanchored
  ones that stop moving fall asleep and cost nothing until something wakes them, so avoid
  writing physics properties (`Anchored`, `CanCollide`, velocities, constraint properties) on
  resting assemblies every frame. `[docs]`
- **Anchor loose props once they settle**, when the design allows it. A few hundred dropped
  boxes cost about 21 ms of physics per frame in one shipped game and about 5 ms once the
  settled ones were anchored. `[reported]`
- **Decide early whether motion is scripted or physical.** A part moved by `CFrame`, `PivotTo`,
  `BulkMoveTo`, or a kinematic joint does not fire `Touched` and does not push or carry other
  bodies. If it must interact physically, it has to be an unanchored assembly driven by
  constraints, which costs solver time and replicates as physics. `[docs]` An anchored part
  moved by `BulkMoveTo` across an anchored part fired no `Touched`, while the same part welded to
  a walking character did, so a touch volume such as a pickup radius stays welded. `[in-game]`
- **NPC crowds: the server keeps data or a bare proxy, and clients build and animate the rigs.**
  A replicated server rig pays instance replication, physics replication, server animation, and
  Humanoid stepping. Sample projects reach 500 to 10,000 NPCs this way where 30 default server
  Humanoids already lagged. `[docs]` `[reported]`
- **Give an NPC a Humanoid only when it needs one.** Roblox's own guidance is that static NPCs
  do not need the class at all. `[docs]`
- **For zone and proximity checks, query from whichever side has fewer items, and build a
  spatial index once zones reach the hundreds.** See "Spatial queries". `[measured]`
- **Use `PivotTo` until movement is a measured bottleneck.** That is the advice of the Roblox
  engineer who maintains these APIs. `[docs]`

## Moving things

**Many independent parts**, each given a new position every frame on the client. 8,000 parts, ms
per frame. "Physics job" is `Stats.PhysicsStepTime`: the script's `PreSimulation` handler plus
the engine work that follows it. `[measured]`

| Method | Script | Physics job | Frame |
|---|---|---|---|
| Per-part `.CFrame` | 26 | 26 | 28 to 32 |
| `BulkMoveTo`, default `FireAllEvents` | 26 | 26 | 31 |
| `BulkMoveTo`, `FireCFrameChanged` | 18.5 | 18.5 | 20 to 24 |
| `Motor6D.Transform` | 2.8 | 12 | 13 to 18 |
| Kinematic `AnimationConstraint.Transform` | 2.8 | 12 | 14 to 17 |

- **`BulkMoveTo` helps only with `Enum.BulkMoveMode.FireCFrameChanged`**, by about 30%. With the
  default mode it cost the same as a loop of `.CFrame` writes: it is that loop, firing fewer
  change events. `[docs]`
- **`Transform` writes are the cheapest way to move many parts, by about 1.5x over the best
  `BulkMoveTo` and 2x over `.CFrame` for the whole frame.** The script-side write is 6x to 9x
  cheaper, but most of the work moves into the engine's batched joint update, so a script timer
  overstates the win.
- `Motor6D` and kinematic `AnimationConstraint` cost the same per frame. The constraint needs two
  attachments per joint and took twice as long to build and destroy.
- **`Transform` has conditions.** Each moved part must be an unanchored member of an assembly
  whose root is anchored, connected by the joint. Write `Transform` in
  `RunService.PreSimulation`. It fires no `Changed` signal. It does not replicate, so it is for
  client-side motion (`networking.md`). A script-created `AnimationConstraint` starts with
  `IsKinematic = false`, so set it to `true`. `[measured]` `[docs]`
- **Never animate joints by writing `C0` or `C1`.** Those are ordinary property writes that
  invalidate the assembly each time. `[docs]`
- **`Bone.Transform` on a skinned mesh** is reported as the cheapest way to move purely visual
  pieces (no collision, no physics, no replication), several times cheaper in script time than
  `BulkMoveTo`. It was not measured here. `[reported]`

**Multi-part objects moved as a whole.** 200 models of 50 parts, ms per frame: `[measured]`

| Setup | Script | Physics job | Frame |
|---|---|---|---|
| Every part anchored, `Model:PivotTo` | 24.7 | 24.5 | 26.6 |
| Every part anchored, one `BulkMoveTo` over all 10,000 parts | 25.6 | 25.6 | 27.6 |
| Welded to an anchored root, `Model:PivotTo` | 12.5 | 12.8 | 14.5 |
| Welded to an anchored root, `root.CFrame = cf` | 9.5 | 9.7 | 11.1 |
| Welded to an anchored root, `BulkMoveTo` over the 200 roots | 9.2 | 9.5 | 11.1 |
| Welded to an unanchored root, driven by `AnimationConstraint.Transform`, one anchor part per model | 0.1 | 13.5 | 15.4 |
| The same, with all 200 models joined to one shared anchor part | 0.1 | 11.2 | 12.7 |

- **Weld the model to one root.** Every welded setup cost about half of what the fully anchored
  model cost with `PivotTo`.
- **A welded model with an anchored root, moved with `BulkMoveTo` or `PivotTo`, is the default.**
  It was the cheapest for the whole frame, it needs no joint, and it works on the server.
- **Driving the welded model through `Transform` removes the script cost (0.1 ms against 9 to
  12 ms) but not the frame cost.** The engine job that applies the transforms took as long as
  the `BulkMoveTo` it replaced. It is still about 1.8x cheaper than `PivotTo` on a fully
  anchored model. Choose it when Luau time is what you are short of, on clients only.
- Give each `Transform`-driven model its own anchor part. Joining all 200 to one shared anchor
  made one 10,000-part assembly and doubled render CPU time (25 to 28 ms against 11 to 12).
- `PivotTo` is not the slow part. On unwelded models it cost the same as a hand-written
  `BulkMoveTo` over every part.
- Cost still grows with the parts in the assembly: about 45 us to move a 50-part welded model
  against 3.3 us for one part.
- Welded models take about twice as long to build.

**Also:**

- Skip the move when the target has not changed (`luau.md`, "The engine boundary"), and
  precompute targets for cyclic motion. `[docs]`
- **To keep an anchored part on a character, move it in `RunService.PreRender`.** The
  render-step callbacks and then `PreRender` run once per drawn frame, right before drawing, so a
  move made there sees the body where it will be drawn. Batch all such parts into one
  `BulkMoveTo` with `FireCFrameChanged`. Jointing the part to the body instead puts it in the
  body's assembly (see "Design decisions"). Not for touch volumes: an anchored one moved this way
  fired no `Touched` (also "Design decisions"), so take only the parts that resize out of the
  assembly. `[docs]` `[in-game]`
- **The other per-frame events may not keep to drawn frames.** In one Studio playtest
  `PreAnimation`, `PreSimulation`, and `PostSimulation` fired two to four times between drawn
  frames, and another Studio session saw up to four `Heartbeat`s per drawn frame. In
  another playtest of the same place, those events, `Stepped`, and `Heartbeat` each fired once
  per drawn frame at 5 to 121 frames a second. What differed was not found, so write code that
  works either way, and use `PreRender` for anything that must happen exactly once per drawn
  frame. `[in-game]`
- **A character that turns with the camera is drawn facing the camera before its `CFrame` is.**
  In first person and mouse lock (`UserGameSettings.RotationType` is `CameraRelative`), the
  engine draws the local character turned to the camera's facing, but writes that facing into
  the root part's `CFrame` only at the next physics step. A part placed from the character's
  `CFrame` then trails it on screen while the camera turns, and jitters when movement turns the
  character between frames, such as strafing in the air. For the local character, also turn the
  placed part about the root part to the camera's flat facing, while `Humanoid.AutoRotate` is on
  and the character is not seated or dead. In one test the root part's `CFrame` was 4° to 10° off
  the camera's facing just before each frame was drawn and matched it exactly just after, and the
  corrected part stayed within 0.05° of its seat. `[in-game]`
- Moving anchored parts on the server every frame replicates every change (`networking.md`).
- Moving a welded assembly out of the way is an engine fast path and a reasonable way to hide
  local objects. It does not work for objects other clients simulate, such as other players'
  characters, because replication moves them back. `[docs]` `[reported]`

## Collision settings

- **`CanCollide`, `CanTouch`, and `CanQuery` are three separate costs.** `CanCollide` removes
  solver contacts, `CanTouch` removes touch detection, `CanQuery` removes the part from raycasts
  and overlap queries (it only takes effect when `CanCollide` is also off). Decorative parts
  should have all three off. `[docs]`
- **`CollisionFidelity` costs CPU and memory, and the cost depends on the shape.** The docs rank
  the modes from cheapest as `Box`, `Hull`, `Default`, `PreciseConvexDecomposition`, and state
  that collision geometry stays in memory even with `CanCollide` off. Set meshes and unions that
  need no collision to `Box` or `Hull`. `[docs]`

  Two test shapes on a server, per solid: `[measured]`

  | Shape and fidelity | Raycast, ns | `GetPartsInPart`, ns | Memory, KB | Time to compute, ms |
  |---|---|---|---|---|
  | Wall with a doorway and window: `Box` | 1,345 | 5,694 | 7.8 | 9 |
  | `Hull` | 2,242 | 9,455 | 8.3 | 9 |
  | `Default` | 2,619 | 14,745 | 11.5 | 11 |
  | `Tunable`, default precision | 2,937 | 11,865 | 14.3 | 334 |
  | `PreciseConvexDecomposition` | 6,411 | 18,210 | 23.3 | 82 |
  | Blob of overlapping spheres and cylinders: `Box` | 1,355 | 6,765 | 22.8 | 27 |
  | `Hull` | 4,255 | 12,669 | 23.1 | 33 |
  | `Default` | 3,283 | 13,760 | 23.8 | 35 |
  | `Tunable`, default precision | 3,609 | 12,713 | 23.6 | 37 |
  | `PreciseConvexDecomposition` | 5,557 | 13,096 | 23.6 | 6,661 |

  Memory is the `BaseParts` tag per solid, which includes the solid's render mesh, so compare
  rows within one shape.

  - `Box` was 2x to 5x cheaper to query than anything else.
  - The ranking above `Box` is not fixed. On the blob, `Hull` was slower to raycast than
    `Default`, and all four modes used the same memory. On the wall, the precise mode cost twice
    the memory of `Default` and 2.4x the raycast time.
  - **Do not pick between `Default` and the precise mode by reputation.** The decomposition
    depends on the mesh, and the precise mode can come out with fewer, better-fitting pieces
    than `Default` on some meshes (reported by this skill's author; it did not happen on these
    two shapes). Look at the result with Studio's collision fidelity visualization and choose
    the mode with the fewest pieces that still fits the gameplay. `[reported]`
  - **`Tunable`** adds a `CollisionPrecision` slider from 0 (the same as `Hull`) to 1
    (near-exact), so the trade can be set per mesh instead of jumping between modes. `[docs]`
  - **The precise mode is slow to compute**: 82 ms to 6.7 s per shape here, against 11 to 35 ms
    for `Default`. That is paid in Studio for placed meshes, and at run time for anything built
    with `UnionAsync` or `SubtractAsync`, so keep precise fidelity out of run-time solid
    modeling.
- **`Touched` is paid per touching pair** and its events travel over the network from the part's
  owner. A multi-part assembly passing through a listener can fire one event per part. Filter
  with `CanTouch = false`, or poll an overlap query a few times a second instead. `[docs]`
- **Touches ignore collision groups unless `Workspace.TouchesUseCollisionGroups` is on.** It is
  off by default and is set only in Studio's Properties window. While it is off, a part with
  `CanTouch` on and a `Touched` listener pays a touch check against every touch-enabled part it
  overlaps, including parts in groups set not to collide with it. A large touch volume, such as
  a pickup radius welded to a character, then touches everything around it: one touched 17 parts
  at 22 studs across and about 190 at 128 studs, and its touch checks (`Step Contacts`) rose from
  about 0.3 ms to 4.4 ms per frame on a desktop. With the setting on it touched only parts in
  groups it collides with. Before turning it on, check that the two parts behind every `Touched`
  handler are in groups that collide. `[docs]` `[in-game]`
- **To see what a part is really touching, call `GetTouchingParts()` on it.** A part with
  `CanCollide` off reports touches only while something is connected to its `Touched`. An overlap
  query with `OverlapParams.CollisionGroup` set filters by collision group, so it hides the
  cross-group touches the setting above lets through. `[docs]` `[in-game]`
- **A touch volume needs a body that stays awake.** An unanchored assembly that stops moving can
  fall asleep. A volume held beside a standing character as its own assembly, by rigid
  `AlignPosition` and `AlignOrientation`, stopped firing `Touched` for new parts inside it, most
  likely because it slept. Welded to the character, whose assembly stays awake, the same volume
  kept working. `[in-game]`
- **`Massless` does nothing for performance.** `[docs]`
- Leave `Workspace.PhysicsSteppingMethod` on its adaptive default, and keep mechanisms simple:
  fewer constraints, and `NoCollisionConstraint` between parts of one mechanism. `[docs]`

## Finding what a client simulates

- **A client simulates only unanchored assemblies it owns**: its character, unanchored parts it
  created, and unanchored server parts it owns (by default the ones near it, `networking.md`).
  A part welded or jointed to an anchored part belongs to an anchored assembly and is never
  simulated, however its own `Anchored` is set, and `GetNetworkOwner` errors on it. `[docs]`
- **List them before suspecting a model.** In a playtest, walk the client's Workspace for parts
  whose `AssemblyRootPart` is not anchored, group them by root, then confirm ownership on the
  server with `GetNetworkOwner`. Rigs and doors that look unanchored can hang off an anchored
  root and cost no simulation. `[in-game]`
- **Parts in a `ViewportFrame` never simulate.** They are outside the Workspace, and a
  `WorldModel` adds animation and spatial queries but not simulation. `[docs]`
- To tell contact cost from solver cost in a dump, see the contact labels at the end of
  `measuring.md`.

## Spatial queries

500 points classified against rotated box zones on a server, ms per pass: `[measured]`

| Zones | Unrelated parts nearby | One query per point | One query per zone | Math over every zone | Math with a grid |
|---|---|---|---|---|---|
| 100 | 0 | 0.92 | 0.51 | 1.78 | 0.030 |
| 1,000 | 0 | 0.82 | 5.74 | 22.8 | 0.135 |
| 1,000 | 20,000 | 0.82 | 15.1 | 17.9 | 0.096 |
| 5,000 | 0 | 1.28 | 56.3 | 88.3 | 0.327 |

- **Query from the side with fewer items.** One small query per point cost about 2 us each and
  barely changed from 100 to 5,000 zones. One query per zone is cheaper only while zones are
  fewer than the points (100 zones against 500 points here), and it grows with the zone count.
- **A grid index plus a point-in-box test was 4x to 30x faster than the best engine approach.**
  Worth building when zone checks run for many entities every frame.
- **A plain loop testing every zone for every point was the slowest option at every size.**
  "Pure math" wins only with a spatial index behind it.
- **Include filters do not prune the search.** With 20,000 unrelated parts in the area, per-zone
  queries got 2.6x slower although the filter excluded every one of them. Cost follows how many
  parts sit inside the query volume. Keep query volumes small.
- Prefer `GetPartBoundsInBox` and `GetPartBoundsInRadius` for per-frame checks. They test
  bounding boxes only; `GetPartsInPart` runs a full geometry test. `[docs]`
- For "is anything here", set `OverlapParams.MaxParts = 1` so the query stops at the first hit.
  `[docs]`
- Create `RaycastParams` and `OverlapParams` once and reuse them. For a large filter, use a
  collision group instead of a long instance list. `[docs]`
- Raycasts are cheap next to script work. Shapecasts cost more than raycasts: use one where it
  replaces many rays. `[docs]`

## Humanoids

150 idle R15 rigs on a server, physics job in ms per frame: `[measured]`

| Setup | Physics job |
|---|---|
| No rigs | 0.14 |
| Default: unanchored, standing | 1.32 |
| Root part anchored | 0.32 |
| Root anchored and `EvaluateStateMachine = false` | 0.18 |
| Root anchored, Humanoid removed | 0.17 |

- **A standing Humanoid costs about 8 us per frame each** on the machine that simulates it.
  1,000 of them is half a frame.
- **For a static NPC, anchor the root and set `Humanoid.EvaluateStateMachine = false`.**
  Anchoring removed about 85% of the cost and turning off the state machine removed the rest,
  matching a rig with no Humanoid. With it off the Humanoid applies no forces and runs no ground
  or obstacle queries, while appearance and scripted state events still work. Disabling
  individual states is not enough for a static NPC. `[measured]` `[docs]`
- For NPCs that do move, disable states they cannot use with `SetStateEnabled` (the docs name
  `Climbing` and `Swimming`), on the machine that simulates them. `[docs]`
- Set `DisplayDistanceType` to `None` on NPC crowds: name and health labels raycast for
  occlusion. `[docs]`
- Humanoid assemblies are exempt from physics throttling, so a server full of them cannot shed
  load. `[docs]`
- `ControllerManager` costs about the same as a Humanoid. `[docs]`
- `RequiresNeck`, `BreakJointsOnDeath`, and `PlatformStand` have no evidence of a performance
  effect.
- Creating or changing avatar models is expensive: pool them (`instances-pooling.md`,
  "Creating instances").

## Animation

- **Animate NPC crowds on clients** (`networking.md`). That is the default for crowds and
  effects, not a ban on server animation: player characters replicate their own animations by
  design, and the engine only replicates a non-player rig's animation when the server plays it.
  `[docs]`
- **The engine already throttles animation for characters simulated on another machine**, based
  on visibility, distance, and frame rate. Check `Animator.EvaluationThrottled` before layering
  procedural transforms, and skip the write on a throttled frame. `[docs]`
- **Procedural joint motion goes in `PreSimulation`**, multiplied into the `Transform` the
  Animator just wrote. `[docs]`
- **`IKControl` cost about 80 us per control in 2023**, so 100 controls is not free. Create and
  drive it on the client: its properties replicate from the server, and only the solve is local
  (`networking.md`). `[docs]`
- **Turn per-frame features off for distant characters.** Held-item IK on every character cost
  12.7 ms per frame on a mid-range phone in one shipped game. Disable IK, procedural motion, and
  similar features beyond a distance, checked on a slow sweep with a margin between the on and
  off distances so they do not flicker. `[reported]`
- **Load each animation once per Animator and reuse the track.** An Animator stops playing new
  animations past 64 simultaneous tracks. `[docs]`
- Animation cost grows with the number of Animators and animated joints. For large crowds, a
  single skinned mesh with a few bones is reported to be far cheaper than a multi-part rig.
  `[reported]`
