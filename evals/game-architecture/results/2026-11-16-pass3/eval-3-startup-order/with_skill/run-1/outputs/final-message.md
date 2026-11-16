I fixed both problems. Each was a startup-order bug, and each fix is a few lines. I haven't run a playtest, so I haven't confirmed the fixes in Studio.

**1. "You can only build on a plot." in some playtests**

`_PlotPlacementMediator` asked `PlotServerService:GetPlots()` for the plots during its `Init`. But `PlotServerService` only builds the plots in its own `Init`. The two modules have the same load priority, so the loader can run their `Init`s in either order. When the mediator went first, the plot list didn't exist yet. That's the "attempt to iterate over a nil value" error. Because of it, no plot was ever registered as a build area, so every placement was refused. That's why it only happened in some playtests.

**Fix:** the mediator now does this work in `Start` instead of `Init` (`PlotSystem/Implementation/_PlotPlacementMediator.luau:12`). Every `Init` finishes before any `Start` runs, so the plots always exist by then.

**2. Clients never finish loading**

`RoundServerService:Start()` waited for the server to finish loading before running rounds. But the server only counts as loaded after every module's `Start` has finished, and this `Start` never finished, so it waited forever. The server never reached `=== LOADING FINISHED ===`. Your clients wait for the server to finish loading before they start, so they hung too: no number keys and no placing.

**Fix:** `Start` now runs the round loop on its own thread and returns right away (`RoundSystem/SystemPackage/RoundServerService.luau:36`). That thread still waits for the server to finish loading before the first round, and the round timings (15-second intermission, 120-second round) are the same. Clients still wait for the server before they start.

**To check:** start a playtest. The server output should reach `=== LOADING FINISHED ===`, with no `Failed to init`, `Skipping :Start()` or `taking a while` lines for these modules. Then confirm you can build on a plot, and that blocks are cleared when a round ends.

**Not changed:** `RoundServerService` requires the module loader by its full path. Your project's conventions say a SystemPackage module should get modules from outside its package through a reference on its folder instead. It doesn't cause either bug, so I left it alone.