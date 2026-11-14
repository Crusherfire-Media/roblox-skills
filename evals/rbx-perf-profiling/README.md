# rbx-perf-profiling evals (M12)

Four tasks and a trigger set for the `rbx-perf-profiling` skill. The skill drives LibMP against a
live MicroProfiler in Studio, which trials can't reach, so every task is file-based: a diagnosis
written from captured LibMP output, or LibMP code the judge reads. How to run them is in
`../README.md`.

LibMP itself is not in the sandbox (it's a 4.9 MB module added to a place in Studio). The
in-game tasks get it through `tasks/fixtures/shared/LibMPLoader.luau`, which requires
`ReplicatedStorage.LibMP` and casts it to `any`, so new Dev modules that require the loader pass
luau-lsp. The judge facts for LibMP come from the upstream Roblox/libmp documents the skill ships
(`references/api-reference.md` and `references/libmp-guide.md`) and its scope reference
(`ALL-SCOPES.md`), since there is no package source to check them against.

## Tasks

| Task | What it tests |
|---|---|
| `stutter-diagnosis` | A diagnosis in `docs/perf/` from pasted LibMP script output on a player's dump (`tasks/fixtures/stutter-diagnosis/`). Planted: periodic 95 to 97 ms spikes from a user scope whose nested GC step follows a heap jump; a steady 22 ms main-thread bottleneck in another user scope; a one-off 352 ms frame that is MicroProfileFlip (profiler start-up); a merged worker total larger than the frame; a GPU frame span close to the CPU frame time while the GPU thread is busy 6.4 ms. Tests inclusive-time reading, spikes against steady state, the GPU-bound trap, and citing both frame ids. |
| `spike-report` | Writing `SpikeReport.run(slot)`, a command-bar analysis of a snapshot slot: median and p90, slow frames with top self-time scopes, and a normal-frame comparison. Tests opening from the slot without touching the profiler, splitting cross-frame scopes by overlap, per-thread self time, keeping GPU ticks apart, both frame ids, disposal, and caching `Find***` and names. |
| `fix-frame-report` | Fixing a Dev frame report with planted LibMP misuse (`tasks/fixtures/fix-frame-report/`). Reported: it borrows and disposes the FPS overlay's live session; pauses capture and never resumes; leaves the frame limit at 256 while the overlay assumes 60; charges whole scopes to their exit frame and double-counts nested Physics scopes; converts GPU ticks with the CPU rate and trusts invalid GPU spans. Unreported: a `GetTimerDesc` view read after `FetchGroupDesc` invalidated it, an undisposed `GetCounterSamples` array, and `FindGroupId` on every scope exit. |
| `memory-script` | Writing a Lute script for `.gprx` dumps that breaks memory down by subsystem (first, last, peak, growth, peak frame) and lists the leaf counters that grew most. Tests walking the counter tree, not double-counting parent totals with their children, computing stats from samples, both frame ids, and staying off `LibMP.Control`. `overview.luau` (from `roblox-performance/scripts/`, formatted with the sandbox's StyLua settings) is the in-repo example. |

`stutter-diagnosis` uses `auto_checks: []` (no code changes). `memory-script` runs only selene and
StyLua: luau-lsp can't resolve `@lute/process` or `./LibMP` in this project, so it would fail any
correct script. With-skill trials still get one `verify-gate` block on those requires, which they
can answer by explaining it.

Checks confirm each planted pattern is gone or each required piece exists. Every check was run on
the untouched start (it fails where the task needs work) and on a hand-made answer (it passes).

## Triggers

`triggers.json` holds 10 queries that should load the skill and 10 that shouldn't. Near misses:
Script Profiler tuning, scaling design, pooling, and remote byte costs (`roblox-performance`), a
slow Vide list (`vide-performance`), Chrome DevTools and Unity profilers, adding
`debug.profilebegin` labels (instrumentation, not analysis), the creator dashboard
(`roblox-analytics`), and a Developer Console heap snapshot. The Studio spike query is labeled true
because the description covers finding the causes of frame-time spikes without naming LibMP;
`roblox-performance` should load for it too.
