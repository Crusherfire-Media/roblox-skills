I've built the inventory screen with Vide, started it from `Main.client.luau`, and written the design note at `docs/inventory-screen.md`. The project's checks pass: the type check, selene and stylua report no problems. I couldn't run it in Studio from here, so none of the input behaviour (touch, mouse, controller) has been tried in-game yet.

**How it works for players**
- **Opening:** a "Blocks" button sits at the right edge, halfway up, away from the phone thumbstick and jump button. It shows a 3D cube of the block you're building with and how many you have left. On PC you can also press **E**, and on a controller **Y**.
- **The panel:** a grid of all ten block types, each with a 3D preview (so glass and brick look different), its name, and how many you have. Locked blocks are greyed out with a 🔒 and the level that unlocks them. The block you're using has a green border and a ✓. The grid uses up to five columns and drops to as few as two on narrow screens, so tiles stay big enough for a thumb. Everything scales with screen height, from phones up to a TV.
- **Picking:** tap, click, or press **A** on a block to build with it, which also closes the screen. Picking a locked block doesn't work; the footer says which level unlocks it instead.
- **Closing:** the ✕ button, tapping the dimmed area outside the panel, **E**, **B** or **Y**. Opening the Roblox menu closes it too.
- **Controller:** when the screen opens, your current block is already highlighted, the D-pad stays inside the panel, and the screen clears the highlight on close so **A** jumps again. Button hints use the controller's own symbols, so PlayStation controllers show theirs.
- **Hints:** key and button hints follow whatever device the player last used, and are hidden on touch.
- **While it's open:** tapping or clicking the world doesn't place blocks, and the mouse is freed from first person and shift lock. The character can still walk.
- **Reduced Motion:** the pop animation is skipped when this Roblox setting is on.

**Design choices you might want to change**
- Picking a block always closes the screen, so getting back to building is one tap.
- Blocks you have none of can still be picked; they just show ×0 in red.

**Things I noticed but didn't change** (also listed in the design note)
- The number keys in `BlockPlacer` can still select a locked block, because it doesn't know about `BlockInventory`. I hid the number hint on locked tiles but didn't change `BlockPlacer`.
- `BlockPlacer` only places blocks on a mouse click or tap, so controller players can pick a block but can't place it yet.
- The server doesn't check locks or counts when placing a block.

**Why the files aren't in a subfolder:** I first put the components in `UI/Components/`, but this checkout's folder path is so long that some file paths went over Windows' 260-character limit and the type checker silently skipped them. I wasn't allowed to copy the project somewhere shorter, so I moved everything up into `UI/`. If you'd like the subfolder back, it should check fine from a normal-length project path.

Files are in `src/StarterPlayer/StarterPlayerScripts/UI/`:
- `InventoryScreen.luau` – starts the screen and sets up the keys and controller buttons
- `InventoryState.luau` – keeps the screen in sync with `BlockInventory` and `BlockPlacer`
- `InventoryPanel.luau`
- `BlockTile.luau`
- `OpenButton.luau`
- `BlockPreview.luau`
- `InputHint.luau`
- `Theme.luau`
- `Motion.luau`
- `Props.luau`