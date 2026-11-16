I haven't fixed these errors because they come from an out-of-date `sourcemap.json`, not from the code. Your checks look up module paths in that file, and it doesn't list the scripts and modules in `Shared` or `StarterPlayerScripts`. It does list the `Shared` and `Packages` folders themselves.

What points to the sourcemap:
- **Files that were there before my change fail too.** `BlockTypes` and `BlockPlacer` were already committed, yet the requires on unchanged lines like `BlockPicker.luau:8` and `BlockPlacement.server.luau:11` also show "Unknown require".
- **The `Unknown type` errors follow from the failed requires.** `PlayerData.PlayerData` and `BlockTypes.BlockType` can't resolve once their modules can't.
- **Requires into `Packages` resolve.** Charm, CharmSync, Vide and VideCharm show no errors, because the sourcemap lists that folder. The paths themselves are written correctly.

I tried to rebuild the sourcemap at the start of the checks, but that command needed approval, which this session can't give. To clear the errors, run this from the project root, then run `luau-lsp analyze` again:

```sh
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
```

If any errors remain after that, they're real, and I'll fix them.