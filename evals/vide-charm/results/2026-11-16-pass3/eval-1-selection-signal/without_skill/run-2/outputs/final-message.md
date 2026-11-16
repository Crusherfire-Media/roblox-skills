The selected block type is now a Charm signal owned by `BlockPlacer`. The hotbar and the ghost block both read it from there, and `BlockTypeChanged` is gone. selene and `stylua --check` both pass. I haven't run it in Studio, so number keys, tile clicks, the outline and the ghost color still need checking there.

**`BlockPlacer.luau`**
- The selection is now `Charm.signal(BlockTypes.List[1].Name)`. `BlockPlacer.getBlockType` is the signal's getter, so anything reading it inside Charm code updates when the selection changes.
- `setBlockType` still rejects unknown names, then sets the signal. I dropped the early return for an unchanged name because Charm already skips updates when the value is the same.
- Placing a block reads the signal, and the `BindableEvent` and `BlockTypeChanged` are removed.

**`BlockPicker.luau`**
- `Selected` is now a Charm getter. The component turns it into a Vide source once with `VideCharm.useSignalState`, and the tile outlines read that source.
- This step is needed because Vide doesn't notice Charm signal changes on its own. Without it, the outline would draw once and never update. The source is cleaned up when the hotbar is removed.

**`Main.client.luau`**
- The copied Vide source and its event connection are gone. It now passes `BlockPlacer.getBlockType` and `BlockPlacer.setBlockType` straight to `BlockPicker`.

**`PlacementPreview.luau`**
- `Charm.listen(BlockPlacer.getBlockType, applyBlockType)` colors the ghost right away and again on every change. This replaces the old initial call plus event connection.

Number keys and tile clicks still go through `setBlockType`, so they now update the signal.