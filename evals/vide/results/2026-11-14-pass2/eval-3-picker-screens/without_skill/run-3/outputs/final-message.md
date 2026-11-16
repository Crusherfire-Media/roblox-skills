The picker now adapts to phones, tablets, laptops and big monitors. When the device changes mid-session it updates right away. The type checker, selene and stylua all pass. I haven't run it in Studio or on a real device, so the sizes below are worked out on paper and still need a look in the device emulator.

**What the picker does now**
- **With a keyboard and mouse, or a gamepad:** it stays as a column on the left with block names, like before, but it scales with the screen. It's 1× at 1080p, about 1.33× at 1440p and 2× on 4K. Laptops never go below 1×, so text doesn't shrink below what you designed. Gamepad players get 25% larger, for viewing from across the room.
- **On touch:** it moves to a row along the top centre, which keeps it clear of the thumbstick (bottom-left) and the jump button (bottom-right). Tiles are 48 instead of 40, above the usual 44-point minimum for tapping. The names next to tiles are hidden, and the title still shows the selected block.
  - Phones stay at 1×.
  - iPads scale up to about 1.4×, depending on the model.
- **Switching mid-session:** rotating, resizing the window or changing input updates the picker immediately. Input is read from `UserInputService.PreferredInput`, so plugging a keyboard into a tablet switches it back to the left column.
- The selection outline now scales with the tile, so it doesn't look hairline-thin on 4K.

**Shared setup for future screens** (in `StarterPlayerScripts/UI/`, also described in the README)
- **`Screen`:** wrap each new screen in it. It sets up the window to stay clear of the Roblox top bar and phone notches, survive respawns, and scale everything inside it.
- **`Responsive`:** live values a screen can read, like input type, viewport size, orientation, scale and the minimum touch size. Use it when a screen needs to change shape, not just size, as the picker does on touch.
- New screens just use the sizes you'd pick at 1080p (or in points on a phone), and scaling is handled for them.

**Things to know**
- On a touchscreen laptop the picker will flip between layouts as you switch between touch and mouse. That's on purpose, but if you find it jarring it's a one-line change.
- With 5 blocks the touch row fits even a narrow phone held upright. If you add many more block types, the row will need to scroll or wrap.
- The top-centre position on touch is my judgement call. Bottom-centre is the usual hotbar spot, but Roblox's thumbstick touch area is wide enough to overlap a centred bar in landscape.

I haven't committed anything.