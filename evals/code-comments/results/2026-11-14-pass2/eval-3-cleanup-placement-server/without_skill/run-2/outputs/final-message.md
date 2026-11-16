I've cleaned up the comments in `Placement.server.luau`. Only comments changed; the code is the same. I haven't committed anything.

**What I removed:**
- The header block, including the changelog. It mostly repeated what the code does, and git history covers the changelog.
- Comments that just described the next line, like `-- set the name`, `-- the Players service` and `-- Increment the block count`.
- The `-- ===== Cooldown =====` style dividers and the `end -- if` / `end -- for` markers.
- The `@param` docblocks on `isFiniteNumber` and `onPlaceBlock`.
- Commented-out code: the old Region3 query and the debug `print`.
- Three comments that were wrong:
  - `-- TODO: add a cooldown`: the cooldown is already there.
  - `-- Uses Region3 ...` on `isOccupied`: it uses `GetPartBoundsInBox`.
  - `-- Changed from 0.5 to 0.15 after playtest feedback`: that's history, not something you need to read the code. I kept the line under it about the 0.2 s click repeat.

**What I kept:** comments that explain *why*:
- Keep `GRID_SIZE` in sync with the client.
- The design doc reference for `MAX_HEIGHT`.
- The NaN trick in `isFiniteNumber`.
- Shrinking the overlap box so blocks that only share a face don't count.
- The reach tolerance, cut down from five lines to three.
- The ownership check in `onRemoveBlock`.
- The DataStore TODO.
- The `stylua: ignore` directive and the section banners.

**Things to check before you commit:**
1. **Block limit mismatch.** The comment said `Limit is 100 blocks per player`, but `MAX_BLOCKS_PER_PLAYER = 200`. I removed the comment and left the value at 200. If 100 is the real limit, the number is wrong.
2. **Broken doc link.** The header pointed to `docs/placement.md`, which doesn't exist in the repo, so I dropped that pointer.
3. **Missing client script.** The `GRID_SIZE` comment mentions `PlacementClient`, which isn't in the repo yet. I kept the comment because it still applies once the client script exists.

I couldn't run StyLua or Selene to double-check formatting, because commands that need approval are blocked in this session.