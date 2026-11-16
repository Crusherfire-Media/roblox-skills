I've rewritten the catalog so CanvasGroups only exist while something is animating. With the catalog open and nothing hovered, there should now be 0 instead of 41. I haven't run any of this: shell commands needed approval and were denied in this session, so I couldn't play-test in Studio or run stylua/selene.

**What changed** (only `BlockCatalog.luau`; `Main.client.luau` didn't need anything):

- **Cards** are now plain Frames with rounded corners. The shine sits in a small CanvasGroup with the same corner radius, which is attached to a card only while that card is hovered or its shine is still fading out. That group still clips the shine to the rounded corners, as before.
- **The panel** is a normal Frame. It's placed inside a CanvasGroup (which handles the transparency) only while it's fading in or out. Once the fade-in finishes, the group is removed and the panel draws directly. The open and close fades work as before.
- Colours, sizes, corner radii, timings and click handling are all the same. Some cards no longer clipped their contents anyway, so the rounded corners and contents should look identical.

**Expected CanvasGroup count:** 0 when open and idle, 1 while hovering a card (briefly 2 when moving between cards), and 1 plus any shining cards during a fade.

**How to check it** is in `docs/perf/block-catalog.md`, along with what changed:
1. A command-bar snippet that counts CanvasGroups in PlayerGui. It should print 0 when open and 1 while hovering.
2. Look at it yourself: the panel should fade both ways, and the shine should stay inside the rounded corners.
3. Run Studio's phone emulator with Quality Level 1, or a real phone with graphics turned down, to confirm the flicker and blank cards are gone.

**Two things to watch when you play-test:**
- The panel moves into its fade group at the moment closing starts. If you see a single-frame blink there, that's where it comes from.
- I'm assuming a CanvasGroup with a transparent background still clips its contents to its rounded corners. Check the corners while a card is hovered.