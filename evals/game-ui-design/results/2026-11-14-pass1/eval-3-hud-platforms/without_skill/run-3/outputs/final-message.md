I've adapted the HUD for touch and controller, and it switches layout as soon as the player changes input. Selene, stylua and luau-lsp all pass. **I haven't run it in Studio**, so nothing below has been seen working on a real phone, tablet, Xbox or controller.

**How it picks a layout** (new `InputMode.luau`)
- It watches every input and picks keyboard/mouse, touch or gamepad from the latest one. Picking up a controller on PC switches to the gamepad layout; touching the mouse switches back.
- Analog sticks and triggers only count once pushed past halfway, so a drifting controller on the desk won't keep flipping a mouse player's HUD.
- Mouse events in the first second after a touch are ignored, because some touch devices send fake mouse events.
- If the last controller is unplugged, it falls back to keyboard/mouse or touch.

**Layouts** (`UI/Hud.luau`)
- **PC:** looks the same as before (same sizes, positions, number keys, hover tooltip and `[B]`/`[I]` hints). Slots and the inventory button now respond to `Activated` instead of `MouseButton1Click`, which also works for taps.
- **Touch:**
  - Slots are 44–52 px, sized to fit and kept clear of the jump button. On very small phones (iPhone SE size) the hotbar wraps to two rows of 5 so slots don't shrink below 44 px.
  - Build mode and Inventory get real buttons on the right edge, since there are no keys. This matters because tapping the world places blocks.
  - The bottom-left corner is left free for the thumbstick.
  - There's no hover, so the selected block's name shows above the hotbar for 1.5 s after picking one.
- **Gamepad/TV:**
  - Bigger slots (up to 64 px) and 22 px text.
  - Real controller button images from Roblox, so PlayStation pads get PlayStation icons. LB/RB icons sit on either side of the hotbar.
  - The same brief name display as touch.
  - On consoles everything stays within 5% of the screen edges, in case the TV crops the picture.
  - HUD buttons can't be selected by controller UI navigation, so the navigation button can't trap the stick in the hotbar.

**Controls** (`Controls.luau`, `Main.client.luau`)
- B and I on keyboard are unchanged.
- Controller: **LB/RB** step through blocks (wrapping at the ends), **X** toggles build mode, **Y** opens the inventory. These take priority over Roblox's default controls and backpack.
- All bindings live in `Controls.luau`, and the HUD's button icons read from the same table, so changing a binding there updates both.

**Bug fix:** the HUD's ScreenGui now has `ResetOnSpawn = false`. Before, the HUD could disappear after the player died, because `Main.client` only builds it once.

**Before launch:**
1. **Ask the block-placement dev about X/Y/LB/RB.** I don't know which buttons they use (R2 is the usual place button). My bindings take priority over theirs, so a clash would block their input.
2. **Turn off the HUD's controller buttons while the inventory is open.** Once the inventory screen is real, LB/RB/X would still change blocks and build mode underneath it.
3. **Test on real devices.** The touch layout relies on where Roblox puts its jump button on small and large screens, which Roblox could change. Check it on an actual small phone and a tablet.
4. **Mixed controllers:** if someone swaps an Xbox pad for a PlayStation pad without touching anything else, the button icons won't update until they switch input type and back.

I haven't committed anything. Running the formatter also regenerated `sourcemap.json` to include the two new modules.