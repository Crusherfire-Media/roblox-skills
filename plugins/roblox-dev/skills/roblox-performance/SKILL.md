---
name: roblox-performance
description: Roblox performance - designing systems that scale and diagnosing or fixing lag, with evidence-tagged rules for Luau, memory and garbage collection, buffers and serialization, networking and replication, instances and pooling, physics and moving parts, rendering, and UI. Load it before designing a system that runs per frame, handles many entities or instances, or fires remotes often; when the user reports lag, low FPS, stutter, high ping, memory growth, crashes on phones, slow joins, UI that flickers or draws blank, or sounds that play late; when asked to optimize, profile, or benchmark anything in a place; and before adding pooling, buffers, a networking library, Parallel Luau, or native code generation for speed. Load it even when the optimization looks obvious, because its first job is deciding whether to optimize at all.
---

# Roblox performance

A system gets optimized when a measurement says it is a problem, or when its design is headed
for a scale where it will be. Everything else stays simple and readable.

## Ground rules

1. **No number, no optimization.** Measure before and after on the same workload. A change that
   does not move the number gets reverted, however clever it is.
2. **Bottleneck first.** Know which subsystem is over budget (scripts, physics, rendering, UI,
   network, memory) before touching code.
3. **Macro before micro.** Look for the fix at the highest level that has one. These gains come
   from this skill's measurements and from reported cases:

   | Level | Example | Typical gain |
   |---|---|---|
   | Design: who simulates, what replicates, how often | Server keeps data, clients build visuals | 5x to 60x |
   | Algorithm and data structure | Set instead of `table.find`, grid instead of scanning | 4x to 70x |
   | Engine usage | Weld to one root, split a ScreenGui, reuse instead of re-create | 1.5x to 25x |
   | Micro: how a line is written | Scratch tables, layout tweaks, `@native` on a hot function | 0 to 2x in that loop (up to 5x for native math) |

   Above all four: ask whether the work is needed at all. It is cheaper to remove a cost than
   to spread, cache, or pool it.

4. **Readable by default.** A micro-optimization costs readability every day and pays back only
   inside a measured hot path. A system that no measurement flags keeps its plain version, even
   if a faster one is easy to imagine.
