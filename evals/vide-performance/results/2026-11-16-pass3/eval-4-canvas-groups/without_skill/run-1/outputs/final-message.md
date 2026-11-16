I fixed the catalog and wrote the note, but none of it has been run. The lint/type/format checks were blocked in my session, and I couldn't test anything in Studio or on a phone.

**Cause:** every CanvasGroup draws its contents into its own off-screen texture and keeps it as long as it exists, even when nothing in it changes. With 41 of them, low-quality phones run past their texture budget, so the catalog flickers and some cards draw blank. PC has more room, which is why it looks fine there.

**What changed (only `BlockCatalog.luau`):**
- **Cards:** each card is now a plain Frame instead of a CanvasGroup. The shine is a card-sized overlay with the same rounded corners, and a gradient on it draws the stripe. Hovering moves the stripe across the card, and the rounded overlay keeps it inside the corners. Width (28 px), 20° lean, strength and timing are the same as before.
- **Panel:** it only sits inside a CanvasGroup while it's fading. Once it's fully open, it moves straight into a plain frame and the CanvasGroup is removed. On close it moves back in and fades out as before.
- **Result:** 0 CanvasGroups while the catalog is open and still, 1 during the 0.25 s fade (down from 41). `Main.client.luau` didn't need changes.

**Things to check:**
- **Run the README checks** (sourcemap, `luau-lsp analyze`, `selene`, `stylua --check`). `stylua` may want to reformat the new shine-width constant.
- **The shine's angle.** Gradient rotation is measured in the card's stretched shape (140×72), so I converted the 20° to match what the old rotated stripe looked like. I'm fairly sure that's how Roblox handles it, but not certain. If the stripe leans differently than before, set `SHINE_GRADIENT_ROTATION = SHINE_ANGLE`.
- **Renamed object.** The panel content now lives in a child frame called `Panel` under `BlockCatalog`. Nothing in `src` looks for the old layout.

The note is in `docs/perf/block-catalog.md`. It has a command-bar snippet that counts CanvasGroups in PlayerGui: it should print 0 once the catalog is open, 1 during a fade, and it printed 41 before. It also lists what to look at on screen and how to test on a phone at low graphics quality.