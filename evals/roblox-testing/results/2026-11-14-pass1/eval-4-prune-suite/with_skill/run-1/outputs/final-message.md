I've rewritten `PlacementRules.spec.luau`: it's down from 31 tests to 19, and every test now goes through the public `snap` and `validate` functions. luau-lsp, selene and StyLua all pass. Specs can't run here, so none of the 19 tests have been run. Run `Specs/PlacementRules.spec` in Studio, or let CI run it, before merging. `PlacementRules.luau` is unchanged.

**The two failing tests**
- **"rejects a position that isn't a Vector3"** called its matchers with a colon (`expect(ok):toBe(false)`). Jest Roblox matchers are called with a dot, so this test could never pass.
- **"doesn't mark the cell occupied"** checked that a count of `0` was falsy. In Luau `0` is truthy, so it always failed.

Both cases are still tested, written correctly.

**Why it broke on refactors**
- **Tests reaching inside the module:** the suite tested the private `_isFinite` helper directly and counted calls to `snap`. Both are removed; NaN and infinity are now covered through `validate`.
- **Copied formula:** one test computed its expected value with the same formula the code uses, so it could never catch a mistake.
- **Hard-coded numbers:** many expected values assumed `BlockSize = 4`, `MaxHeight = 200` and `MaxReach = 24`. Those values are now read from the modules, so retuning them won't break the spec.
- **Shared state:** "rejects placing twice in the same cell" only passed because an earlier test had left a shared table filled in. It repeated the occupied-cell test, so it's gone.
- **Block type catalog:** a test copied every block type's colors and materials field by field. That's presentation data owned by `BlockTypes`, not a placement rule, so it's gone.

**Coverage:** every rule the module documents now has a test, including one that had none before: placement is refused when the player has no character. The new suite has:
- 4 snap cases.
- 3 accepted boundaries: the cell resting on the Baseplate, the highest cell allowed, and a cell exactly at max reach.
- 1 check that every block type is accepted.
- 10 rejection cases, each breaking one rule in an otherwise valid request.
- 1 check that `validate` never changes the occupied table.

**Assumptions** (also in the note):
- The rejection tests don't check the reason strings. The module documents them as server-log text, so their wording isn't a promise to callers.
- The spec now uses the style guide's form (`--!strict`, `const`, and `@game/...` string requires) instead of `game:GetService` paths.
- The `_isFinite` export is still in `PlacementRules.luau` because this change doesn't touch that file. Nothing uses it now, so it can be removed later.

The note for the pull request is at `docs/placement-spec-cleanup.md`. Nothing is committed yet.