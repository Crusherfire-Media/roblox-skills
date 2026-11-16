I wrote the specs in `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`. luau-lsp, selene and `stylua --check` all pass with no errors or warnings. I couldn't run the specs themselves, since Jest only runs in Studio, so none of them have actually been executed. One spec is expected to fail because it shows a bug, explained below. `PlacementRules.luau` is unchanged; the spec file is the only change.

**What's covered**
- **`snap`:** the origin, points inside a cell, points exactly on a cell edge (they go to the cell above), negative coordinates, each axis on its own, and snapping a point that's already a cell center.
- **`validate`, rejections:**
  - **Bad block type:** nil, unknown name, wrong case, empty string, number, table, boolean.
  - **Bad position:** nil, a table shaped like a Vector3, string, number, CFrame, Vector2, and NaN or ±infinity on each axis.
  - **Height:** the cell resting on the Baseplate, the cell just below it, the highest allowed cell and the first one above `MaxHeight`.
  - **Reach:** no character, just inside, exactly at and just past `MaxReach`, distance measured diagonally in 3D, and distance measured to the cell center rather than the raw position.
- **`validate`, occupied cells:** blocked cells are looked up by the snapped center, a cell next to a blocked one is fine, a cell marked `false` counts as free, and `occupied` is never changed.
- **`validate`, check order:** which reason is reported when a request breaks more than one rule.

**Bug found: a cell exactly `MaxReach` away is rejected.** The comment on `validate` says "A cell exactly MaxReach away is in reach", but the code uses `>=` (`PlacementRules.luau:72`), so it says "out of reach". The test "accepts a cell exactly MaxReach away" follows the comment, so it will fail until either the code changes to `>` or the comment changes. The comment above that test explains this. Since the client will use these rules for previews, it's worth deciding which one is right before then.

**Possible issue, but harmless for now:** the comment says the cell center must be above Y = 0, while the code only rejects centers below 0. A snapped center can never be exactly 0, so the two behave the same. I left a note on the matching test rather than marking it as a bug.

**Assumptions**
- The specs check the exact reason strings ("out of reach" and so on). That shows which rule rejected a request, but it means rewording a reason will break the tests.
- Limits come from `PlacementRules.MaxReach`, `PlacementRules.MaxHeight` and `BlockTypes.BlockSize` rather than hard-coded numbers, so changing those values won't break the specs.
- Vector3 results are compared with `toEqual`.

**Permissions:** two combined commands were blocked because this session can't approve permission prompts. One was a first file listing, the other was running StyLua's auto-format together with the checks. Instead, I applied StyLua's two formatting changes by hand and ran each check on its own. Regenerating `sourcemap.json` left it identical to the committed copy.