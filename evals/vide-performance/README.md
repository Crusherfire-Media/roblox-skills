# vide-performance evals (M12)

Four tasks and a trigger set for the `vide-performance` skill. Every task starts from the sandbox
plus the block placement fixtures in `tasks/fixtures/shared/` (copied from `../vide/`). Trials
can't run Studio, so each prompt gives the user's own measurements (frame times, instance counts,
connection counts) and asks for a short note under `docs/perf/` on what changed and how to confirm
it. The judge sees the code and the note. With-skill trials also load `vide` and `vide-ui-labs`
(the skill gate requires them) and usually `roblox-performance`. How to run them is in
`../README.md`.

## Tasks

| Task | What it tests |
|---|---|
| `kept-pages` | A build menu that `show` rebuilds on every open and `switch` rebuilds on every tab change (about 450 instances for Shapes). Kept pages and a kept menu, a slide that still plays on every open (the kept menu needs its own presence flag), the rainbow swatch's Heartbeat stopped while hidden, and kept pages that still behave like fresh ones. |
| `placed-list` | A placed blocks list with one row per block (about 2,000) and one Heartbeat connection per row. A row pool the size of the window (or rows out of the tree), a canvas height from the data, one clock that runs only while the panel is open, and age text written only when it changes. |
| `late-sound` | UI sounds created per cue and destroyed after playing, with a startup `PreloadAsync` that didn't help. A counted cache that holds each sound while its UI can play it, the picker's open sound held before the picker exists, the shared click held once, and rapid cues that still overlap. |
| `canvas-groups` | A catalog with 40 cards, each its own idle CanvasGroup kept only for a hover shine. CanvasGroups that exist only while drawn, the shine still clipped to rounded corners, a temporary group created and removed while faded, and card content kept out of temporary groups. |

Checks confirm the note exists and the planted pattern is gone (pages chosen with `switch`, the
menu built by `show` on the open flag, a per-row per-frame connection, a fresh Sound per cue,
cards built as CanvasGroups). The `placed-list` row check was also run on a shared-clock variant,
where it passes.

## Judge facts

Vide facts only, checked against the sandbox's Vide source: `switch` and `show` destroy the old
branch and rebuild, `present` starts false and turns true after the builder, `indexes` keeps a
key's scope while the key stays, `spring` starts at its goal, `derive` reruns readers only on a
real change while a property binding writes on every rerun. Engine claims the skill relies on
(audio memory release, the CanvasGroup texture budget, hidden UI still laid out) can't be verified
from package source, so the prompts carry the user's observations instead (IsLoaded false after
the preload, 41 CanvasGroups and flicker at low quality, connection and object counts).

## Triggers

`triggers.json` holds 10 queries that should load the skill and 10 near misses: engine performance
that isn't UI (physics, remotes, memory growth, world footstep sounds, which belong to
`roblox-performance`), slow lists in another library (react-lua), MicroProfiler questions about
plain Instance UI, and Vide work with no cost named (a stuck label, device layout, a UI Labs story,
a Charm-backed HUD label). The description's build-time clause ("before building UI that opens and
closes often, keeps pages or tabs, ... or plays sounds") makes a new tabbed settings menu a
positive even with no measured cost.
