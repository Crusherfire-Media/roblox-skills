---
name: rbx-perf-profiling
description: Analyze fine-grained performance data provided by the MicroProfiler through the LibMP Luau module. Use it to investigate CPU and GPU bottlenecks, identify the causes of frame-time spikes, and analyze memory allocations by subsystem.
---

# Roblox Performance Profiling

LibMP is a Luau module that exposes everything the MicroProfiler (MP) shows (frames, scopes,
groups, threads, counters) to scripts on clients, servers, and in Studio, in both Play and Edit
modes. This file holds the rules for driving LibMP from an agent: through a Studio MCP that can
run Luau in the edit session or in a playtest, or by handing the user a snippet for the Studio
command bar. It also condenses Roblox's own guide.

The three upstream files come from [Roblox/libmp](https://github.com/Roblox/libmp) under the MIT
License, Copyright (c) 2026 Roblox Corporation. The license text ships next to them in
[references/LICENSE-libmp.txt](references/LICENSE-libmp.txt).

| File | What it holds | Read it |
|---|---|---|
| [references/libmp-guide.md](references/libmp-guide.md) | Roblox's upstream guide (their `SKILL.md`), unmodified except that its Studio MCP tool name is replaced with a plain description: concepts, a minimal, an advanced, and a long-capture Luau example, the API documentation, and known issues | Before writing the first LibMP script in a session: the sections up to "LibMP -- minimalistic Luau example", then the example closest to the task (the advanced one attributes cross-frame scopes to each frame, reads counters, and walks threads; the long-capture one reads stream segments and scope labels) |
| [references/api-reference.md](references/api-reference.md) | The upstream LibMP API reference | Before calling a method or reading a field that this file and the guide's examples do not show |
| [references/ALL-SCOPES.md](references/ALL-SCOPES.md) | The complete MicroProfiler scope reference (~260 KB) | Grep it for a scope or label name. Grep this local copy instead of fetching the GitHub URL the guide points at |
| [references/local-notes.md](references/local-notes.md) | Behavior observed in live Studio sessions that the upstream docs do not cover | Before trusting a count of stepping scopes, when a `Control` method seems to be missing, when a method in the API reference is missing at runtime, and before refreshing this skill |

## Getting the LibMP module

Try the engine shortcut first:

```lua
local LibMP = require("@rbx/LibMP")
```

Upstream documents it for Studio's Assistant, Roblox's built-in Studio MCP, and the Studio command
bar. Other callers get this error:

> The requested library 'LibMP' can only be loaded via a shortcut by Assistant. To use it in
> regular scripts, add it manually to the place.

When it fails, the place needs its own copy of the module:

1. Check for one first: a `LibMP` ModuleScript, usually in `ReplicatedStorage`.
2. If there is none, ask the user before adding it. It comes from the
   [Creator Store](https://create.roblox.com/store/asset/109009378620272/LibMP) or as a Luau file
   from the [LibMP releases](https://github.com/Roblox/libmp/releases). Tell the user where it went,
   so they can keep it out of a published build.
3. Require it by path: `require("@game/ReplicatedStorage/LibMP")`.

The module is about 4.9 MB, so the first `require` in a Studio session costs roughly 800 ms, and
later ones in the same Luau VM come from the require cache. Code run inside a playtest's server or
client runs in that game's VM, which needs the copy in the place even when the shortcut works in
the edit session.

## Where to run the analysis

- **Static data in the edit session.** MP data is readable in Edit mode, and a slot captured during
  a playtest survives the switch back to Edit (see the essentials below). Deep analysis over many
  frames belongs here, where it costs the game nothing.
- **Live checks in a playtest.** Run Luau on the playtest server or a client to enable capture and
  watch for a spike. Keep these checks light, since they run inside the frames being measured.
- **Return results** from the snippet with `return` instead of printing them. Print to the output
  log only when the user asks to see the results there.
- **One snippet does one complete job**: open, read, aggregate, dispose, return. A run-Luau call
  can time out, so a long aggregation over 256 frames with every thread may need to be split by
  frame range.

## Profiler state is global

LibMP drives the one MicroProfiler in the engine. The game's own LibMP code, a capture tool in
the user's Studio MCP, the on-screen MP, and your snippet all share its state. Five consequences:

1. **Leave the profiler as you found it, or say what changed.** `LibMP.Control` has setters only,
   so the current frame limit, capture state, and profiler state can't be read back. Before
   changing one, find the value the game or the user set (search the code for `SetFrameLimit`,
   `EnableCapture`, and `EnableProfiler`), restore that value at the end, and tell the user what
   you changed and what you couldn't restore.
2. **The frame limit is sticky.** `LibMP.Control:SetFrameLimit` stays in effect for every later
   reader, and changing it clears counter history. Set it before reading frames (a game may have
   set a very low one), and put back the value you found. 256 is the maximum.
3. **The first capture after the profiler turns on holds a one-time engine stall** of about 350 ms
   about 12 frames in, seen in Studio playtests. Let about 24 frames pass after
   `EnableProfiler(true)` before the frames you analyze start, and leave the profiler enabled
   between captures so the stall is paid only once per session.
4. **One analysis at a time.** Toggling capture while another capture is recording, from a game
   script or a capture tool, ruins that capture. Check whether one is in flight before you start.
5. **Dispose of only what you opened.** A live session the game or another tool holds keeps
   advancing; reading it is fine, disposing of it breaks its owner.

## Essentials from the upstream guide

The guide in `references/libmp-guide.md` explains each of these in its named section.

- **Freeze the data before deep analysis** (Sessions & Capturing; Special notes for AI agents).
  From a snippet run through a Studio MCP, open the session from a snapshot instead of
  `OpenFromLiveData`. `LibMP.Control:CaptureToSlotSync(slot)` saves the live frames into slot 1
  to 4, which survives Play and Edit switches in Studio, and `LibMP.Session.OpenFromSlot(slot)`
  opens it; call `LibMP.Control:ResetSlot(slot)` once that data is no longer needed.
  `CaptureToBufferSync()` with `LibMP.Session.OpenFromBuffer(buffer)` gives the same frozen dataset
  in a Luau buffer. Live data suits lightweight in-game checks, and pausing the MP suits in-game
  analysis done within one frame. Pause and snapshot together only to freeze the on-screen MP UI
  on the data you analyze, and unpause when finished. In Studio, stay in the current mode when MP
  data has already been captured and is static.
- **Record longer windows with a stream** (Sessions & Capturing). A memory stream into a slot, or
  a file stream in Studio, can run for minutes. The slot becomes readable after the stream is
  finalized, and a long capture usually holds several segments. These controls live in
  `LibMP.Experimental.V1` and may change.
- **Set the frame limit before operating on frame data** (Special notes for AI agents), then
  restore it (consequence 2).
- **Report both frame IDs**, the regular and the absolute one, so the user can find the frame in
  code and in the MP UI (Special notes for AI agents).
- **Attribute scopes to frames by overlap** (Iterators & Frame Boundaries). A scope instance can
  cross frame boundaries: distribute its duration across every frame it overlaps, never only the
  frame where its exit entry appears. The first frame of a range may hold exits without enters
  and the last enters without exits; on snapshotted data, start iterating one frame early to warm
  up the scope stack.
- **Keep GPU and CPU timestamps apart** (Important Iterator Behaviors). Their origins and scales
  differ, and a frame's GPU start and end can be too broad or wrong. Measure GPU time from the
  continuous sections of scopes in the GPU thread. A GPU frame time close to the CPU frame time
  does not by itself mean the game is GPU-bound (Special notes for AI agents). Some platforms have
  no GPU thread at all.
- **Read times as inclusive** (Timing Types). A scope's time includes its children, and inclusive
  group totals are work volume, not frame duration. For a real bottleneck, inspect the per-frame
  critical path and per-thread spans.
- **Analyze rare spikes separately from steady-state bottlenecks.** A single 600 ms stall can
  dominate averages and hide the normal bottleneck.
- **Stop when the evidence is clear** (Special notes for AI agents). When one scope clearly
  dominates, report it rather than also working through GPU scopes and memory counters, unless the
  user asks for the full picture.
- **Read a `Get***` view at once, or use `Fetch***`** (Data Retrieval). A `Get***` view is
  invalidated by any later `Get***` or `Fetch***` call on the same session. `Fetch***` returns a
  deep copy and is the recommended default. Arrays from `Get***` persist until disposed.
- **Dispose of every Session, Iterator, and Array you create** with `Dispose()` (Notes). Store an
  array in a variable as soon as a `Get***` method returns it, or it leaks. A `LibMP.GetMemUsed()`
  that keeps rising almost certainly means a leak.
- **Call `Find***` methods once and store the result**: they are slow (the advanced example).
- **Know what the data holds** (Limitations; Important Iterator Behaviors). There are no built-in
  averages, minimums, or maximums: compute them from the raw data. Scope labels can be read when
  the log iterator is configured with `TrackScopeLabels = true`, but label text may be missing.
  Scopes added with `debug.profilebegin` / `debug.profileend` keep their names.
- **A saved dump works offline** (Notes). The user can save one from the MP menu with "Dump", then
  "Dump in binary format"; the `.gprx` file opens in command-line Luau (Lute) with the same module.
