Opening the menu and switching tabs should now be smooth after each page's first visit. Pages are built once and then kept, and switching only hides and shows them. I haven't run it in Studio. Selene and StyLua pass, but I couldn't confirm the MicroProfiler numbers from here. The type checker reported errors, but they all come from an outdated `sourcemap.json` and Vide's own type definitions, not from the code I changed.

**What was causing it:** every page was destroyed and rebuilt each time you switched to it. That's the ~450 instances for Shapes and ~370 for Colors. Closing the menu also destroyed the whole menu, so reopening it rebuilt whatever page was current.

**What changed:**
- **`Main.client.luau`:** the menu is mounted once and stays. Closing slides it out with the same animation as before, and it's hidden once the slide finishes instead of being destroyed.
- **`BuildMenu.luau`:**
  - Each page is built the first time you open that tab in an open menu, then kept. Switching tabs only changes which page is visible.
  - Nothing is built at startup, so a tab you never open costs nothing.
  - The rainbow swatch stops updating while it's hidden.

The menu's layout, colors and slide animation are the same. One small visible difference: the rainbow swatch used to restart at red each time you opened Colors. Now it carries on from the color it was on.

The first visit to Shapes or Colors in a session will still spike like before, since that's when the page is built. If you want that gone too, the pages could be built ahead of time, spread over a few frames.

The note is in `docs/perf/build-menu.md`. It explains the change and how to check it in Studio:
- **MicroProfiler (Ctrl+F6):** after visiting each tab once, switching tabs and reopening the menu on Shapes or Colors should stay near your normal ~8 ms frame.
- **Explorer:** under `BuildMenuGui > BuildMenu > Page`, switching tabs should only change a page's `Visible`, with no pages added or removed.