The block picker now animates with Vide springs. The type check, selene and stylua all pass, but I haven't run it in Studio, so I haven't seen the motion or tuned the timing in play.

**Sliding in and out**
- The picker uses the exit-delay support built into `Vide.show` in this version. It returns its panel along with a 0.4 s delay, and `show` hands it a `present` flag.
- Its position follows a spring between "on screen" and "just below the screen", driven by that flag. It starts below the screen, slides up, and when build mode turns off it slides down before `show` removes it.
- Spamming B or the Build button is safe. If build mode comes back on during the slide-out, `show` cancels the removal and keeps the same picker, and the spring turns around from wherever it is. Nothing stacks up.
- Tiles can't be clicked while the picker is sliding out.

**Gliding highlight**
- The per-tile yellow outline is gone. There is now one highlight frame drawn over the tiles, and a spring moves it to the selected tile.
- To make that work, the tiles moved into their own inner frame with the list layout, so the layout doesn't pin the highlight in place.

**Tile reactions**
- Each tile watches its button's `GuiState`. A scale spring makes it grow slightly on hover, shrink to 0.86 while pressed, and bounce back when released.
- The scale applies to a button centred inside a fixed slot, so the row doesn't shift when a tile changes size.

The changes are in `BlockPicker.luau` and a small edit to the `show` call in `Main.client.luau`. All the timings and scales are constants at the top of `BlockPicker.luau`.

If you raise `SLIDE_PERIOD`, raise `EXIT_DELAY` with it, or the picker will be removed before it finishes sliding off. Mid-animation reversals already eat into the 0.4 s margin, so watch for the panel vanishing slightly early when you test.