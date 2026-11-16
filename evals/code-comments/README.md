# code-comments evals

Pilot eval set for the `code-comments` skill: two tasks for the writing branch (the comments an
agent adds while writing new code) and two for the cleanup branch (pruning an over-commented file).
None of the prompts mention the skill or a comment style; the cleanup prompts only ask to clean up
the comments, the way a developer would.

| Task | Branch | What it tests |
|---|---|---|
| `tasks/placement-rules.json` | writing | Write the shared placement validation module from scratch. The code has natural spots for a real why (NaN slipping past range checks, the shrunk overlap box, the grid offset, units); the rubric rewards those and penalizes narration, long blocks, and change or request references. |
| `tasks/placement-server.json` | writing | Write the server placement script on top of two clean shared modules (`BlockTypes`, `PlacementRules`). Same comment criteria, plus remote security and correct per-player state. |
| `tasks/cleanup-placement-server.json` | cleanup | Clean up an over-commented server script: narration, change history, a changelog header, a design doc section reference, stale comments, commented-out code, block-end markers, banners inside a function, em dashes, and a drifted top-level banner, mixed with eight comments that carry a real why (or are directives) and must survive, one of them a five-line block that should be trimmed. |
| `tasks/cleanup-block-picker.json` | cleanup | The same on a Vide UI LocalScript: narration on every property, a Roact changelog and commented-out Roact code, a stale default, a banner inside a table constructor, and five keeps (two directives, a cross-file attribute sync note, the Activated gotcha, the gameProcessed gotcha, a TODO). |

Fixtures live in `tasks/fixtures/` because `setup_files` paths are relative to the task file and
may not contain `..`. Each cleanup task's `notes` field lists every planted keep and removal.

## Checks

- **Code unchanged** (cleanup tasks): an inline `node -e` script strips comments and whitespace
  (and a trailing comma before `}`, which StyLua may add or drop) from the file at `HEAD` (the
  setup commit) and from the trial's file, and compares them. It ignores formatting, so a StyLua
  rerun after deleting comments still passes.
- **Kept / Removed** (cleanup tasks): one `file_matches` per planted keep, matching a word a trimmed
  version would still contain, and grouped `file_not_matches` checks for the planted removals.
- **Convention** checks test the skill's house rules: no em dash or `--` used as a dash in comments,
  and `--[[` and `]]` on their own lines. A baseline agent has no way to know these, so read them as
  a measure of compliance rather than of quality. The judge's rubric leaves them out.

## Triggers

`triggers.json` has 10 should-trigger and 10 should-not queries. The description claims every code
edit in any language, so the positives include plain Luau, Python, and Node edits as well as comment
cleanup requests; the negatives are near-misses that write prose (README, commit message, patch
notes) or only read or ask (a Luau comment syntax question, a no-edit bug review, a selene question).
