I fixed both problems. Each needed a small change to one file, but I haven't run a playtest to confirm them.

**1. "You can only build on a plot." in some playtests**
- **Cause:** The loader runs `Init()` in `LoaderPriority` order, and modules with the same priority run in no fixed order. `PlotServerService` and `_PlotPlacementMediator` both use the default priority of 0. In some sessions the mediator's `Init()` ran first, before any plots existed, so `GetPlots()` returned nil and crashed. That meant no build areas were ever added, so every click was rejected.
- **Fix** (`PlotSystem/Implementation/_PlotPlacementMediator.luau`): the mediator now adds the plots in `Start()` instead of `Init()`. The loader finishes every `Init()` before it starts any `Start()`, so the plots always exist by then. `AddBuildArea` only adds the plot to a list, so calling it at `Start()` is safe.

**2. Clients never finish loading**
- **Cause:** `RoundServerService:Start()` waited for `ModuleLoader.IsServerLoaded()`. The loader only sets that flag after every `Start()` has returned, including this one, so the server waited on itself forever. It never printed `=== LOADING FINISHED ===`, and clients wait for the server before they start.
- **Fix** (`RoundSystem/SystemPackage/RoundServerService.luau`): `Start()` now runs the round loop in its own thread with `task.spawn` and returns right away. That thread still waits until the server has loaded before the first round, so the "every other system running first" check is kept.

I didn't change the round timings (15s intermission, 120s round). The client still has `WAIT_FOR_SERVER = true`, so clients still wait for the server to finish loading. That setting now works because the server actually finishes.

**To check in a playtest:** the server output should reach `=== LOADING FINISHED ===`, the number keys and clicking should work on the clients, and placing on a plot should succeed in every session, not just some.