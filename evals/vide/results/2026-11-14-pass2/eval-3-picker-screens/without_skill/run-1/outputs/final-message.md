The picker now changes its size and layout to fit the device. It updates on its own when the window is resized, a tablet is rotated, or the player switches between touch, keyboard and gamepad. The type check, selene and stylua all pass with 0 errors and 0 warnings. I haven't run it in Studio or on a real device, so the sizes and layout changes still need checking in the device emulator or on your phone, iPad and 4K monitor. Nothing is committed.

**What the picker does now**
- **Phones and tablets:** it's a row of tiles across the top centre, with the selected block's name underneath. That keeps it away from the thumbstick in the bottom left and the jump button in the bottom right. Tiles are at least 48 points on phones, which is comfortable for a finger, and get a bit larger on an iPad.
- **Keyboard and mouse, or gamepad:** it's the same left-side column you built, with block names. While a keyboard is in use, each tile shows its number key (1–5).
- **Very small windows** (any input) use the top row too.
- **Sizing:** your 1080p layout is now the baseline. It scales 2× on a 4K monitor, never drops below 0.8× on small laptops, and gets an extra 1.25× with a gamepad for couch distance.
- **Switching input:** the layout follows the same setting Roblox uses to show or hide its touch controls. So if someone plugs a keyboard into a tablet, the thumbstick disappears and the picker switches to the column at the same moment.

**Shared setup for future screens** (in a new `StarterPlayerScripts/UI/` folder)
- `UI/Responsive.luau` keeps track of the input type (touch, keyboard and mouse, or gamepad), the scale, the usable screen size, and a size class: Compact for phones, Medium for tablets, Large for monitors. Each one updates live.
- `UI/Screen.luau` wraps a screen's root UI object (the ScreenGui) and applies the scale for you. A new screen is laid out at 1080p sizes, wrapped in `Screen({ Name = ..., Children = { ... } })`, and comes out the right size everywhere. It only needs to check `Responsive` if it should be arranged differently on different devices.

**Other changes**
- **Respawn fix:** the picker's UI used to be deleted every time the character respawned, because it was mounted only once. Screens now survive respawning.
- **No overlap:** the picker now stays clear of the Roblox top bar and any phone notch.
- `BlockPlacer` now provides the hotkey labels, so the picker's number badges always match the keys that actually work.

**Worth knowing**
- **Outline thickness:** I didn't check whether the selection outline gets thicker along with everything else. On a 4K screen it may look thin, so take a look.
- **Gamepad:** a gamepad player can only reach the tiles through Roblox's built-in menu navigation. There's no button that switches blocks the way 1–5 do. If you want one, the shoulder buttons cycling through blocks would be the natural addition in `BlockPlacer`.