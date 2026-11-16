I cut the PlacementRules suite from 31 tests to 21 and fixed the two failing tests. The specs haven't been run, since there's no Studio or CI here. luau-lsp (in strict mode), selene and StyLua all pass with no errors. I worked out the edge values by hand against the current settings (block size 4, max height 200, max reach 24), so the first CI or Studio run is the real check. `PlacementRules.luau` is unchanged, and I haven't committed anything.

**Why the two tests failed**
- **"rejects a position that isn't a Vector3"** called its checks as `expect(ok):toBe(...)`. Jest Roblox needs a dot there, so the test crashed instead of checking anything.
- **"doesn't mark the cell occupied"** checked that a count of `0` was falsy. In Luau `0` counts as true, so this test could never pass.
- A third test, "rejects placing twice in the same cell", only passed because the test before it left data in a shared table. Run alone, it failed. Each test now sets up its own data.

**What I deleted, and why it broke on refactors**
- **Tests of internals:** three tests of the private `_isFinite` helper, and one that counted calls to `snap`. NaN and infinity are now checked through `validate`.
- **Tests that could never fail:** two compared the result against the module's own formula, or against `snap()` itself.
- **Duplicates:** one test per block type (`validate` treats them all the same), repeated snap rows, and the "placing twice" test, which repeated the occupied-cell test.
- **Block catalog test:** it pinned every block's color, material and transparency, so any art change broke it.

**What I changed**
- Positions and limits are now written in terms of `BlockSize`, `MaxHeight` and `MaxReach`, instead of numbers that assumed a block size of 4.
- Tests no longer compare the wording of rejection messages. The module only promises "a short reason", so they just check that a reason comes back.
- I added the two rules that had no test: rejecting a player with no character, and leaving `occupied` unchanged when a placement is accepted.

**Assumptions** (all in `docs/placement-spec-cleanup.md`)
- I'd normally confirm the cut list with you first. Since you weren't available, I followed one rule: test each behavior once, through the module's public functions.
- The module's comment says a cell must be at "Y > 0", but the code rejects "Y < 0". They agree in practice because no cell center can sit exactly at 0. For the same reason, there's no way to test whether exactly `MaxHeight` is allowed with the current settings. I left both alone.
- `PlacementRules._isFinite` is now unused, but removing it would mean editing the module.
- `BlockTypes` no longer has any tests. If rules like unique block names matter, they'd go in a separate `BlockTypes.spec.luau`.

The rewritten spec is at `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`.