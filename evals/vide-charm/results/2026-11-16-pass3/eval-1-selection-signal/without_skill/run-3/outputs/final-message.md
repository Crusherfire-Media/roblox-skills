The selected block type is now a Charm signal owned by BlockPlacer, and `BlockTypeChanged` is gone. The type checker, selene and stylua all pass. I couldn't run it in Studio from here, so the number keys, tile clicks, outline and ghost color haven't been checked in a running game.

**BlockPlacer.luau**
- The plain local is replaced with `Charm.signal(BlockTypes.List[1].Name)`.
- Other scripts read the selection through `BlockPlacer.selectedBlockType`, which is read-only.
- Changes still go only through `BlockPlacer.setBlockType`, which keeps its check against unknown block types. Charm already skips updates when the value hasn't changed, so the manual "same name" check is gone.
- Removed: the `BindableEvent`, `BlockTypeChanged` and `getBlockType`. Nothing references them anymore.
- Number keys still call `setBlockType`, and placing reads the current value from the signal.

**Main.client.luau**
- The mirrored Vide `source` and the event hookup are gone.
- It passes `Selected = BlockPlacer.selectedBlockType` and `Select = BlockPlacer.setBlockType` to the picker, so tile clicks still change the selection.

**BlockPicker.luau**
- It wraps the `Selected` getter with vide-charm's `useSignalState`. Vide doesn't react to Charm signals on its own, and this turns the signal into something Vide can bind to.
- This runs while the UI is being mounted, so the subscription is cleaned up when the UI is removed.
- The tile outline color and thickness read from that, so the yellow outline still follows the selection.
- The prop names didn't change. `Selected` is now documented as a Charm getter.

**PlacementPreview.luau**
- `Charm.listen(BlockPlacer.selectedBlockType, applyBlockType)` replaces the initial `applyBlockType(getBlockType())` call and the event hookup. `listen` runs once immediately and again on every change, so the ghost gets the right color as soon as it's created.