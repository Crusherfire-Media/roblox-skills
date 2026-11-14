I cleaned up the comments in `src/ServerScriptService/Placement.server.luau`. I only meant to change comments, not code. I tried to confirm that with a script that compares the code lines before and after, but it needed a permission approval this session can't give, so it didn't run. I compared them by eye instead. Run `git diff` before you commit to be sure.

**Counts:** about 60 comments deleted, 5 rewritten, 6 kept, plus the section banners and the `--!strict` and `-- stylua: ignore` directives, which stay as they were.

**Deleted:**
- Comments that just repeat what the code says, including `end -- if` markers and the docblocks that only restate a function's name and parameters.
- The `===== Cooldown =====`-style headers inside `onPlaceBlock`.
- The changelog in the file header. That history belongs in commit messages.
- Commented-out code: the old Region3 lines and the `print` call.
- Wrong or outdated comments:
  - "Limit is 100 blocks per player" sat above `MAX_BLOCKS_PER_PLAYER = 200`.
  - `isOccupied` was described as using Region3. It uses `GetPartBoundsInBox`.
  - The cooldown TODO was already done.
  - "Changed from 0.5 to 0.15 after playtest feedback" was history, not an explanation.
- "Max height per the design doc, section 4.2". A section number goes out of date, and the constant needs no comment.

**Rewritten:**
- The file header is now one line describing what the script does. I dropped the pointer to `docs/placement.md` because that file doesn't exist in the repo.
- The five-line reach-tolerance comment is now two lines: one extra cell of tolerance, because the server's character position lags the client's.
- The RemoveBlock ownership check now just says the client can send any instance.
- I rewrapped the persistence TODO to fit 80 columns.

**Kept:** the GRID_SIZE keep-in-sync note, the units on `MAX_REACH`, the cooldown limit (must stay below the client's 0.2 s click repeat), the NaN check note, the note on shrinking the overlap box, and the DataStore TODO.

**Things to check:**
- There's no `PlacementClient` in this repo, so I couldn't confirm the GRID_SIZE sync note or the client's 0.2 s click repeat. I kept both. Check they still match the client.
- The DataStore TODO describes real missing work: blocks are deleted when a player leaves. I kept it so that doesn't get lost.
- The `MAX_BLOCKS_PER_PLAYER` comment said 100, but the value is 200. I trusted the code and removed the comment. If 100 was the intended limit, the constant is the bug.