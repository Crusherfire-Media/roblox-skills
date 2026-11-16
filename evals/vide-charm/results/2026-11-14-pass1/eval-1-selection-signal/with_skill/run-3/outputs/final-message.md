The five "Unknown require" errors came from an out-of-date `sourcemap.json`, not from my changes. I regenerated it with `rojo sourcemap`, re-ran `luau-lsp analyze`, and the three edited scripts now have no errors.

- **Why it was the sourcemap:** every error was on a require that was already in these files (`Shared.BlockTypes` and the sibling modules). The new Charm and VideCharm requires I added resolved fine on the first run.
- **What's still reported:** only type errors inside the installed Vide 0.4.1 and Charm 0.11.1 packages under `roblox_packages/.pesde/`. They come from newer Luau type features, are outside this task, and don't affect the game's code.
- **No new files to commit:** `sourcemap.json` is gitignored, so the working tree still shows just the three edited scripts.

Nothing is committed.