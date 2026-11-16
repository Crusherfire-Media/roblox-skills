I've rewritten the spec so it only tests what `PlacementRules.luau` documents, and written the PR note at `docs/placement-spec-cleanup.md`. I couldn't run the specs here. luau-lsp, selene and `stylua --check` all pass on the new spec. `PlacementRules.luau` is unchanged and nothing is committed.

**Why the two tests failed** (worked out by reading the code, not by running it):
- **"rejects a position that isn't a Vector3"** used `expect(ok):toBe(false)` with a colon instead of a dot, so it could never pass.
- **"doesn't mark the cell occupied"** checked `expect(count).toBeFalsy()`. In Lua, `0` counts as true, so the test failed even when `validate` behaved correctly.

Both are fixed.

**Removed:**
- **The formula-based snap test:** it copied the snap formula into the test, so it was checking the code against itself.
- **The three `_isFinite` tests:** `_isFinite` is a private helper. NaN and infinity are now tested through `validate` instead.
- **The "calls snap exactly once" spy test:** it checked how `validate` works inside, so any refactor broke it.
- **"rejects placing twice in the same cell":** it only passed because an earlier test filled a shared `occupied` table.
- **The BlockTypes colors/materials test:** those aren't placement rules, so it broke on any palette change.

**Changed:**
- There's no shared state any more, so tests don't depend on run order.
- Each rejection test starts from one known-good request and changes a single input.
- Tests no longer check the exact wording of rejection reasons.

**Added coverage for documented rules that weren't tested:**
- A player with no character is rejected.
- Infinite positions are rejected (before, only NaN was tested).
- Block type names that aren't strings, and positions that are `nil` or a string, are rejected.
- Reach is measured to the cell's center, not the raw click position.
- The cell next to an occupied one is still accepted.

The suite went from 31 to 35 tests, mostly short table rows. Every rule in `validate`'s doc comment now has at least one accept case and one reject case.

**Assumptions** (also in the spec header and the PR note):
- **Reason strings:** they're only for the server log and nothing reads them, so tests just check that some reason comes back.
- **Hard-coded numbers:** the expected values assume `BlockSize = 4`, `MaxHeight = 200` and `MaxReach = 24`. Changing those changes the rules, so the specs would need updating.
- **Height wording:** the comment says "Y > 0" but the code rejects `Y < 0`. No cell center can sit at exactly 0, so the two behave the same and the spec doesn't try to tell them apart.

Two of my commands were blocked by the permission system. They only bundled several checks into one command, so I ran each check on its own instead.