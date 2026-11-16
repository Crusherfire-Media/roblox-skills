I've fixed all three bugs and one more problem with the sound, in `PlacedBlocks.luau` and `BuildHud.luau`. I couldn't test any of it: there was no way to run a playtest, and my command to check for a formatter or type-checker was denied in this session. Please check it in Studio.

**"Blocks placed" stuck at 0** (`PlacedBlocks.luau`)
- `onBlockPlaced` and `clear` were changing the history table in place and then setting the signal to that same table. Charm only notices a change when it gets a different table, so the count never moved. In Studio, Charm also locks the tables it stores, which is where "attempt to modify a readonly table" came from. On live servers the change just went unnoticed, so there was no error.
- `onBlockPlaced` now copies the list, adds the new block to the copy and stores the copy. `clear` stores a fresh empty list.
- Both functions now set their two values in one `Charm.batch`, so the HUD updates once per placement instead of twice.

**"Last:" always "none"** (`BuildHud.luau`)
- The label read the Charm value directly. Vide (the UI library) doesn't track Charm values, so the label showed the first value forever. It now goes through `VideCharm.useSignalState`, the same way the count already did.

**Extra click each time you hide and show the HUD** (`BuildHud.luau`)
- Each time the HUD was shown, it started a new sound listener with `Charm.subscribe`, and nothing stopped it when the HUD was hidden. That's why each hide and show added one more click. It's now wrapped in Vide's `cleanup`, so it stops when the HUD hides.

**Sound fix you didn't mention:** the click listened for changes to the last block type. Placing the same type twice in a row didn't change it, so the second placement made no sound. It now plays whenever the placed count goes up. Every placement clicks, and Clear stays silent.

The HUD's layout, text and Clear button are unchanged. The click still only plays while the HUD is visible, as it did before.

**What to check in Studio:**
1. Place several blocks, including two of the same type in a row. The count should go up each time, "Last:" should show the type, and each placement should click once.
2. Press H several times, then place a block. You should hear exactly one click.
3. Press Clear. It should show 0 and "Last: none", with no sound.

Two other things I noticed and left alone:
- **Vide strict mode is off.** It catches mistakes like these during development. Adding `Vide.strict = RunService:IsStudio()` in `Main.client.luau` turns it on in Studio only.
- **No UI previews:** the project has no UI Labs setup (UI Labs is a Studio plugin that previews UI components without a playtest), so I didn't add a preview (a "story") for the HUD. I can set that up if you want.