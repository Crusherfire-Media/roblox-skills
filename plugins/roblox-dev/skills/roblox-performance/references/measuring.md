# Measuring

How to get numbers that can be trusted before and after a change.

## Which tool answers which question

| Question | Tool | Notes |
|---|---|---|
| Where does frame time go? | A MicroProfiler capture on the playtest server or a client | The first stop when the bottleneck is unknown. Engine-wide: scripts, physics, render, network, GC |
| What made this one frame slow? | A MicroProfiler capture that holds the spike frame | Break that frame down by label, longest first |
| Which Luau function is hot? | A ScriptProfiler profile: Studio's Script Profiler, or `ScriptProfilerService` from Luau | Scripts only. Wrap suspects in `debug.profilebegin("System:Step")` and `debug.profileend()` and filter the result to `System:` |
| How much memory, by category? | `Stats:GetMemoryUsageMbForTag` for each `DeveloperMemoryTag` (`PerfBench.readMemory`), or the Developer Console's Memory tab | Sample it several times over a session to see growth |
| What is taking instance or asset memory? | Studio's Scene Analysis (Window, Performance Summary, Scene Analysis) during a playtest | Attributes memory and triangles to instances, scripts, and assets on the client and the server. Also lists unparented instances |
| How many draw calls and triangles? | `Stats.SceneDrawcallCount`, `SceneTriangleCount`, `ShadowsTriangleCount`, read by running Luau on the playtest client | Delete an object and re-read to price it |
| How many bytes does this send? | `Stats.DataSendKbps` and `DataReceiveKbps`, read on the playtest server or client | Kilobytes per second. See "Bytes" below |
| Is pure Luau variant A faster than B? | Luau run in the edit session, or `PerfBench.compare` | No playtest needed |
| Is engine approach A cheaper than B? | `PerfBench.measureFramesAsync` in a playtest | Compare whole frames, not script time |
| How does it behave on a slow connection? | Simulated latency in a multiplayer playtest (a server and two or more clients) | A solo playtest hides replication fan-out |

A MicroProfiler capture comes from one of three places: LibMP run on the playtest server or
client (load the `rbx-perf-profiling` skill first; add the LibMP ModuleScript to the place,
usually as `ReplicatedStorage.LibMP`, from https://github.com/Roblox/libmp/releases or the
Creator Store), a MicroProfiler capture tool in your Studio MCP if it has one, or a dump the
user saves (see "Reading a live client's MicroProfiler dump"). For a spike, keep the profiler
recording and stop it a few frames after a frame crosses your threshold, so the ring of recent
frames still holds it. However it is taken:

- **Analyze only the frames the workload spans**: about 60 for one second at 60 FPS. The
  MicroProfiler keeps a ring of recent frames, so an analysis that takes the whole ring reaches
  back into frames recorded before the capture began (earlier captures, even an earlier
  playtest, and the profiler's start-up stall) and can report on those instead of the workload
  being measured. `[measured]`
- **Check the result before trusting it**: the frame times should look like the workload (a
  frame of a second or more is the start-up stall, not the game), and the analysis should not
  have stopped at an event limit.
- Filter by a label name (such as `UpdateUILayouts`, or `$Script`) and keep only the top labels
  and groups so the output stays short. Save each full result to a file to compare runs.

This skill says "label" for a MicroProfiler entry; LibMP and other tools call them timers or
scopes. Labels missing from the table at the end of this file are described in the
`rbx-perf-profiling` skill's `references/ALL-SCOPES.md`.

## A fair comparison

- **Same everything except the change.** Same place, same position and camera, same workload,
  same target (server or the same client), same tool settings.
- **Give each variant a fresh world.** Destroy what the previous variant built and wait a second
  before the next. Engine cost depends on what already exists.
- **Enough samples, and the median.** At least 100 frames after 20 to 30 warm-up frames. Report
  the median and the 90th percentile. Use the mean only for workloads that alternate between
  frames.
- **Run each variant at least twice, in the order A, B, B, A.** Whole runs occasionally come back
  5x to 10x slower for no reason tied to the variant (4 of 24 runs in one session). `[measured]`
- **Know the noise.** Between rounds the frame interval moved 15% to 25% while the engine's own
  job timers moved under 7%. Treat a frame-interval difference under about 25%, or an engine
  timer difference under about 7%, as noise until it repeats. `[measured]`
- **Measure at the real scale.** Some effects appear only with large counts (data layout is one,
  see `luau.md`).
- **Move to a new value every iteration.** A benchmark that writes the same `CFrame` or property
  value each time measures the engine's unchanged-value shortcut, not the work. `[reported]`

## Script time is not total cost

A timer around a Luau call sees only the call. Engine calls often queue work that runs later in
the frame: replication, cluster updates, layout, the batched joint update. Writing `Transform`
looked 6x cheaper than `BulkMoveTo` to a script timer and was 1.5x cheaper once the engine's
share was counted (numbers in `physics.md`, "Moving things"). `[measured]`

For anything that touches instances, compare one of these instead of script time:

- `Stats.PhysicsStepTime` (the physics job: `PreSimulation` handlers and the engine work after
  them), `Stats.HeartbeatTime`, and `Stats.RenderCPUFrameTime`, all in seconds.
- The frame interval, but only when the workload is heavy enough to exceed the frame cap.
- A MicroProfiler capture of the label that does the deferred work.

**The frame cap hides small costs.** The Studio client ran capped at 240 FPS while its window
had focus and at 60 FPS at other times, and the cap changed in the middle of a session. Work
that fits under the cap does not show in the frame interval at all. Either scale the workload up
until every variant is clearly above the cap (thousands of items, not hundreds), or read the
engine timers above. `[measured]`

## Pure Luau comparisons

- Luau run in the edit session through the Studio MCP used for these measurements compiled like
  a normal script: same inlining, same builtin fast paths, so pure Luau timings taken there were
  valid. `[measured]` Another MCP may compile differently; when a result decides something, time
  the same code from a ModuleScript too.
- `--!native` and `@native` have no effect in code run directly in the edit session. To measure
  native code, put the code in a ModuleScript and require it. `require` returns the cached copy
  of a module loaded before in that session, so after editing the module require a clone
  (`require(module:Clone())`), which keeps the module's directives in effect. `[measured]`
- Put `--!optimize 2` at the top of any benchmark module. Live games compile at level 2 and the
  docs say Studio defaults to 1, though this Studio build behaved like level 2 either way.
  `[docs]` `[measured]`
- A native speedup measured on a Studio client may not exist on live clients (`luau.md`).
- Feed each variant values the compiler cannot know in advance (read them from a table filled at
  run time) and return a result computed from the loop. Constant inputs get folded away and an
  unused loop can be dropped.

## The harness

[PerfBench.luau](PerfBench.luau) holds the helpers used for this skill's own measurements. It is
a throwaway tool outside the game's module layout: no loader tag, and deleted before the task
ends.

1. In edit mode, create a ModuleScript named `PerfBench` in `ReplicatedStorage`, where the
   server and clients can both reach it, and write the file's contents into it, filling in
   `#Author` and `#Date`.
2. For pure Luau comparisons, call it from Luau run in the edit session, with no playtest. For
   frame measurements, start the playtest, build the workload, and call it from Luau run on the
   playtest server or client:

   ```lua
   local PerfBench = require(game.ReplicatedStorage.PerfBench)
   local result = PerfBench.measureFramesAsync(function(frame)
       -- one frame of the workload
   end, { Frames = 120, Event = "PreRender" }) -- leave Event out on the server
   return PerfBench.formatFrames("variant A", result)
   ```

3. When done: destroy what the benchmarks built, restore anything they changed (a scripted
   camera, for example), stop the playtest, and delete the ModuleScript.

| Function | Use |
|---|---|
| `measureFramesAsync` | Per-frame cost of engine work: script time, frame interval, and the engine's job timers |
| `compare` | Pure Luau variants, nanoseconds per iteration |
| `readMemory`, `formatMemoryDelta` | Bytes per item by memory tag |
| `measureSendRateAsync` | Mean send rate, for the "Bytes" procedure below |
| `formatFrames`, `formatCompare` | One-line summaries to return from a playtest Luau call |

Working rules for Luau run on the playtest server or client:

- Keep each call short: one or two variants per call. With the MCP used here, a call over about
  15 seconds failed with "Unknown error", and a client that was busy for long dropped off as a
  peer until it finished. `[measured]`
- For a benchmark that must run longer, start it with `task.spawn`, have it append results to a
  table, return at once, and read the table from later calls.
- State kept in `_G` is shared with anything else running Luau in the same Studio session. Use
  unique key names and clear them.
- **Check that `step` runs once per frame.** `measureFramesAsync` runs it on `PreSimulation` by
  default, which fired two to four times per drawn frame in one Studio playtest and once per
  frame in another (`physics.md`, "Moving things"). Where it fires more often, the results
  describe steps, not frames. For per-frame numbers on a client pass `{ Event = "PreRender" }`,
  and keep `Transform` writes in a `PreSimulation` handler of their own. `[in-game]`

## Bytes

`Stats.DataSendKbps` on the server is the total sent to all clients, in kilobytes per second,
smoothed over a second or two. To price one remote call or one replicated change:

1. Read the idle rate for a second or two.
2. Start a steady load (N sends per frame) and wait three seconds for the average to settle.
3. Read the loaded rate for two seconds and count the sends in that window.
4. Bytes per send = (loaded - idle) x 1000 / sends per second.

Wait a few seconds between variants so the previous load decays out of the average. Studio's
local server ran at about 240 Hz, so "once per frame" there is four times a live server's 60 Hz.
The sizes measured this way matched the community's wire-size tables, which suggests Studio
serializes traffic the same way a live server does. `[measured]`

The Developer Console's Network tab lists HTTP calls, not remotes. `PhysicsSendKbps` and
`PhysicsReceiveKbps` read zero under the current physics replication pipeline. `[docs]`

## Reading a live client's MicroProfiler dump

A player's machine shows what Studio cannot. In the client's MicroProfiler, Dump, then Dump in
binary format, saves the frames it holds (its frame limit, set in the profiler's menu) as a
`.gprx` file in the Roblox logs folder. At a high frame rate that can be only a second or two,
so the dump has to follow the spike closely: pause the profiler right after it, then dump.

Read it offline with LibMP in Lute, the command-line Luau runtime:

1. Download a Lute release for the platform (`gh release download -R luau-lang/lute`).
2. Download LibMP from https://github.com/Roblox/libmp/releases and save it next to the scripts
   in this skill's `scripts/` folder as `LibMP.luau`. The scripts load it with
   `require("./LibMP")`.
3. Run them from that folder:
   - `lute overview.luau <dump> [topN]`: frame time percentiles, the longest frames with their
     ids, and every frame's time, to see clusters.
   - `lute tree.luau <dump> <first frame> <last frame> [minMs] [maxDepth] [threadMask]`: the call
     tree averaged per frame, one per thread, with every worker thread merged into one tree,
     since jobs move between workers.
   - `lute series.luau <dump> <first frame> <last frame> "<timer>|<timer>"`: per-frame time and
     count for chosen timers, to see a cost run across an animation.
   - `lute counters.luau <dump> [text]`: every counter whose path contains the plain text, such
     as `physics` or `instance_count`, with its first and last value.
   - `lute counter-series.luau <dump> "<counter>" [every]`: one counter's values by frame, every
     25th by default and every one with `every` 1. The counter is a LibMP search mask, where `$`
     anchors the end: `instance_count/part$` or `memory/physics/broadphase$`.

**Timer logs cover fewer frames than the dump.** Each thread keeps its own log, and a busy one
runs out first, so the tree and series scripts can report nothing for most of a dump: one dump of
434 frames had worker-thread timers for only its last 100 or so. Counters have a value for every
frame. When a problem starts before the timer logs do, find the frame it starts on in the
counters: a part count that starts climbing, or physics memory that jumps with no new parts (for
example, a part that grew). `[in-game]`

The `rbx-perf-profiling` skill has the LibMP API, if a question needs more than these scripts.

## What Studio cannot tell you

- **Device frame rate.** Studio runs the client and the server on one desktop. Phones run
  roughly 3x to 4x slower on CPU work. The device emulator changes the screen, not the speed.
  `[docs]` `[reported]`
- **Client memory.** Studio totals include the server and the editor. Compare deltas between two
  scenes, never totals, and take real figures from the Developer Console on a device. `[docs]`
  The same goes for MicroProfiler counters: in a playtest they appear to cover the whole Studio
  process (several times a live client's values), so do not compare a Studio dump's memory and
  instance counters with a live client's. `[in-game]`
- **Live network conditions and player counts.**
- **Engine regressions.** A sudden jump in an engine label with no change in the place can be
  the engine. Check recent DevForum bug reports before restructuring a system around it.
  `[reported]`

## Reproducing a live client's problem in Studio

When a dump shows a cost that a Studio playtest does not, the difference is usually the
player's state or input rather than the engine:

- **Copy the player's state.** A test account rarely has the upgrades, timed boosts, unlocked
  areas, or full inventory a long session builds up, and a cost that grows with one of them
  stays small in Studio. Recreate the values in the playtest through the game's own APIs, or set
  the instance properties they drive, such as the size of a part an upgrade scales.
- **Copy the input rate.** Repeated clicks can stack animations and rebuilds that a single click
  never shows. Drive the system through its public API at the rate a player can click, about ten
  times a second, while capturing.
- **Stand where the player stood.** Costs such as touches and contacts depend on what is nearby.
  Move the character there with `PivotTo` from the server before measuring.
- **Preview a setting scripts cannot change.** Some Workspace properties can only be set in
  Studio's Properties window. Imitate the effect inside the playtest first and measure the gain.
  For example, to preview `TouchesUseCollisionGroups`, turn off `CanTouch` on the parts in groups
  the touch volume does not collide with.

## Budgets

- 16.67 ms per frame at 60 FPS, for the engine and every script together, on client and server.
  Consistency matters more than the average: one 400 ms frame in a second of 10 ms frames reads
  as a stutter. A slow server heartbeat lowers the experience for every client. `[docs]`
- Starting points for low-end phones, all one experienced developer's rules of thumb and not
  limits: about 500 scene draw calls, 500,000 triangles, 150 UI draw calls, under 1.3 GB of
  client memory, under 50 KB/s received per client, 40 to 60 replicated moving assemblies near a
  player, and 150,000 instances or fewer in a place. Derive your own on the weakest device you
  support. `[reported]`

## MicroProfiler labels worth knowing

| Label | What it usually means |
|---|---|
| `$Script` labels, `deferredThreads` | Luau time. Narrow with the ScriptProfiler. In a dump a script shows as `Script_<name>`, so a game run from one client script shares one label |
| `delayedThreads` | Threads resumed from `task.delay` or `task.wait`, such as a range check's loop |
| `WaitingHybridScriptsJob` | Threads resumed after a wait or a remote's reply: work that runs when the server answers |
| `Script_SchedulerHostConfig.default` | Roblox's own core scripts (the dev console among them), not game code |
| `$newindex` (count) | Property writes from Luau. Thousands in one frame mean instances being built |
| `$index` with `Layout` under it | A property read that forced layout, such as `AbsoluteSize` (`ui.md`) |
| `GC` | Garbage collection. Allocation rate or a large live heap (`luau.md`) |
| `physicsStepped`, `stepContacts` | Simulated assemblies, contacts, mechanisms (`physics.md`). The step count per frame grows with frame time (about 21 in a 90 ms frame in one dump), so a physics cost multiplies once frames slow down `[in-game]` |
| `Step Contacts` (under `stepContacts`) | Checking parts that touch or overlap. High while `LDLPGSSolver::solve` stays low points to pairs that touch or overlap without colliding, such as parts with `CanTouch` on in groups that do not collide, rather than collisions (`physics.md`, "Collision settings") `[in-game]` |
| `ContactManagerOnAssemblyAdded`, `ContactManagerOnAssemblyRemoving` | An assembly entering or leaving the physics world, which includes a rebuild while its parts are being resized, joined, or removed. Every frame means something keeps changing a simulated assembly (`physics.md`, "Design decisions") `[in-game]` |
| `stepHumanoid` | Humanoid state machines and sensing (`physics.md`) |
| `stepAnimation` | Animators and animated joints (`physics.md`) |
| `updateInvalidParts`, `updateInstancedClusters` | Part properties changed this frame (`rendering.md`) |
| `updateInvalidatedFastClusters` | Avatar or skinned-mesh models created or changed. Over 4 ms is a problem (`instances-pooling.md`) |
| `UpdateUILayouts`, `Rebuild Z-order list` | UI resized, repositioned, added, or removed (`ui.md`) |
| `Post-Layout Event Dispatch` | Change events from a layout pass reaching listeners, such as size listeners (`ui.md`) |
| `Text Shaping+Layout` (count) | Labels shaped again. Hundreds a frame mean text changing pixel size, usually a scale animation (`ui.md`) |
| `UITextureJob::updateAndGetFramebuffer`, `new Texture` | CanvasGroup textures made again, for example when a group changes size (`ui.md`) |
| `LocalizationService::attemptLocalization`, `Stat::send` | `Text` writes on labels with `AutoLocalize` on (`ui.md`) |
| `Pass2d`, `fillGuiVertices` | UI appearance being rebuilt (`ui.md`) |
| `Pass3dAdorn` | BillboardGuis and Humanoid name labels (`ui.md`) |
| `UpdateInput` | Input events and UI hit-testing (`ui.md`) |
| `Replicator/ProcessPackets` | Incoming replication: instance creation or bulk property changes (`networking.md`) |
| `ModelCompleteness Mega Job` | Many instances added or removed at once (`instances-pooling.md`) |
| `ShadowMapSystem`, `LightGridCPU` | Shadow casters or lights moving (`rendering.md`) |
| `updateParticles` | Particle simulation (`rendering.md`) |
| `Perform/Present/waitUntilCompleted` | Waiting on the GPU: the frame is GPU-bound |
