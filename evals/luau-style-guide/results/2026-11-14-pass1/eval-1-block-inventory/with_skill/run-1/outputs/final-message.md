The two luau-lsp errors are fixed. `BlockInventory.luau` now passes luau-lsp with the project's Roblox definitions (`globalTypes.d.luau`) and passes StyLua's check.

- **Unknown require:** the require path was fine. `sourcemap.json` was out of date and listed neither `BlockTypes` nor the new module, so luau-lsp couldn't find the file. I regenerated it with `rojo sourcemap`, so `sourcemap.json` now shows as changed in git alongside the new module.
- **Unknown type `BlockTypes.BlockType`:** this cleared once the require resolved. Running the full check then turned up one real type error: the loop over `BlockTypes.Order` widens each entry to a plain `string`, so it didn't fit the counts table. I added a cast to `BlockType` on that line with a short comment explaining it. How the module behaves hasn't changed.

The earlier summary still applies. The module still hasn't been run in Studio.