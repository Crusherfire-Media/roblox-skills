I cleaned up the comments in `src/ServerScriptService/Placement.server.luau` and didn't intend to change any code. I tried to confirm that with a script that compares the code before and after, comments stripped. The session's permissions blocked it, so that's unconfirmed. Skimming `git diff` before you commit should show only comment lines removed or reworded.

**Counts:** about 60 comments deleted, 3 rewritten, 7 kept unchanged.

- **Deleted:** comments that just restated the code, `end -- if` / `end -- for` markers, the `===== Cooldown =====` style sub-banners inside `onPlaceBlock`, the changelog in the file header, the "changed from 0.5 to 0.15" history note, and two blocks of commented-out code (the old Region3 lookup and a `print`).
- **Rewritten:**
  - The file header is now a two-line description. I removed the pointer to `docs/placement.md` because that file doesn't exist in the repo.
  - The five-line reach-tolerance explanation is now two lines.
- **Kept:** `--!strict`, `-- stylua: ignore`, the top-level section banners, the GRID_SIZE sync note, the studs note on `MAX_REACH`, the cooldown limit, the NaN check, the face-sharing shrink, the "client can send any instance" check, and the DataStore TODO.

**Things to check:**
- **Wrong comment on `MAX_BLOCKS_PER_PLAYER`:** it said "Limit is 100 blocks per player", but the value is `200`. I deleted it. If 100 was the real limit, the code needs fixing.
- **Design-doc reference on `MAX_HEIGHT`:** it pointed to "the design doc, section 4.2". I deleted it rather than writing out the requirement, because the number explains itself. If that section held a reason for 200, it's worth putting back in your own words.
- **Done TODO:** "TODO: add a cooldown" was deleted because the cooldown is already implemented.
- **Comments I couldn't verify:** `PlacementClient` isn't in this repo. So I couldn't check that its grid size is also 4, or that its click repeat is 0.2 s. I kept both comments because they look like real limits.
- **Close call:** I kept the DataStore TODO in `onPlayerRemoving`. Right now every player's blocks are destroyed when they leave, so it marks a real missing feature.