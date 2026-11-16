I fixed both problems with a small edit to each of two files. I haven't playtested it, and a shell command I tried for listing the files was blocked by the permission settings. I read the files directly instead.

**1. "You can only build on a plot." in some playtests**

`_PlotPlacementMediator` asked for the plots in its `Init`, but `PlotServerService` only creates them in its own `Init`. The loader runs `Init`s in no fixed order when their priorities are equal. When the mediator's `Init` ran first, the plot list was still empty, the mediator failed, and no plots were ever registered as build areas. That's why it only broke in some playtests.

The fix moves the mediator's work from `Init` to `Start` in `PlotSystem/Implementation/_PlotPlacementMediator.luau`. The loader finishes every `Init` before running any `Start`, so the plots always exist by then.

**2. Clients never finish loading**

`RoundServerService:Start()` waited for the server to finish loading, then ran the round loop forever. But the server only counts as loaded after every `Start` has returned, so this `Start` was waiting for itself and never returned. Clients wait for the server to finish loading before they start, so they stalled too, which is why the number keys and clicks did nothing.

The fix moves the wait and the round loop into their own function in `RoundSystem/SystemPackage/RoundServerService.luau`. `Start()` now launches it with `task.spawn` and returns right away, so the server finishes loading. The loop still waits for loading to finish and for at least one player before the first round.

The round timings (15-second intermission, 120-second round) and the client wait are unchanged. `_RoundPlacementMediator` was fine and I didn't touch it.

**To check it:** run a few playtests. The server output should reach `=== LOADING FINISHED ===`, with no `Failed to init`, `Skipping :Start()` or `taking a while` lines for these modules. Then confirm that clicking on a plot places a block.