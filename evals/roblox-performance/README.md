# roblox-performance evals (M12)

Four tasks and a trigger set for the `roblox-performance` skill, built on the block placement demo.
Shared fixtures in `tasks/fixtures/shared/` are copies of the vide set's `BlockTypes`,
`BlockPlacement.server.luau`, and `BlockPlacer`, plus a `Main.client.luau` that starts
`BlockPlacer`. How to run them is in `../README.md`.

## Tasks

| Task | Branch | What it tests |
|---|---|---|
| `placement-review` | Deciding whether to optimize | A friend's list of six "optimizations" for placement code that runs at most 10 times a second per player. Rewards restraint: a scale estimate, rejecting pooling, buffers, native code, and especially an `UnreliableRemoteEvent` for placement (a correctness bug), keeping any change small, and saying what to measure if lag ever appears. A write-up and no code change is a full answer. |
| `block-info-lag` | Diagnosing and fixing, per-frame Luau | A client script that, every frame, scans the whole Blocks folder twice to count blocks and once more to find the block nearest the mouse, with a measured lag report in the prompt. Tests removing the cost (event-driven counts, a raycast or cell lookup for hover) over throttling or micro-tuning, unchanged behavior, and a report that doesn't invent after-numbers. |
| `ghost-network` | Networking and replication | Ghost previews fired from RenderStepped (frame-rate-bound sends) and drawn as server parts moved per message. Tests send-on-change at a capped rate, client-built visuals with a local own-ghost, `UnreliableRemoteEvent` for replaceable data while placement stays reliable, validating and relaying untrusted data, and an estimated (not measured) bandwidth write-up. |
| `build-loading` | Instances, creation, and spreading work | Loading a 20,000-block save in one loop with `Instance.new("Part", parent)` and two value objects per block, and unloading with one `Destroy`. Tests cutting instances (state in tables or attributes), set-then-parent, batching across frames with a budget, reserving cells before the first yield and handling a mid-load leave, keeping removal's owner check, and writing down what players will notice. |

Checks confirm each planted pattern is gone and the requested write-up exists. `placement-review`
uses `auto_checks: []` (an unchanged codebase is a valid answer, and the harness fails the
automatic checks when no Luau file changes) and instead runs selene, StyLua, and luau-lsp over all
of `src` as command checks, which pass on the untouched start and catch a broken edit.

The fixtures pass luau-lsp, selene, and StyLua in the sandbox, except the planted
`Instance.new("Part", parent)` in `build-loading`, which selene flags as deprecated.

Rubrics avoid numbers only Studio could produce: they reward estimates from rates and counts, and
reports that say what to measure, rather than any particular after-number.

## Triggers

`triggers.json` holds 10 queries that should load the skill and 10 that shouldn't. Near misses:
Vide reactivity, a Vide tabbed panel (a `vide-performance` design question), a LibMP API question
(`rbx-perf-profiling`), remote validation, DataStore saving, Python and Next.js performance,
analytics, `task.defer`, and a Jest spec.

Two labels follow the description literally: the late Vide button sound is labeled true because
the description lists "sounds that play late", even though `vide-performance` owns that topic; the
Vide tab question is labeled false because it asks for a UI design, not a slow system.
