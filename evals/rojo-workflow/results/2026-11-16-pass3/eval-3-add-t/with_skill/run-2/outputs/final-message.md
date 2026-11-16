Neither error can be fixed in the code. Both come from the sourcemap the check reads, and neither will clear before you install:

- **`Packages/t` (line 10):** `t` isn't installed yet, so `roblox_packages/t` doesn't exist and the sourcemap has no entry for it. It should clear once you run `pesde install` and regenerate `sourcemap.json`. That's step 1 and 3 under "Before testing" in `PR_DESCRIPTION.md`.
- **`Shared/BlockTypes` (line 12):** this `require` was already in the file before my change, untouched; adding the `t` require only moved it down two lines. luau-lsp can't resolve it because the existing `sourcemap.json` doesn't map `ReplicatedStorage.Shared.BlockTypes`. Regenerating the sourcemap should fix this one too.

I couldn't regenerate the sourcemap or rerun the checks myself, because this session can't approve shell commands. So both errors, and the full README checks, still need a rerun after the install.