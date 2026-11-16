The catalog should now use **0 CanvasGroups once it's open and settled**, and only 1 during the 0.25 s fade, instead of 41 the whole time. I haven't run it in Studio or on a phone. The only checks I ran were selene and stylua on `BlockCatalog.luau`, and both pass. The flicker fix and the "looks the same" goal still need your eyes on a device. Nothing is committed yet.

**Why phones flicker:** each CanvasGroup draws its contents into its own texture. Phones on low graphics quality have a small budget for those textures, and with 41 of them some cards run out and flicker or draw blank. PC has more room, so it looks fine there.

**Changes (all in `BlockCatalog.luau`; `Main.client.luau` is unchanged):**
- **Cards are plain Frames now.** The shine is a card-sized overlay with the same rounded corners as the card. The stripe is a 20° gradient band on that overlay, and it sweeps across using the same hover animations as before. The rounded corners do the clipping that the per-card CanvasGroup used to do. The overlay is hidden when the card isn't hovered.
- **The panel only uses a CanvasGroup while it fades.** `BlockCatalog` is now a see-through Frame with the content inside a `Panel` frame. While the panel is fading in or out, `Panel` sits inside a `Fade` CanvasGroup that does the fade. Once it's fully open, `Panel` moves directly under `BlockCatalog` and `Fade` is detached. When closing starts, it moves back in. Vide's fade animation lands exactly on fully open, so this switch happens once, at the end of the fade-in.

**How to check:** open the catalog and count the CanvasGroups under PlayerGui with the snippet in the note. Expect 0 when it's open and 1 mid-fade. Then hover some cards and open and close the panel a few times. The real test is a phone at Graphics Quality 1: scroll through every card and look for blanks.

**Two possible visual differences:**
- The stripe is now a rotated gradient rather than a rotated frame. Its lean and width could look slightly different on the 140×72 cards. If they do, adjust `SHINE_ANGLE` or `SHINE_WIDTH`.
- On low quality, text may get slightly sharper at the moment the fade-in ends, because the panel stops being drawn through the CanvasGroup.

The note, with these steps and the snippet, is in `docs/perf/block-catalog.md`.

One of my shell commands (a file listing) was blocked because this session can't approve permission prompts. I used the file search tools instead, so nothing was skipped.