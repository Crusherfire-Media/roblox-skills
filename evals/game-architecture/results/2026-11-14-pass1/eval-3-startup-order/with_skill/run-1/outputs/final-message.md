I fixed both problems. Each one came from code running too early in the Module Loader's startup sequence.

**1. "You can only build on a plot."**: `_PlotPlacementMediator:Init()` was registering the plots with the placement system. But the plots are only created in `PlotServerService:Init()`, and the loader doesn't fix the order in which two modules' `Init`s run. When the mediator happened to run first, `GetPlots()` returned `nil`, the mediator's `Init` failed, and no build areas were ever registered. So every click got that message. That's why it only broke in some playtests.

- **Fix:** I renamed the mediator's `Init` to `Start` in `PlotSystem/Implementation/_PlotPlacementMediator.luau`. The loader runs every `Start` after every `Init` has finished, so the plots now always exist by then. `AddBuildArea` just adds to a list, so registering a bit later is safe.

**2. Clients never finish loading**: `RoundServerService:Start()` waited for `IsServerLoaded()` and then ran the round loop forever. The loader only marks the server as loaded after every `Start` has returned, so this `Start` never returned and loading never finished. Clients wait for the server to finish loading, so they never started either.

- **Fix:** In `RoundSystem/SystemPackage/RoundServerService.luau`, I moved the wait and the round loop into a function called `runRoundsAsync`. `Start` now runs it on its own thread with `task.spawn` and returns at once. The round still waits for the server to finish loading before the first intermission. The timings are unchanged (15-second intermission, 120-second round). I didn't touch the client-side wait for the server.

I haven't playtested this. To check it, start a playtest and make sure the server output reaches `=== LOADING FINISHED ===` without any `>> Failed`, `Skipping :Start()` or `taking a while` lines. Then try building on a plot a few times across separate playtests, since the first bug only showed up in some of them.