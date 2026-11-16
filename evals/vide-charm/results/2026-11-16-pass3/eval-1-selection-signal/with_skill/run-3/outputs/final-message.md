The type check now passes on all four scripts.

The "Unknown require" errors weren't caused by these edits. `sourcemap.json` was out of date and didn't list any of the `src` modules, so the type checker couldn't follow any of the requires. I rebuilt it with `rojo sourcemap default.project.json --output sourcemap.json`. That file is gitignored and generated, so nothing tracked changed.

For this run I told luau-lsp to skip `roblox_packages/**`. The errors it was reporting there are inside the Vide and Charm packages themselves, not in your code.