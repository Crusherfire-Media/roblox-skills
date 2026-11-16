I wrote the review to `docs/ui-review.md` and didn't touch any code. It lists 26 problems: 8 Blockers, 6 High, 6 Medium and 6 Low. Each one has the file and line, what players run into, and the fix. It ends with a suggested fix order and a device test checklist.

**The 8 Blockers:**
1. **The HUD disappears after respawn.** The ScreenGui is created from a PlayerScripts script without `ResetOnSpawn = false`. The first time a player resets or falls off the map, the HUD and popup are gone for the rest of the session.
2. **No safe-area handling.** `IgnoreGuiInset = true` puts the coin counter under Roblox's menu button. Edge elements land under phone notches and the home bar, and outside the TV safe area on Xbox.
3. **Menu buttons cover the mobile jump button** in the bottom-right corner.
4. **Menu buttons are blank orange squares.** All icons are `rbxassetid://0`, and the names only appear as hover tooltips. Phones and Xbox have no hover, so most players never see a label.
5. **Xbox players can't really use the UI.** Nothing selects the Claim button when the popup opens, B doesn't close it, and there are no controller shortcuts or button prompts.
6. **No hotbar.** Changing blocks only works with number keys, so phone and Xbox players are stuck with the first block, and nobody can see which block is selected. Gamepad players also can't place blocks at all. That part needs a `BlockPlacer.luau` fix, not a HUD fix.
7. **The Discord link is shown to every player.** Most of your players are kids, and Roblox only allows external links for users whose policy permits them; Discord itself is 13+. The game could get moderated for this. Use the official Social Links on the experience page instead, or check `PolicyService` before showing it.
8. **Rewards can be claimed over and over** by reopening the Rewards button. Once the streak goes past day 7, no tile is highlighted as today.

**Main High issues:** the "Claim in 0:59 or lose your streak / lose your progress" wording pressures kids and isn't even true (nothing happens at 0:00). The popup text is very low contrast (the title is about 1.7:1 and the body about 2.6:1). The popup is a fixed 520×340 pixels, so it clips on small phones and looks tiny on TVs. Touch targets are too small; the Close button is 24 pt. The popup also opens the instant a player joins.

**Contrast numbers are hand-calculated.** The command to double-check them was blocked by permissions. They come from the standard WCAG formula, so expect small rounding differences.