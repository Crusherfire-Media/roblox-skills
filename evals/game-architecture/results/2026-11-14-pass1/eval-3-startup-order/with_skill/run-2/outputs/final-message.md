I've fixed both problems. I couldn't run a playtest from here, so neither fix has been tested in Studio yet.

**1. "You can only build on a plot." in some playtests**

`_PlotPlacementMediator` read the plot list in its `Init`. But `PlotServerService` only creates the plots in its own `Init`. The loader runs `Init`s in no fixed order when priorities are equal, so in some playtests the mediator ran first. It got `nil` back and errored, and no plot was ever added as a build area. That's why placement was refused everywhere, but only some of the time.

**Fix** (`PlotSystem/Implementation/_PlotPlacementMediator.luau`): the mediator now adds the plots in `Start` instead of `Init`. Every `Init` has finished before any `Start` runs, so the plots always exist by then.

**2. Clients never finish loading**

`RoundServerService:Start()` waited for `ModuleLoader.IsServerLoaded()` and then ran the round loop forever. The loader only marks the server as loaded after every `Start` has returned, and this one never did. So the server never finished loading, and clients waited forever.

**Fix** (`RoundSystem/SystemPackage/RoundServerService.luau`): `Start` now runs the round loop on its own thread and returns straight away. I removed the server-loaded wait and the `ModuleLoader` require it used. The wait isn't needed: by the time `Start` runs, `_RoundPlacementMediator` has already connected to `RoundEnded`, and the first 15-second intermission gives everything else time to start.

The round timings (15-second intermission, 120-second round) are unchanged. Clients still wait for the server to finish loading before they start, which now actually happens.

When you playtest, check that the output reaches `=== LOADING FINISHED ===` and has no `>> Failed`, `Skipping :Start()` or `taking a while` lines. Then confirm you can build on a plot and that blocks clear when a round ends.

The permission check blocked my `git status` command, so I couldn't see the full working-tree status. It shows a lot of `D` (deleted) entries for the Notification and Placement system files even though the Placement files are on disk. I haven't touched any of them, but it's worth a look before you commit.