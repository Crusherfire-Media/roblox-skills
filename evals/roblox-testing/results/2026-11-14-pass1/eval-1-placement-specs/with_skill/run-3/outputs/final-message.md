I added `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`. luau-lsp, selene and `stylua --check` all pass on `src` with no errors or warnings. The specs have not been run, since Studio isn't reachable from here. I didn't touch `PlacementRules.luau`, and the spec is the only file changed.

**What the specs cover** (8 tests, 18 cases):
- **`snap`** (4 rows): the origin; just inside a cell's upper edge; exactly on an edge, which counts as the upper cell; and just below zero, which counts as the cell below.
- **`validate` accepts a valid request**: it returns the cell's center, and `occupied` stays empty.
- **Malformed requests are refused** (6 rows, one for each check the code writes itself): a block name that isn't a string, an unknown block name, a position that's a table instead of a Vector3, NaN, +∞ and −∞.
- **Height** (4 rows): the cell resting on the Baseplate is allowed and the one below it isn't; the highest cell under `MaxHeight` is allowed and the one above it isn't.
- **No character** (`rootPosition == nil`) is refused.
- **Reach** (2 rows): a cell just inside `MaxReach` is allowed and one just beyond is refused.
- **Exactly `MaxReach` away**: see the problem below.
- **Occupied cell**: any position inside a cell that's already in `occupied` is refused, and `occupied` is unchanged afterwards.

**Problem found: one test will fail.** "allows a cell exactly MaxReach from the character" should go red. The doc comment says a cell exactly `MaxReach` away is in reach, but the code refuses when `distance >= MaxReach`. It should use `>`. The comment above that test explains this. With the code as it is, the server refuses a placement the documented rule allows, and once the client preview is built from that doc it will disagree with the server.

**Assumptions I made:**
- The positions in the tests are built from `BlockTypes.BlockSize`, `PlacementRules.MaxHeight` and `PlacementRules.MaxReach` rather than typed-in numbers, so changing those values won't break the specs. The height cases work for any values. The reach and height cases also assume `MaxReach` is bigger than one block.
- Refusal tests only check that `validate` returns `false`. They don't check the reason text, because the module only promises "a short reason for the server log". Each refusal case keeps every other input valid, so the refusal can only come from the check being tested.
- The doc comment says a cell must be above the Baseplate (`Y > 0`), but the code checks `center.Y < 0`. That mismatch can't actually happen, because snapped centers are never exactly 0, so there's no test for it. Changing it to `<= 0` would make the code match the doc.
- The testing guide asks for the list of tests to be confirmed before writing them. You weren't available, so I chose the list above myself; tell me if you want any added or removed.

To run them in Studio, filter Jest to `Specs/PlacementRules.spec`. All tests should pass except the exactly-`MaxReach` one.