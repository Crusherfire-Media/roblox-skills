I fixed the three luau-lsp errors in `GhostPreview.luau`. I haven't re-run the analyzer myself, so the next stop check will be the confirmation.

- **Two require errors:** the analyzer here can't resolve the `@game/...` alias. The file now requires through `ReplicatedStorage.Shared.BlockTypes` and `ReplicatedStorage.Shared.PlacementRules`, using a new `ReplicatedStorage` service binding. I didn't use a relative path instead because Roblox copies this script into the player's PlayerScripts at runtime, where `../..` would point somewhere else.
- **Unknown type `BlockTypes.BlockType`:** this only appeared because the require didn't resolve, so the same change should clear it.

Nothing else in the file changed.