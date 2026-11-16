# Eval results: every roblox-dev skill (2026-11-13 to 2026-11-16)

Each skill has 4 or 5 tasks, run 3 times per setup on Opus. With-skill loads the whole
`roblox-dev` plugin as shipped (skills plus hooks); baseline loads no Roblox plugin. A blind A/B
Opus judge compares each with-skill run against a baseline run of the same task. Trigger tests
send 20 prompts (10 that should load the skill, 10 that shouldn't), 3 runs each, with hooks off.
`PILOT.md` covers the method and the pilot's cost per trial.

Results are in `evals/<skill>/results/<date>-<pass>/`: `benchmark.md` summarizes the trials,
`judge-summary.json` totals the verdicts, each pair's `comparison.json` gives the judge's reasons,
and each trial's `outputs/changes.diff` shows its code.

## Final results

| Skill | Judge (with-skill / baseline / tie) | Mean judge score | Triggers | Final pass |
|---|---|---|---|---|
| `luau-style-guide` | 11 / 1 / 0 | 8.48 / 7.17 | 18 of 20 | pass5 |
| `figma-to-roblox` | 12 / 0 / 0 | 8.46 / 6.21 | 18 of 20 | pass1 |
| `game-ui-design` | 12 / 0 / 0 | 8.26 / 6.69 | 20 of 20 | pass1 |
| `vide-performance` | 12 / 0 / 0 | 8.54 / 6.63 | 20 of 20 | pass3 |
| `code-comments` | 10 / 2 / 0 | 8.67 / 7.21 | 20 of 20 | pass2 |
| `vide` | 10 / 2 / 0 | 8.38 / 7.75 | 19 of 20 | pass2 |
| `vide-charm` | 10 / 1 / 1 | 8.83 / 8.00 | 18 of 20 | pass4 |
| `rojo-workflow` | 9 / 2 / 1 | 8.18 / 7.44 | 19 of 20 | pass4 |
| `vide-ui-labs` | 9 / 2 / 1 | 8.56 / 8.00 | 19 of 20 | pass3 |
| `rbx-perf-profiling` | 9 / 3 / 0 | 8.06 / 6.79 | 20 of 20 | pass1 |
| `roblox-performance` | 9 / 3 / 0 | 8.42 / 7.86 | 19 of 20 | pass3 |
| `roblox-testing` | 9 / 3 / 0 | 8.42 / 7.25 | 19 of 20 | pass1 |
| `game-architecture` | 6 / 7 / 2 | 8.52 / 8.45 | 18 of 20 | pass4 |

`game-architecture` is even with the baseline and is kept as is. Its remaining losses are close
calls on polish (a fuller comment, "coin" vs "coins"). In these tasks the existing code already
shows the loader patterns, so the baseline copies them. The skill's value lies in what file-based
tasks don't measure: Studio mode, projects without example code, and loader debugging.

## What the wording passes changed

Pass 1 measured every skill as ported. Passes 3 and 4 re-ran the with-skill side after rewording
and reused the baselines, since a baseline loads no plugin. Pass 5 re-ran both setups.

| Change | Result |
|---|---|
| `vide`: strict mode only when asked; cleanup wording | 8/4 to 10/2 |
| `code-comments`: narrower description | triggers 18 to 20 of 20 |
| `luau-style-guide`: "Fit the project": edited files keep their conventions, new files take their siblings' | stopped edits to untouched lines; `vide-charm` 5/5/2 to 10/1/1 |
| `vide-ui-labs`: mount a story once, with a story-local source | 7/5 to 9/2/1 (picker-story 0/3 to 3/0) |
| `rojo-workflow`: edit only the needed files, mention the Rojo crash only when seen, BOM byte check, narrower description, module-to-folder only when the module gains a child | 2/10 to 9/2/1 (with the harness fixes below) |
| `game-architecture`: "Fit the existing project": every changed line traces to the task; description scoped to loader projects | stopped refactors of untouched systems; still even overall |

`luau-style-guide` measured 8/4 in pass 4 against reused baselines; pass 5, with fresh runs of
both setups, measured 11/1, so the dip was run-to-run variation.

## Open items

- Trigger misses. `game-architecture` misses a round-countdown sound and a new FPS-counter
  LocalScript since its description was scoped to loader projects. `luau-style-guide` misses a
  comment cleanup (`code-comments` covers it) and loads for a Lune script.
- luau-lsp reports "path does not exist" for new files in trials, in both setups, because the
  sourcemap isn't regenerated. The judge discounts it, but a checker that regenerates the
  sourcemap first would remove the noise.

## Harness fixes during the runs

1. Trial paths over 260 characters made `git add` skip files, so diffs came back empty. Trials now
   set `core.longpaths`.
2. `git mv` and `git rm` were denied in trials, which broke the `rojo-workflow` move task.
   They are pre-approved now, with read-only git commands.
3. Per-task `judge_facts` add library facts the judge needs for one task.
4. The export now copies only verdicts, grading, final messages, and diffs, and redacts paths
   escaped twice inside JSON.
