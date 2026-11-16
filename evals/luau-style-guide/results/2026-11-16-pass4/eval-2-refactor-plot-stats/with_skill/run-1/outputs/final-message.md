I fixed both type errors that luau-lsp found in `PlotStats.luau`. I still can't run luau-lsp here, so I haven't confirmed the file now passes. The next check will show that.

- **Line 54:** `Block.Position` is typed as always present, so comparing it to `nil` was a type error. Untyped callers can still send blocks with no `Position`, so the check has to stay. I cast it to `Vector3?` for that one comparison and added a short comment saying why.
- **Line 122:** luau-lsp reads the loop variable over the block type list as a plain `string`. I cast it back to `BlockType` where it looks up `counts`. This is a known luau-lsp gap, not a real bug.

Both are type-only changes, so all four functions behave exactly as they did before.