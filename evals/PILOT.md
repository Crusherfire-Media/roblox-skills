# Pilot: code-comments and vide (2026-11-13)

The pilot ran the full method on two skills to measure real cost per trial before budgeting the
other 11. Each skill has 4 tasks, run 3 times per setup. With-skill loads the whole `roblox-dev`
plugin as shipped (skills plus hooks); baseline loads no Roblox plugin. Results are in
`evals/<skill>/results/2026-11-13-pilot/` (`benchmark.md` has every trial and judge verdict).

## Results

| Skill | Judge wins (with-skill / baseline) | Mean judge score | Automatic checks | Trigger accuracy |
|---|---|---|---|---|
| `code-comments` | 10 / 2 | 8.67 / 7.25 | 99.0% / 90.8% | 18 of 20 |
| `vide` | 8 / 4 | 8.42 / 7.83 | 100% / 96.2% | 19 of 20 |

- `code-comments` wins every cleanup pair (6 of 6) and the placement-rules writing task (3 of 3).
  Its two losses on placement-server come from server bookkeeping and from the style guide's
  banners and file header, which a neutral judge reads as noise.
- `vide` wins picker-screens 3 of 3. Its losses come from scope creep traced to the skill's wording
  (adding `Vide.strict` to tasks that didn't ask for it) and from close calls on motion.

## Cost per trial (Opus)

| | With-skill mean | Baseline mean | Judge run |
|---|---|---|---|
| `code-comments` | $0.54, 102 s | $0.28, 66 s | about $0.11 |
| `vide` | $1.50, 284 s | $0.65, 154 s | about $0.17 |

With-skill trials cost about twice as much: they read skills, retry edits the gate denied, and fix
what `verify-gate` reports.

## Harness bugs the first pass found

The first pass is discarded. Its with-skill half was re-run after these fixes; the baseline runs
are reused, since a baseline loads no plugin.

1. Trials ran with `--no-session-persistence`, so `skill-gate` and `verify-gate` found no transcript
   and passed silently. Trials now keep their session transcripts.
2. The judge marked correct Vide code wrong for relying on `create("ScreenGui")` setting
   `ResetOnSpawn = false`. `harness/judge-facts.md` now gives the judge library facts verified
   against the vendored source.
3. `verify-gate` blocked on luau-lsp errors inside installed packages. Fixed in the plugin (PR #5):
   it reports only the edited files.

The pilot also found a factual error in `vide` (destroying a `mount` scope leaves the UI parented),
fixed in PR #3 before the trials ran.
