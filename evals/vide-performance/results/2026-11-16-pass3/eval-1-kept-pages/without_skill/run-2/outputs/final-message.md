Opening the menu and switching tabs should now be smooth after the first time, but I haven't run it in Studio, so the MicroProfiler numbers still need checking on your end. Selene and StyLua both pass on `src`.

**What I changed**

- **Pages are kept (`BuildMenu.luau`).** Vide's `switch` used to throw away the current page and rebuild the new one on every tab switch, which is where the 450 and 370 instances came from. Each page is now built the first time you visit its tab and then kept. Switching tabs only shows or hides it.
- **The menu is kept (`Main.client.luau`).** The menu used to be destroyed every time it closed and rebuilt when it opened. Now it's created on the first open and stays. Opening and closing only run the slide, and once it has finished sliding out the panel is hidden so it costs nothing.
- **The rainbow swatch pauses when you can't see it.** It only updates while the Colors tab is showing and the menu is open, since the page no longer gets destroyed when hidden.
- **It looks the same.** The first open still slides in, closing still slides out, and Colors and Shapes still start scrolled to the top every time they appear, as they did when they were rebuilt. If you'd rather they keep their scroll position, delete `scrollToTopWhenShown` and its two uses.

You'll still get one spike the first time you open the menu and the first time you visit Colors and Shapes in each session. I didn't build them ahead of time because that would just move the cost to joining the game or the first open.

**The note:** `docs/perf/build-menu.md` has the same summary plus the steps to check it in Studio:
1. Visit each tab once, which still spikes.
2. Switch tabs and close and reopen the menu on Shapes and on Colors. Those frames should stay close to your normal 8 ms.
3. Check in the Explorer that the `Page` frame keeps the same three page frames and only their `Visible` changes. You can also print the instance count under `BuildMenuGui` before and after switching; it should stay the same.