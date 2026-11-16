I cleaned up the comments in `src/ServerScriptService/Placement.server.luau`. Only comments should have changed; the code lines should be identical. I couldn't check that with `git diff`, because the command needs approval and this session can't grant it. Please glance over `git diff` before you commit.

**Counts:** about 45 comments deleted, 6 rewritten or shortened, 6 kept as they were.

- **Deleted:** comments that just restated the code, `end -- if` markers, the `===== Cooldown =====` style dividers inside `onPlaceBlock`, the changelog in the header, the old commented-out Region3 code, the commented-out `print`, and doc blocks that only repeated function names and parameters.
- **Rewritten:**
  - The header now just says what the script does.
  - The five-line reach-check explanation is now one line: `One cell of slack: the server's character position lags the client's`.
  - The ownership check in `onRemoveBlock`, the face-overlap comment and the DataStore TODO were reworded or wrapped to fit 80 columns.
  - The `Private Functions` section title is now in capitals, with a blank line under it.
- **Kept:** the note to keep `GRID_SIZE` in sync with PlacementClient, the "studs" unit on `MAX_REACH`, the cooldown limit, the NaN check, `--!strict`, `-- stylua: ignore`, and the DataStore TODO.

**Things to check:**
- **Possible block-limit bug:** the old comment said "Limit is 100 blocks per player", but `MAX_BLOCKS_PER_PLAYER = 200`. I deleted the comment and left the value alone. Check which number you actually want.
- **Doc that doesn't exist:** the header pointed to `docs/placement.md`, which isn't in the repo. I removed the pointer.
- **Height limit:** `MAX_HEIGHT` cited "design doc section 4.2". I removed that rather than copy over a requirement I couldn't see. If the 200 limit matters, add a comment saying why.
- **Cooldown:** I kept "must stay below the client's 0.2 s click repeat", but I couldn't confirm the client's 0.2 s from this file.
- **Out-of-date comments removed:** "TODO: add a cooldown" (the cooldown already exists) and "Uses Region3" on `isOccupied` (it uses `GetPartBoundsInBox`).

**Not changed:** the Luau style guide also wants `--@author` and `--@date` lines in the header, and `const` for constants and services. Those are code and header changes outside a comment cleanup, so I left them. I can do them separately if you like.