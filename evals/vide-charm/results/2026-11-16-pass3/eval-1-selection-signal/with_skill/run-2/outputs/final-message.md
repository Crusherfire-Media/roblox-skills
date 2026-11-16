The selected block type is now a Charm signal owned by BlockPlacer, and `BlockTypeChanged` is gone. The type check, selene and the stylua check all pass (my first combined check run was blocked by the permission system, so I ran them one at a time). I haven't playtested it, so the number keys, tile clicks, outline and ghost color still need checking in Studio.

**`BlockPlacer.luau`**
- The selection lives in `Charm.signal(BlockTypes.List[1].Name)`. Its setter is private, and `BlockPlacer.getBlockType` is now the Charm getter.
- `setBlockType` still rejects unknown names and then sets the signal. I dropped the "same name, do nothing" check because Charm already skips setting a signal to the value it holds.
- `placeAt` reads `getBlockType()` when firing `PlaceBlock`. Number keys still go through `setBlockType`, so they work as before.

**`Main.client.luau`**
- The copied Vide `source` and its event connection are gone. `app()` now calls `VideCharm.useSignalState(BlockPlacer.getBlockType)`, so the hotbar follows the signal and stops listening when the UI is destroyed.
- Tile clicks still call `BlockPlacer.setBlockType`.

**`BlockPicker.luau`** is unchanged. It already takes `Selected` (a value it can read reactively) and `Select` (a callback) as props. Now `Selected` comes straight from the Charm signal through `Main`. Keeping BlockPicker free of game state lets it be rendered on its own, for example in a UI Labs story. The yellow outline still comes from `props.Selected()`.

**`PlacementPreview.luau`**
- The first color call and the event connection are replaced by `Charm.listen(BlockPlacer.getBlockType, applyBlockType)`. It colors the ghost once at start and again on every change.

**Things you might trip over:**
- BlockPicker has no UI Labs story, and the project has no storybook yet. I didn't add one because the component didn't change.
- `Vide.strict` isn't set anywhere. Adding `Vide.strict = RunService:IsStudio()` in `Main.client.luau` would catch impure effects and yields while developing.

Nothing is committed.