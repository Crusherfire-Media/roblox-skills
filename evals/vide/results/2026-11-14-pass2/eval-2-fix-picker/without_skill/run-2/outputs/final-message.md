I fixed all three bugs and three other cases of Vide being used wrong. I couldn't test any of it: running selene, stylua and luau-lsp needed approval, and this session couldn't grant it. I checked the edits by reading the code against Vide 0.4.1's source, but please try them in Studio.

**The reported bugs**

1. **Yellow outline stuck on Brick** (`BlockPicker.luau`): each tile checked whether it was selected once, when it was built, and never again. The outline colour and thickness now come from a value that updates whenever the selection changes, so the outline follows your choice.
2. **"cannot create a new reactive scope inside another reactive scope" on hover**: the info card was built inside a plain function, which Vide treats as a reactive scope. The card has its own reactive text ("Selected" / "Click to select"), so building it there threw that error. I switched it to `Vide.show(isHovered, ...)`, which builds and removes the card in its own scope.
3. **Old pickers left on screen, E skipping blocks, Q/E working outside build mode**: there were two leaks.
   - In `Main.client.luau`, closing the picker shut down its Vide scope but never destroyed the ScreenGui, because Vide doesn't destroy instances it created. Closing now destroys the ScreenGui.
   - In `BlockPicker.luau`, the Q/E key listener was never disconnected. Every time you entered build mode, another listener was added, and they all kept firing. That's why E skipped several blocks and Q/E worked outside build mode. The listener is now disconnected when the picker closes.

**Other Vide misuse I fixed**

- **Picker label**: it used an `effect` to copy the selected name into a second `source`. It's now a plain function that reads the selection directly, which is how Vide expects it.
- **Waiting inside the scope**: `Main.client.luau` called `WaitForChild("PlayerGui")` inside `root()`, and Vide scopes shouldn't pause like that. It now waits once at the top of the script.
- **Double-open guard**: if the picker is already open, opening it again now does nothing, so a second copy can't appear.

**One behaviour change:** I set `ResetOnSpawn = false` on the ScreenGui. Before, dying in build mode would delete the picker while build mode stayed on, so the screen and the actual state disagreed. Now the picker stays until you press B. Remove that line if you'd rather it disappear on respawn.

The picker looks and works the same otherwise.