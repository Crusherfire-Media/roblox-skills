Those five errors are gone. The cause was the out-of-date `sourcemap.json`, not the code: it didn't list `BlockTypes`, `BlockPicker`, `BlockPlacer` or `PlacementPreview`, so luau-lsp couldn't resolve their requires. The flagged require lines were already there before this task.

I regenerated the sourcemap with `rojo sourcemap default.project.json --output sourcemap.json` and ran `luau-lsp analyze` on `StarterPlayerScripts` again. It reports no errors in `src`. `sourcemap.json` isn't tracked by git, so this doesn't add anything to the diff.

The errors still reported are all inside the installed Vide and Charm packages under `roblox_packages/.pesde`. They come from the package source, not from anything I changed.