Both analyzer errors come from setup, not from the code, so I've left the files as they are:

- **`Packages/t` (line 10):** t isn't installed yet. It will resolve once you run `pesde install` and regenerate the sourcemap, as listed in `PR_DESCRIPTION.md`.
- **`Shared/BlockTypes` (line 12):** this require was already in the file before my change. It fails because `sourcemap.json` is out of date: it has a `Shared` folder but no entry for `BlockTypes` or `BlockPlacement`. Running `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` (the README's first check command) will fix it.

After installing and regenerating the sourcemap, run `luau-lsp analyze` again; both errors should be gone. I can't run either command from here.