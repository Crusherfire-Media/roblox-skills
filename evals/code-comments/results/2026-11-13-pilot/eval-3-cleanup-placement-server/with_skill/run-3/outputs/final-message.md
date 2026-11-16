I've cleaned up the comments in `src/ServerScriptService/Placement.server.luau`. I meant to change only comments and leave the code as it was, but I couldn't confirm that automatically: the script that compares the old and new code with comments removed needed approval, and approval isn't available in this session. Running `git diff` before you commit is the quickest way to check.

**Counts:** about 50 comments deleted, 3 rewritten, 7 kept.
- **Rewritten:**
  - The file header is now one line. I removed the changelog, since that history belongs in commit messages.
  - The reach-tolerance comment went from five lines to one: `-- One extra cell of tolerance: the server's copy of the character lags the client's`.
  - The `Private Functions` banner is now `PRIVATE FUNCTIONS`, with a blank line under it so editors don't show it as part of the first function's description.
- **Kept:** the `GRID_SIZE` keep-in-sync note, the meaning of `MAX_REACH` (studs, measured from the HumanoidRootPart), the `PLACE_COOLDOWN` limit (minus the "changed from 0.5" history), the NaN check note, the note on shrinking the overlap box, the DataStore TODO, and `--!strict` / `-- stylua: ignore`.

**Things you should look at:**
- **The block limit comment didn't match the code.** It said "Limit is 100 blocks per player", but `MAX_BLOCKS_PER_PLAYER = 200`. I deleted the comment. Check which number you actually want.
- **`docs/placement.md` doesn't exist.** The header pointed to it, so I removed that pointer.
- **I couldn't check the sync note.** `PlacementClient` isn't in this repo, so I couldn't confirm it has a `GRID_SIZE` to stay in sync with. I kept the note anyway.
- **Unclear limits:** `MAX_HEIGHT` was described only as "per the design doc, section 4.2", which tells a reader nothing on its own. I removed the reference. If 200 is a hard limit, write the actual reason next to it.
- **Old and finished items removed:** the "add a cooldown" TODO (the cooldown is already there), the `isOccupied` description that still mentioned Region3 (the code uses `GetPartBoundsInBox`), and the commented-out Region3 and `print` code.

**Close calls you may want to undo:**
- I kept `-- The client can send any instance, so check it's one of ours and theirs` in `onRemoveBlock`. The check is fairly clear without it, but it marks the point where the server refuses to trust the client.
- I removed all the `-- ===== Cooldown =====` style headings inside `onPlaceBlock`. The blank lines already split the steps.