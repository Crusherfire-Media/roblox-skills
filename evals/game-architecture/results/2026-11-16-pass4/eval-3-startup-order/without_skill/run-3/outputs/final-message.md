I fixed both problems with one small change each. I haven't run a playtest, so please try it in Studio to confirm.

**1. "You can only build on a plot." in some playtests**
`_PlotPlacementMediator` asked for the plot list during `Init`. The plots are only created in `PlotServerService:Init()`. The module loader runs modules with the same `LoaderPriority` in no fixed order, and neither module sets one. So in some sessions the mediator ran first, got `nil`, and errored. No plots were ever registered as build areas, which is why every click was rejected.

**Fix:** the mediator now does this work in `Start` instead of `Init` (`PlotSystem/Implementation/_PlotPlacementMediator.luau`). The loader finishes every module's `Init` before any `Start` runs, so the plots always exist by then. I checked that `AddBuildArea` is safe to call at that point. Clients wait for the server to finish loading before they act, so nobody can click before the plots are registered.

**2. Clients never finish loading**
The loader runs each module's `Start` one at a time and waits for it to return before moving on. It only marks the server as loaded after every `Start` has finished. `RoundServerService:Start()` waited for "server loaded" and then ran the round loop forever. Neither of those ever ends, so the server never got to `=== LOADING FINISHED ===`. Clients wait for that, so their modules never started.

**Fix:** `RoundServerService:Start()` now runs the same code on a separate thread with `task.spawn` and returns straight away (`RoundSystem/SystemPackage/RoundServerService.luau`). The round loop still waits for the server to finish loading before the first round. The timings are unchanged (15 s intermission, 120 s round), and clients still wait for the server before starting.