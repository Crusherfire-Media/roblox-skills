I fixed all three bugs and two other places where Vide was used wrong. I checked each fix against Vide 0.4.1's source in `roblox_packages`. I couldn't run selene or stylua because the commands needed approval this session doesn't allow, and nothing has been tested in Studio yet. The picker looks and works the same as before.

**BlockPicker.luau**

- **Outline stays on Brick:** each tile checked once, when it was created, whether it was the selected block, and never checked again. It now updates whenever the selection changes, so the outline colour and thickness follow the block you click or step to.
- **"cannot create a new reactive scope inside another reactive scope":** the info card was built inside a plain function child. Vide treats that as a reactive scope, and the card's own "Selected / Click to select" text needs a reactive scope of its own, which Vide doesn't allow inside another. It now uses `Vide.show(isHovered, ...)`, which builds the card in its own scope and cleans it up when the mouse leaves.
- **Q and E skip blocks and work outside build mode:** every time the picker opened, it added a new Q/E key listener and never removed it. So after a few toggles, one key press stepped several times, and the old listeners kept running after the picker closed. The listener is now registered with `cleanup(...)`, so it's disconnected when the picker closes.
- **Something else:** the selected block's name label was filled in by an effect writing into a second value. It's now computed directly from the selection with `derive`, which is the usual Vide way to do it.

**Main.client.luau**

- **Old pickers left on screen:** destroying a Vide root runs its cleanup steps but doesn't remove the instances it created, so every ScreenGui stayed in PlayerGui. The ScreenGui is now registered with `cleanup(gui)`, so closing build mode destroys it.
- **Something else:**
  - The wait for PlayerGui (`WaitForChild`) now happens before the root is created, because Vide code shouldn't pause partway through.
  - `openPicker` now does nothing if a picker is already open, so it can't create a second one.