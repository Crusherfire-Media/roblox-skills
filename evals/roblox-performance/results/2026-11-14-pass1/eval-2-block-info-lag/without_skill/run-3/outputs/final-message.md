I rewrote `BlockInfo.client.luau` so its per-frame work stays the same size no matter how big the build gets, and wrote the report in `docs/perf/block-info.md`. I haven't tested it in Studio, so I don't have new MicroProfiler numbers yet. The type checker (luau-lsp), the linter (selene) and the format check (stylua) all pass.

**What was costing time:** the whole script ran every frame in `RenderStepped`, and most of it scaled with the number of blocks:
- It called `blocksFolder:GetChildren()` three times a frame. Each call builds a new 6,000-item list, which is almost certainly what caused the GC label right after the script.
- Counting looped over every block, and the hover lookup read `IsA` and `Position` on every block and measured its distance.
- Every frame it also made a new `RaycastParams`, rebuilt the panel text and set `Text` (which makes the engine redo text layout), and set `Adornee`, even when nothing had changed.

**What I changed (what players see is the same):**
1. **Counts:** they're now kept up to date when blocks are added or removed, instead of being recounted every frame.
2. **Hover:** blocks are grouped by their 4-stud grid cell. Since the hover radius is no bigger than one block, a qualifying block can only be in the cell under the mouse or the 26 around it, so only those are checked. The distance test and "nearest block wins" rule are unchanged, including highlighting a block when you point at the ground right next to it.
3. **Raycast:** one `RaycastParams` is reused, and its filter is only updated when your character changes.
4. **Panel:** the text and `Adornee` are only set when a count or the hovered block changes.

Each frame now does one raycast and at most 27 cell lookups.

**This relies on three things that are true of the current server code:**
- Blocks never move after they're placed.
- Blocks are never renamed.
- `HOVER_RADIUS` stays at or below the block size.

If any of those change, the script needs updating. The report says how.

**What to check in Studio:**
- On the same 6,000-block build, `Script_BlockInfo` should be tiny and flat, and the GC label should be gone or much rarer.
- On a 20k–50k block build, it should cost about the same as at 6,000. Joining a server with a big build causes one short spike while the existing blocks are counted; that's expected.
- On your phone, the frame rate should recover. If it's still low while `Script_BlockInfo` is cheap, the remaining cost is drawing the blocks, not this script.
- Behaviour should be unchanged:
  - Counts update right away when you place or delete blocks.
  - The highlight and "Pointing at" behave as before on block edges and corners, and on the ground next to a block.
  - The raycast still ignores your character after you respawn.

Nothing is committed yet.