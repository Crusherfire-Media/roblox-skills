# luau-style-guide evals

Four tasks and a trigger set for the `luau-style-guide` skill: two write tasks (a plain
module and a class), a behavior-preserving refactor, and a review written to `docs/review.md`. The
prompts never mention the skill or a style rule. All fixtures and prompts are written for this
repo; nothing is copied from the Roblox Lua Style Guide, which has no license.

The rubrics score rules whose payoff a judge can see in the code: types that catch mistakes,
failures reported to the caller, safe handling of client input, consistent return values, readable
call sites and names, and complete teardown. House conventions (`--!strict` where the prompt
doesn't ask for it, `const` services, `local Module = {}`, string requires, `Module.__index =
Module`, if-then-else expressions in place of `and`/`or`) are objective checks labeled
"Convention" and stay out of the rubric, as in `evals/code-comments`. No task rewards or penalizes
section banners or a file header.

| Task | Branch | What it tests |
|---|---|---|
| `tasks/block-inventory.json` | write | A server module for per-player block supplies loaded from a DataStore. Typing (the closed `BlockType` set, `{ [Player]: Counts? }`), out-of-stock and not-loaded failures returned to the caller, a readable way past the 99 cap (options table or separate function), a yielding load that is named as one and wrapped in `pcall`, and timing (a player who leaves during the load, players already in the server). |
| `tasks/refactor-plot-stats.json` | refactor | Clean up a game-jam module (`fixtures/refactor-plot-stats/PlotStats.luau`) without changing behavior: cryptic names, a global function, a mixed array/dictionary table, `fmt(n, true, false)` flags, nested and duplicated filtering, magic numbers, a bare `return`, no types. A Lune check compares the four public functions against the starting file. |
| `tasks/review-block-shop.json` | review | Review a server script (`fixtures/review-block-shop/BlockShop.server.luau`) into `docs/review.md` without editing it. Planted: NaN and other client input slipping past range checks, a coin race across a DataStore yield with no `pcall`, `or` turning an explicit `false` into `true`, a function that falls off its end used in `tostring`, and unchecked `{ [Player]: T }` lookups, plus readability items. Control: a correct `== nil` check. |
| `tasks/ghost-preview.json` | write (class) | A client class for the build mode ghost block. A typed prototype class with every field set in the constructor, a teardown that disconnects and destroys everything, an options table for transparency and ray length, an optional return for the placement query, and reuse of `PlacementRules`. |

Shared fixtures: `fixtures/shared/BlockTypes.luau` (the `BlockType` union, styles, block size) and
`fixtures/shared/PlacementRules.luau` (`snap` and `check`). Every fixture passes luau-lsp, selene,
and StyLua in the sandbox; luau-lsp prints an `ImplicitReturn` lint (exit 0) on the review
fixture's planted `getOwnerName`. Each task's `notes` field lists what it plants and what its
checks cover.

## Checks

- **Behavior unchanged** (`refactor-plot-stats`): an inline `node -e` script writes the file at
  `HEAD` (the setup commit) and the trial's file to a temp folder and runs a Lune script on both.
  It loads each with `luau.load` in an environment holding Lune's `Vector3`, calls `summarize`,
  `getTallest`, `format`, and `compare` over fixed inputs, and compares the results deeply. It
  passes on the untouched file and on a hand-made refactor, and fails when the discount boundary or
  the decimal format changes. It needs `lune` from the sandbox's `rokit.toml`.
- **Unchanged files** (`review-block-shop`, `ghost-preview`): `git status --porcelain` on the paths
  the task must leave alone, so new files count too.
- Every other check was run on the starting point (it fails where the task requires work) and on a
  hand-made answer (it passes).

## Judge facts

`block-inventory` adds one fact about the type checker, not a package: luau-lsp 1.70.1 types the
loop variable of a generic `for` over `{ BlockType }` as `string`, so iterating `BlockTypes.Order`
needs a cast. Verified by running `luau-lsp analyze` in the sandbox. Without it, the judge may mark
a correct cast as sloppy.

## Triggers

`triggers.json` has 10 should-trigger and 10 should-not queries, labeled against the description:
writing, editing, reviewing, or reformatting Roblox Luau, plus asking for clean code. The positives
are a one-line fix, new Scripts and ModuleScripts, a remote handler, a review with no edit, a
snippet question, a reformat, a class conversion, the "clean code skill" by name, and a comment
cleanup (a Luau edit, so the description covers it although `code-comments` owns the wording).
The negatives are near misses: Python, TypeScript clean code, a Lune script that never runs in
Roblox, Neovim Lua, a pairs/ipairs explanation with no code, selene config, a Module Loader
question, a profiling question, a commit message, and a Vide API question.
