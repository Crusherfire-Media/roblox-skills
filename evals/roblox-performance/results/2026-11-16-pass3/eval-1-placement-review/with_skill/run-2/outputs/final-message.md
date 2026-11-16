That luau-lsp error doesn't come from my change, so I've left it alone.

It points at line 10, the `require(ReplicatedStorage.Shared.BlockTypes)` line, which was already in the file and which I didn't touch. "Unknown require" from luau-lsp usually means it couldn't map Roblox paths to files, typically because no Rojo sourcemap was built. A wrong require would cause a different error, and `src/ReplicatedStorage/Shared/BlockTypes.luau` does exist. The client script `BlockPlacer.luau` uses the same require. It wasn't checked only because I didn't edit it.

My edit only removed `VALID_NAMES` and swapped the check to look the name up in `BlockTypes.ByName`. luau-lsp reported nothing else for the file.