Loading and unloading are fixed in `Builds.server.luau`, and the write-up is in `docs/perf/build-loading.md`. Nothing has been measured yet: the expected numbers in the doc are estimates until you re-take the server and client captures.

**The three luau-lsp errors don't come from this change.** They're caused by an out-of-date `sourcemap.json`:

- The flagged require (`require(ReplicatedStorage.Shared.BlockTypes)`) is exactly the same as in the original file. Only its line number moved.
- The committed `sourcemap.json` lists `ReplicatedStorage.Shared` as an empty folder. `BlockTypes.luau` isn't in it at all, so luau-lsp can't resolve the require. The two `BlockTypes.BlockType` "unknown type" errors follow from that.
- The project files are fine: `default.project.json` maps `Shared` to `src/ReplicatedStorage/Shared`, and `BlockTypes.luau` is there and exports `BlockType`.

**Fix:** run `rojo sourcemap default.project.json -o sourcemap.json` and re-run luau-lsp. I tried to build a fresh sourcemap in a temp folder to confirm this, but the session couldn't approve the command, so it didn't run. I also didn't regenerate the tracked `sourcemap.json`, because that's outside this task.

StyLua and selene both pass on the new file. Without Roblox definitions files, luau-lsp also flags every Roblox global (`Vector3`, `Instance`, `task` and so on), so the code still hasn't been properly type-checked.