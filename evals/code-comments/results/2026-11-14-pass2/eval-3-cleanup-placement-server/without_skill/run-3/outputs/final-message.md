I cleaned up the comments in `src/ServerScriptService/Placement.server.luau`, going from 102 lines removed to 26 added. I checked the diff: every changed line is a comment, so the code itself is untouched. I haven't committed anything.

**Removed:**
- Comments that just repeat the code (`-- set the name`, `-- Create the part`, `-- connect PlaceBlock`, …), plus the `-- if` / `-- for` / `-- isFiniteNumber` markers after each `end`.
- The section banners (`-- SERVICES --` and so on) and the `@param`/`@return` doc blocks. Your other scripts don't use either style.
- The changelog in the header, since git history covers it. The header is now a two-line description with the pointer to `docs/placement.md`.
- Commented-out code: the old Region3 lines in `isOccupied` and the leftover `print` at the end of `onPlaceBlock`.
- Comments that were no longer true:
  - `-- Uses Region3 to find…` on `isOccupied`: it uses `GetPartBoundsInBox` now.
  - `-- TODO: add a cooldown…`: the cooldown is already there, right below it.
  - "Changed from 0.5 to 0.15 after playtest feedback" on `PLACE_COOLDOWN`. That's history, so I kept only the rule that it must stay below the client's 0.2 s repeat.

**Kept, because they explain things the code can't:** the "keep in sync with the client" note on `GRID_SIZE`, the design-doc reference on `MAX_HEIGHT`, the NaN trick, why the overlap box is shrunk, the ownership check in `onRemoveBlock`, and the DataStore TODO. I also shortened the reach-tolerance explanation from five lines to three.

**Before you commit, check these:**
1. **Block limit:** the old comment said "Limit is 100 blocks per player", but `MAX_BLOCKS_PER_PLAYER = 200`. I removed the comment and left the value alone, so confirm 200 is what you want.
2. **Missing references:** the comments point to `docs/placement.md` and a `PlacementClient` script, and neither exists in the repo yet. I left both pointers in, assuming those files are coming. If they aren't, those notes should go too.