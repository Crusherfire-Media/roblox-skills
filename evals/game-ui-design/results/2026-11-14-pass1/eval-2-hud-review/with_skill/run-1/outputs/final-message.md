I wrote the review to `docs/ui-review.md` and didn't change any code. It has 20 findings ranked by harm to play. Each one gives a severity, who it affects, how strong the evidence is, and a concrete fix with sizes or API names.

**Blockers (fix before the next release):**
1. **The Discord link in the HUD** breaks Roblox's Community Standards, which ban showing outside URLs. It puts the whole experience at moderation risk. Remove it and use the Social Links on the experience page instead.
2. **Xbox players get stuck on join.** Every button uses `MouseButton1Click`, which only fires for the mouse, and nothing sets a gamepad selection. Console players can't claim or close the popup that covers the screen when they join. The fix is `Activated`, a default selection, and B to close.
3. **The popup blocks play on join.** Replace the auto-open with a badge on the Rewards button.
4. **The menu sits in the bottom-right corner, on top of the phone jump button.** Move it to the right edge at middle height.

**High-severity problems:**
- **Hidden coins:** `IgnoreGuiInset = true` puts the coin counter under Roblox's own top-bar buttons.
- **HUD may vanish:** it may disappear after the first respawn because `ResetOnSpawn` is still on. Check this by resetting your character in Studio.
- **Pressure on kids:** the popup says "Claim in 0:59 or lose your streak!" That kind of loss threat and countdown is exactly the pressure on children the review recommends against.
- **Repeat claims:** players can claim the reward again and again through the Rewards button, and the tiles show no "today" after day 7.
- **Blank buttons:** the menu buttons are blank orange squares whose names only appear on mouse hover.
- **Tiny targets:** they're 24–36 px; Close is 24 × 24.
- **Clipped popup:** the fixed 520 × 340 panel will likely be cut off on small landscape phones.
- **Contrast and color:** almost every text and tile color pair fails contrast, and the day tiles differ only by color.

The rest are medium and low items, such as the endless pulse on the Rewards button and the 1.5 s toast. The review also lists what's working (keep it) and six playtest and funnel questions.

**Things to check:**
- **Not verified in Studio:** I reviewed from the code only, with no Device Emulator screenshots. The top-bar overlap (#5), the respawn issue (#6), and the clipping on small phones (#11) are marked for checking there.
- **Contrast ratios are hand-calculated:** they're approximate because my script needed approval this session couldn't give. Run them through a contrast checker before the fix pass.
- **Server-side claim:** coins and the streak are set on the client right now. That's outside a UI review, so it gets one line, but the claim needs to move to the server when you fix #8.