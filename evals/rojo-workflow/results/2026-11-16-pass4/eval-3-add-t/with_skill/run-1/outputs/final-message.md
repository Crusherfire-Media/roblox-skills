I fixed one of the two luau-lsp errors. The other will stay until t is installed.

- **`Unknown require: …/Shared/BlockTypes` (fixed):** `sourcemap.json` was out of date. It had neither `BlockTypes` nor `BlockPlacement`. I regenerated it with `rojo sourcemap`, and luau-lsp now finds the module. The file is generated and listed in `.gitignore`, so this doesn't add anything to the diff.
- **`Unknown require: …/Packages/t` (expected until install):** t isn't installed, so there's no `roblox_packages/t` for luau-lsp to find yet. This is the install step you said you'd do yourself. It clears once you run `pesde install` and then regenerate the sourcemap (steps 1 and 3 in `PR_DESCRIPTION.md`). Once t is installed, run luau-lsp again to check the type casts against t's actual types.

selene and `stylua --check` both pass on the edited script. No playtest has been run, and the changes still aren't committed.