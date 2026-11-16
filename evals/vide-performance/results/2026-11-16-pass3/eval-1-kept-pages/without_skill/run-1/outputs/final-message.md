Switching tabs and reopening the menu should now be smooth after the first time. Each page and the menu itself are now built once and kept, and later switches just show or hide them. Luau analysis, selene and stylua all pass, but I couldn't run the game in Studio, so I haven't measured the frame times. The note explains how to check that.

**What was causing it:** Every tab switch threw the old page away and built the new one from scratch, which is where your ~450 and ~370 instances come from. Closing the menu also threw the whole menu away after it slid out, so reopening rebuilt whatever page it was on.

**What I changed:**
- **Pages are kept** (`BuildMenu.luau`). A page is built the first time its tab is shown. After that, switching tabs only hides one page and shows another.
- **The menu is kept** (`Main.client.luau`). It's built on the first open and never destroyed. It still slides in and out the same way. Once it has fully slid off-screen it's hidden, so it costs nothing while closed.
- **It still looks the same.** A page that comes back scrolls to the top again, and the rainbow swatch starts its colour cycle from the beginning, just as a newly built page did. The first open still slides in from below.
- **No work while hidden.** The rainbow swatch stops updating whenever the Colors page can't be seen.

The first open of the menu and the first visit to each tab still cost about what they did before, since that's when those pages get built.

The note is in `docs/perf/build-menu.md`. To check: in the MicroProfiler, switching tabs and reopening the menu should show normal ~8 ms frames instead of 30–40 ms ones. You can also print the instance count under `BuildMenuGui` (run it as the client); it should stay the same no matter how often you switch.