5. **Same behavior.** Optimizing changes how a system works, never what it does. See
   [Keeping behavior unchanged](#keeping-behavior-unchanged).
6. **Every optimization is a hypothesis.** Many make things worse: a pool holds memory and
   stale state, a cache goes stale, a buffer is no faster to read than an array, native code
   costs memory, a naive math loop loses to the engine query it replaced.

When asked to optimize something that measures fine, say so with the numbers and recommend
leaving it alone. That is a complete answer.

**Signs an optimization is mis-aimed.** Stop and re-check when any of these is true:

- The code runs once a second or less and no spike frame points at it.
- The gain was measured only with a script timer, only once, or only on a desktop.
- The work being spread, pooled, or cached is the cheap part, and the expensive part still runs
  as before.
- `@native` or a buffer is going onto code that mostly calls engine APIs.
- A pool or cache has no measured peak demand behind its size.
- The technique comes from a forum post older than the engine feature it works around.

## Pick the path

- Building something new: [Designing a system](#designing-a-system).
- Something is slow, or the user asks to optimize existing code:
  [Diagnosing and fixing](#diagnosing-and-fixing).
- Reviewing code: check it against the "Design decisions" section of each reference it touches,
  and raise only macro-level problems or ones a measurement supports.
- A question about which approach is faster: answer from the matching reference and name the
  evidence tag behind it. When the answer decides a design, offer to measure it in the actual
  place.

## Designing a system

1. **Ask the scale questions.** How many (entities, instances, players)? How often (every frame,
   every second, on an event)? Who pays (the server, every client, the network)? What is the
   weakest device that must run it?
2. **Estimate.** Multiply count by rate by the unit costs in
   [references/estimating.md](references/estimating.md). When the result is under about 5% of
   the frame budget on the weakest device, nothing replicates per frame, and the instance count
   is small, write the plain, readable version and stop here. Most systems end at this step.
3. **Set a budget** for what the estimate says matters: milliseconds per frame, KB/s per client,
   MB, draw calls, instance count. Starting points are in
   [references/measuring.md](references/measuring.md) under "Budgets".
4. **Choose the macro design** from the "Design decisions" section of each reference the system
   touches (see [References](#references)). This is the decision that is expensive to change
   later.
5. **Build the simple version of that design**, with no micro-optimizations. Wrap the hot loop
   in `debug.profilebegin("System:Step")` and `debug.profileend()` so a profile can find it.
6. **Measure at the intended scale and at double it** (read `references/measuring.md` first),
   and tell the user the budget, the two measurements, and the design chosen.

Done when the step 2 estimate cleared the system, or the measured cost at twice the intended
scale is inside the budget, or the user has accepted the trade-offs of a design that is not.

## Diagnosing and fixing

1. **Pin down the symptom and the target.** What is slow, on which machine (server, every
   client, one device class), when (always, in spikes, after long sessions), since when, and
   what number counts as fixed (default: the budgets in `references/measuring.md`).
2. **Reproduce it on a repeatable workload** in a playtest: a fixed place, position, and action,
   scripted when possible. When it only happens on devices or live servers, ask the user for a
   MicroProfiler dump or Developer Console numbers from there and use those as the baseline.
3. **Take the baseline** (read `references/measuring.md` first) with the tool the symptom calls
   for in the table below, and save the numbers.
4. **Find the bottleneck.** Attribute the cost to one subsystem and, inside it, to one cause.
   Read that domain's reference.
5. **Name the biggest lever**, highest level first, and say what you expect it to gain. When
   the lever changes behavior, stop and follow
   [Keeping behavior unchanged](#keeping-behavior-unchanged).
6. **Set up the safety net.** When the place has specs, run the specs that cover the system you
   will change (the `roblox-testing` skill's Running specs) and note the result.
   List the behaviors the change must keep. Where no spec covers one, propose a spec through the
   `roblox-testing` skill or write down how it will be checked by hand.
7. **Change one thing.**
8. **Re-measure on the same workload.** Keep the change when the number moved by more than the
   noise (`references/measuring.md`); otherwise revert it.
9. **Repeat from step 4** until the target is met. Fixing one bottleneck exposes the next, so
   stop at the target and say what is left.
10. **Report** in the format in [references/reporting.md](references/reporting.md).

Done when the target is met on the same workload, or the user has accepted what is left.

| Symptom | First measurement | Then read |
|---|---|---|
| Low client FPS, steady | A MicroProfiler capture on the client, top groups | Script: `luau.md`. Render: `rendering.md`. UI labels: `ui.md`. Physics: `physics.md` |
| Stutter or spikes | A MicroProfiler capture that holds the spike frame, broken down by label | GC: `luau.md`. Creating or destroying instances: `instances-pooling.md`. `ProcessPackets`: `networking.md` |
| Server lag for everyone | A MicroProfiler capture and a ScriptProfiler profile on the server | `luau.md`, `physics.md` |
| High ping, late remotes, rubber-banding | `Stats.DataSendKbps` and `DataReceiveKbps` | `networking.md`, `buffers-serialization.md` |
| Memory growth, crashes on phones | Memory by tag sampled over time, Studio's Scene Analysis | `LuaHeap`: `luau.md`. `Instances`: `instances-pooling.md`. `Graphics*`: `rendering.md` |
| Slow joins | `Stats.InstanceCount`, Scene Analysis, Studio's Print Join Size Breakdown | `networking.md`, `instances-pooling.md` |
| Lag when menus open or lists fill | A MicroProfiler capture filtered to `UpdateUILayouts` | `ui.md`; for Vide UI also the `vide-performance` skill |

`references/measuring.md` says how to take each of these. A MicroProfiler capture read from Luau
goes through LibMP, so load the `rbx-perf-profiling` skill before the first one.

## Keeping behavior unchanged

An optimized system does the same observable thing as before: same results, same timing as far
as players and other systems can tell, same public API. Specs that passed before pass after. A
spec that goes red only because it was tied to internals is handled by the refactor rule in the
`roblox-testing` skill: report it rather than editing it quietly.

Some of the best levers do change behavior: a lower update rate, effects that no longer exist on
the server, quantized positions, pooled objects that keep state a fresh one would not have,
props hidden at distance, changed art or lighting, and work spread across frames (for those
frames the world is half built or half removed, and code that assumed it happened at once can
break or duplicate items). When a lever like that is the right fix, stop before making it and
tell the user:

- what changes for players or for other systems,
- what it is expected to gain,
- the behavior-preserving alternative and what that gains instead.

Make the change after the user chooses.

## The short list

The costs that are easiest to miss. Numbers and evidence are in the reference named after each.

- **Instances are heavy.** Keep state in Luau tables and use instances for what the engine must
  render, simulate, or replicate. (`instances-pooling.md`)
- **The server holds data, and clients build visuals.** Effects, tweens, projectile visuals, and
  NPC rigs created on the server replicate to everyone. (`networking.md`)
- **Send less, less often, to fewer players before packing bytes.** (`networking.md`)
- **The assembly is the unit of physics and movement cost.** Weld what moves together to one
  root, and keep parts that resize or come and go out of an assembly that simulates.
  (`physics.md`)
- **Touches cross collision groups unless `Workspace.TouchesUseCollisionGroups` is on.** A large
  touch volume then pays a check for every touch-enabled part it overlaps. (`physics.md`)
- **One changing element redraws its whole ScreenGui.** Keep per-frame UI in its own small
  ScreenGui. (`ui.md`)
- **Draw calls come from variety, not count.** Color and size are free; each extra material,
  mesh, enabled `ParticleEmitter`, or `Beam` adds one. (`rendering.md`)
- **Math beats engine queries only with a spatial index.** (`physics.md`)
- **A script timer misses most of an engine call's cost.** Compare whole frames.
  (`measuring.md`)
- **Buffers save memory and bytes, not time.** (`buffers-serialization.md`)

## References

Read the one that matches the bottleneck or the system being designed. The topic references open
with "Design decisions", the macro choices.

| File | Covers |
|---|---|
| [references/measuring.md](references/measuring.md) | Which tool answers which question, fair comparisons, the benchmark harness, reading a live client's MicroProfiler dump with the scripts in `scripts/`, reproducing a live client's problem in Studio, budgets, MicroProfiler labels. Read before any measurement. |
| [references/luau.md](references/luau.md) | Script cost, algorithms, data layout, the engine boundary, garbage collection, leaks, Parallel Luau, native code |
| [references/buffers-serialization.md](references/buffers-serialization.md) | When a buffer is the right tool, bit packing, bytes on the wire, compression, DataStore limits |
| [references/networking.md](references/networking.md) | Remotes, replication, streaming, send rates, reliability |
| [references/instances-pooling.md](references/instances-pooling.md) | Creating and destroying instances, pooling and when it backfires, attributes against value objects |
| [references/physics.md](references/physics.md) | Assemblies, moving things, collisions and touches, finding what a client simulates, spatial queries, Humanoids and NPCs, animation |
| [references/rendering.md](references/rendering.md) | Draw calls, mesh and texture settings, transparency, lighting, culling, VFX, client memory |
| [references/ui.md](references/ui.md) | ScreenGui invalidation, text, layout, expensive UI features, in-world UI |
| [references/estimating.md](references/estimating.md) | Unit costs for the design estimate, with a worked example. Read before step 2 of "Designing a system". |
| [references/reporting.md](references/reporting.md) | The report that ends a diagnosis, and what Studio numbers cannot show. Read before step 10 of "Diagnosing and fixing". |

## Evidence tags

Rules in the references end with a tag that shows their weight:

- `[docs]`: stated by Roblox documentation or a Roblox engineer.
- `[measured]`: benchmarked for this skill in Studio 0.741 (October 2026) on an empty baseplate
  and a desktop. The numbers show direction and rough size.
- `[reported]`: a community measurement or an expert's report that was not reproduced here.
- `[in-game]`: measured in a production game while fixing its performance (October 2026,
  Studio and the published desktop client, one desktop): a before and after on the same
  workload, a cost measured directly in that place, or engine behavior observed there. Real
  content, one game.

A tag on a table's lead-in line or on a heading's first line covers everything beneath it. Two
tags mean both kinds of evidence apply. A rule with no tag is this skill's own judgment.

The engine changes, and a baseplate is not a game: a tagged rule tells you what to try first,
and the measurement in the actual place decides.

## Reporting

End a diagnosis with the report in [references/reporting.md](references/reporting.md), which also
says what Studio numbers cannot show.
