A stop-hook check ran `luau-lsp analyze` and found 4 errors in `Placement.server.luau`, and I've fixed what caused them. Your luau-lsp setup doesn't resolve `require("@game/...")` paths. I changed the two requires to instance paths, `require(ReplicatedStorage.Shared.BlockTypes)` and `require(ReplicatedStorage.Shared.PlacementRules)`.

The two `Unknown type 'BlockTypes.BlockType'` errors came from the failed require, so they should clear with it. The analyzer didn't flag `const`, so I kept it.

I couldn't re-run the analyzer to confirm, so this still needs a pass of `luau-lsp analyze` and `stylua --check`. Nothing else in the script changed.