The three luau-lsp errors are false alarms, so I didn't change any code for them. The cause is an out-of-date `sourcemap.json`, not the edit:

- Both modules exist at the paths the story uses: `src/StarterPlayer/StarterPlayerScripts/BlockTile.luau` and `src/ReplicatedStorage/Shared/BlockTypes.luau`.
- `sourcemap.json` doesn't list either file, so luau-lsp can't find them. That causes the two "Unknown require" errors. The third error, `Unknown type 'BlockTypes.BlockType'`, follows from the `BlockTypes` one.
- The flagged lines (the two requires and the `blockType()` return type) were already in the story before my edit. My change only reorganized the controls and the reads of them.

I couldn't rebuild the sourcemap here because this session can't run commands that need approval. To clear the errors, run `rojo sourcemap default.project.json -o sourcemap.json`, then run `luau-lsp analyze` again. That run will also type-check the new grouped controls.