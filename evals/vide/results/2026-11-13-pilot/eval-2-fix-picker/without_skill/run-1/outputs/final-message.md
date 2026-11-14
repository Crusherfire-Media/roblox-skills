I fixed all three bugs and two other places where Vide was used wrong. StyLua and Selene pass with no errors. I couldn't test it in Studio, so it's worth a quick playtest. The type checker (`luau-lsp analyze`) reported errors, but they're all inside the Vide package or are module paths it couldn't find. None are in the code I changed.

**1. Yellow outline stuck on Brick** (`BlockPicker.luau`, `tile`)
The tile checked whether it was selected only once, when it was first built, so the outline never updated. It now checks every time the selection changes, so the outline color and thickness follow the selected block.

**2. "cannot create a new reactive scope inside another reactive scope"** (`tile`)
The hover card was built inside a plain function child. Vide treats that as a reactive scope, and the card's "Selected / Click to select" text is a reactive value, which can't be created inside one. It now uses `show(isHovered, ...)`, which builds the card in its own scope.

**3. Old pickers left on screen, E skipping blocks, Q/E working outside build mode**
Two separate leaks caused this:
- **Old pickers:** Destroying a Vide `root` doesn't destroy the instances it created, so every ScreenGui stayed in PlayerGui. `Main.client.luau` now calls `cleanup(gui)` inside the root, so the gui is removed when you leave build mode.
- **Skipping and Q/E outside build mode:** The Q/E key handler in `blockPicker` was never disconnected, so each time you opened the picker another handler piled up. One E press then stepped once per handler, and they kept running after the picker closed. The connection is now passed to `cleanup(...)`, so it's disconnected along with the picker.

**Other Vide problems I fixed**
- The selected-name label was kept in sync by an `effect` copying into a separate `source`. That's an anti-pattern in Vide, and it briefly showed an empty label. It's now a plain function that derives the name from the selection, and the unused `effect` import is gone.
- `WaitForChild("PlayerGui")` was called inside the `root`. That can pause while the UI is being built, so I moved it to the top of the script.
- `openPicker` now closes any existing picker first, so opening it twice can't leave an orphan behind.

The picker's layout, sizes, colors and behavior are otherwise unchanged.