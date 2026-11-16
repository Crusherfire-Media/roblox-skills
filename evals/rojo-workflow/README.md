# rojo-workflow evals (M12)

Four tasks and a trigger set for the `rojo-workflow` skill. Trials have no Studio and can't run
`rojo serve` or `pesde install`, so the tasks use the file-based parts of the skill: how files map
into the place, moving and adding files, declaring a dependency, and repairing the project file.
The serve and Studio rules are judged from a written guide. How to run them is in `../README.md`.

## Tasks

| Task | What it tests |
|---|---|
| `move-rules` | Moving and renaming `ServerScriptService.Placement.PlacementRules` to `ReplicatedStorage.Rules.BlockRules`. The project's ReplicatedStorage node has no `$path`, so the new folder needs a node in `default.project.json`. The module reads its tuning values from `PlacementRules.meta.json`, which must be renamed with it, or the attributes vanish silently. References to update: an instance require, an `@game` string require, an attribute lookup by instance path, the spec, and a doc. |
| `starter-kit` | Adding new files in the right places: a `.server.luau` Script, a `.client.luau` LocalScript where LocalScripts run, and a `Configuration` with number attributes declared as `.model.json` (or `init.meta.json`) in a folder the project mounts. The trap: `src/ReplicatedStorage/StarterKit.model.json` isn't in the place. |
| `add-t` | Adding the `t` package (osyrisrblx/t on Wally) through pesde: the root `pesde.toml` `[dependencies]` in the file's Wally form with an exact real version, a require through the alias link, no faked lock or `roblox_packages` edits, the handler's NaN check kept (`t.Vector3` doesn't reject NaN), and a PR description telling the reviewer to run `pesde install`. luau-lsp is left out of the auto checks because the package can't be installed. |
| `fix-project` | Repairing a project file broken by a merge: a UTF-8 BOM, a misspelled `$path`, Jest packages moved to `ReplicatedStorage.TestPackages`, and `globIgnorePaths` removed (two `Tests` folders). Plus `docs/rojo-workflow.md`: changes go in files rather than Studio, serve only into your own dev place (`servePlaceIds`), check `rojo serve` after renames (Rojo 7.7.x crash), and keep JSON free of a BOM. |

The checks on `move-rules`, `starter-kit`, and `fix-project` build the tree with `rojo sourcemap`
inside an inline Node script and check the instances the place would contain, so any correct file
layout passes. Each check was run on the untouched starting point (fails), on a hand-made correct
answer (passes), and on the main wrong answer for `starter-kit` and `fix-project` (fails). The
scripts are inlined in each task's `checks` with `node -e`, like the code-comments tasks, so
trial agents can't read them in the project.

## Judge facts

- Rojo behavior was checked by running Rojo 7.7.1 in the sandbox, and building places and reading
  them back with Lune: `.meta.json` attributes, an orphaned meta file dropped silently,
  `.model.json` Configurations, the unmapped `src/ReplicatedStorage` folder, and the BOM,
  missing-`$path`, and duplicate-`Tests` errors.
- `servePlaceIds` and `globIgnorePaths` come from Rojo's project-format docs, and the serve crash
  from rojo-rbx/rojo#1314. These aren't package source, but the guide criteria depend on them.
- `t` facts (what `t.Vector3` checks, published versions) come from the t source and the Wally
  index, since t isn't installed in the sandbox.

## Notes

- The skill gate never requires `rojo-workflow`, so it loads in with-skill trials only through its
  description or the prompt hint (the words rojo, pesde, or syncback). Only `fix-project`'s prompt
  says "rojo".
- The description says to load the skill "before the first edit, new file, or Studio change" in a
  Rojo repo. The sandbox is a Rojo repo, so by that wording almost every coding prompt in every
  eval should trigger it. The trigger set labels repo edits true (including two with no Rojo
  words) and keeps the negatives to questions with no edit, other tools (Argon, npm, Unity),
  plain Studio, and sibling topics (Module Loader lifecycle, Jest matchers).
