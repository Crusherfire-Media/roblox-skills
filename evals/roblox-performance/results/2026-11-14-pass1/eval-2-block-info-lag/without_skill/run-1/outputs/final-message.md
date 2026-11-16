I rewrote `BlockInfo.client.luau` so the work it does each frame no longer grows with the number of blocks. I also wrote the report at `docs/perf/block-info.md`. All four checks in the README pass (stylua, selene, rojo sourcemap, luau-lsp analyze), but I couldn't run anything in Studio, so the speedup isn't measured yet.

**What was costing time:** every frame, the script listed every block in the folder three times:
- once to count blocks by type;
- once to find the block under the mouse, checking the type, position and distance of every block (the most expensive part);
- once for the "Total" line.

On top of that, it created a new raycast settings object and filter table, rebuilt the panel text piece by piece, and set the label text, all every frame. That makes about 6,000-entry lists three times per frame, and that throwaway memory is what the GC label after `Script_BlockInfo` was cleaning up.

**What I changed:**
- **Counts:** they now update only when a block is added to or removed from `Workspace.Blocks`. Blocks already in the build are counted once when the script starts.
- **Hover:** blocks are stored in a lookup by grid cell. After the raycast, the script checks at most 27 nearby cells instead of every block. The rule is unchanged: the nearest block center within `BlockSize` of the point the mouse ray hits. Ties still go to the earliest-placed block, as before.
- **Raycast settings:** created once. The filter that ignores your character is updated when you respawn.
- **Panel and highlight:** the text is rebuilt and the label written only when a count or the hovered block changes. The highlight is only updated when the hovered block changes.

What players see should be the same: same panel text, counting rules, hover behaviour and highlight.

**One assumption:** placed blocks never move or get renamed. That's true now, because the server creates them anchored and names them before adding them to the folder. If you later add moving or renaming blocks, the script will need to handle that.

**What to check in Studio** (also in the report): with your 6,000+ block build, `Script_BlockInfo` in the client MicroProfiler should be far below 2.5 ms and stay flat as the build grows. The GC label after it should be gone from most frames. Phone FPS on the big build should be close to an empty baseplate. Also check:
- the counts when placing blocks and when joining a server that already has a build;
- the hover on block faces, edges, corners and the baseplate next to a block;
- that hover still ignores your character after you respawn.

Nothing is committed. One shell command (listing files and printing the script together) was blocked by the permission system, so I read the files with the file tools instead. It didn't affect the result.