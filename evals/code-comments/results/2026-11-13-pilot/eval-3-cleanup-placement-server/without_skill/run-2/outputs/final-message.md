I've cleaned up the comments in `Placement.server.luau`. I only touched comments, not code. I couldn't run `stylua --check` or `selene` because running commands needed approval this session couldn't give, so run those before you commit.

**Removed:**
- Comments that just repeat the line they're on (`-- set the name`, `-- Create the part`, `-- connect PlaceBlock`, and the rest).
- The `-- SERVICES --` style section banners, the `===== Validation =====` dividers, the `end -- if` / `end -- for` markers, and the doc blocks that repeated function signatures. `Main.server.luau` and the client script don't use any of these.
- Dead code left in comments: the old Region3 query and `-- print("placed", ...)`.
- The changelog in the header, since git history covers that. The header is now one line.
- Two comments that no longer matched the code:
  - `isOccupied` said "Uses Region3", but it uses `GetPartBoundsInBox`.
  - `TODO: add a cooldown`, even though the cooldown is already right below it.
- "Changed from 0.5 to 0.15 after playtest feedback". I kept the line about why the value has to stay below 0.2 s.

**Kept**, because these explain why the code is the way it is: the GRID_SIZE sync note, the design doc reference for MAX_HEIGHT, the units for MAX_REACH, the cooldown limit, `stylua: ignore`, the NaN check, why the overlap box is shrunk, the reach tolerance (cut from 5 lines to 2), the warning that the client can send any instance, and the DataStore TODO.

**Check these before committing:**
- **`MAX_BLOCKS_PER_PLAYER` doesn't match its old comment.** The comment said "Limit is 100 blocks per player" but the value is `200`. I deleted the comment and left the value alone, so make sure 200 is the limit you want.
- **`docs/placement.md` doesn't exist**, so I removed the header's pointer to it.
- **There's no `PlacementClient` in the repo yet.** I kept "Keep in sync with GRID_SIZE in PlacementClient" assuming you're writing it next.