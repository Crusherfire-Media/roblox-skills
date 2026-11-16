One of the two luau-lsp errors is fixed and the other will clear once you install t.

- **`Unknown require: …/Shared/BlockTypes` (fixed):** this was a stale `sourcemap.json`, not a code problem. It had no children under `ReplicatedStorage.Shared`. I regenerated it with `rojo sourcemap` and the error is gone. The file is gitignored, so this changes nothing in the diff.
- **`Unknown require: …/Packages/t` (still there):** t isn't in `roblox_packages` because I haven't run `pesde install`, which you asked to do yourself. It should clear after you install and regenerate the sourcemap, as the PR description says.

`stylua --check` and `selene` both pass on `BlockPlacement.server.luau`. There's still been no playtest. I updated the testing section of `PR_DESCRIPTION.md`, which had said no checks were run, to give these results.