The HUD now works with touch and with a controller, and it switches layout live when the player's input or screen changes. The type-check, selene and stylua pass. None of it has been run in Studio, so nothing has been seen on screen yet. Nothing is committed.

**How it works:** a new `UI/Screen.luau` tracks the screen size, the player's main input (as Roblox reports it), whether it's a TV, and controller connects and swaps. It then picks one of four layouts. Picking up a controller on PC, or plugging a keyboard into a tablet, changes the layout on the spot.

| | PC | Phone | Tablet | Xbox / controller |
|---|---|---|---|---|
| Hotbar | Same as before | 2×5 grid, 46 px slots, placed between the thumbstick area and the jump button | 2×5 grid, 56 px slots, same placement | 1×10, 56 px slots, LB/RB button icons on each side |
| Switch blocks | Number keys, click | Tap | Tap | LB/RB, wrapping round at both ends |
| Build mode | `B` or click | Button at top right, under the coins | Button just above the jump button | `Y` |
| Inventory | `I` or click | Button beside it | Button stacked above it | `X` |
| Prompts | `[B]`-style key labels | None | None | Xbox or PlayStation icons from Roblox, with text if Roblox has none |

- **Block names:** touch and controller have no mouse hover, so the block name shows for 2 seconds after each switch. It also shows while controller UI navigation is on a slot.
- **Bigger screens:** the whole HUD grows on 1440p and 4K screens, and by a quarter more on a TV. Controller text is 26 px, the console readability guideline for TVs.
- **Small screens:** a phone with a controller, or a small desktop window, gets the compact layout. If the screen is too narrow for the bottom row (a Steam Deck, for example), the hotbar moves up above the buttons.
- **Controller menus:** while controller UI navigation is on a menu, the HUD's controller shortcuts pause so the future inventory screen can use those buttons. Keyboard shortcuts keep working.
- **UI Labs story:** I added `ServerScriptService/Stories/Hud.story` with a storybook. It has controls for layout, input, build mode and coins.

**What changes on PC:**
- The build mode hint is now a clickable button with a background, and it reads `[B] Build: On`.
- The inventory button is a little wider (140 px instead of 120).
- Slots and buttons darken when you hover or press them.
- At 1080p everything else looks the same, including the hover tooltip.

**For you to decide or pass on:**
- **Button mapping:** I picked Y, X and LB/RB and left both triggers free for block placement. Please check this with the other dev. If it changes, update the keys in both `Main.client.luau` and `UI/Hud.luau`.
- **Jump button position:** the phone and tablet layouts use the default jump button position, not a live reading. If you have custom touch controls, that needs changing.
- **Inventory screen:** when it's built, it should select something by default when it opens with a controller, close with B, and hide Roblox's touch controls while it's open.
- **Not done:**
  - PC text is still 14 px, below the 18 px PC readability guideline. Raising it changes the PC look, so I left it to you.
  - The HUD doesn't follow the player's Roblox settings for text size, background transparency or reduced motion.
  - Vide's strict mode isn't turned on anywhere. Adding `Vide.strict = RunService:IsStudio()` would catch more mistakes in Studio.

**To check in Studio:**
1. Open the story and switch through the four layouts.
2. In the Device Emulator, look at a 667×375 phone, a 568×320 phone, an iPad, 1080p, 4K and Xbox.
3. Switch device mid-playtest to confirm the layout follows.
4. Check that tapping a slot over the thumbstick area always selects the block rather than starting the thumbstick.

I also had the Roblox reviewer go over the change. It found no blockers. I fixed the five problems it raised, including the four PC-behavior and layout ones above.