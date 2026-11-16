I fixed both problems. Each was a startup-order bug, and each fix is a small change in one file. I couldn't run a playtest from here, so this hasn't been checked in Studio yet.

**1. "You can only build on a plot." in some playtests**
`_PlotPlacementMediator` asked for the plot list in its `Init`, but `PlotServerService` only creates the plots in its own `Init`. The loader gives modules with the same priority no fixed order. When the mediator's `Init` ran first, the plot list was still empty and it crashed, so no plots were ever registered as build areas. Every click was then refused. That's why it only broke in some playtests.

**Fix** (`PlotSystem/Implementation/_PlotPlacementMediator.luau`): the mediator now registers the plots in `Start` instead of `Init`. The loader runs every `Init` before any `Start`, so the plots always exist by then.

**2. Clients never finish loading**
`RoundServerService:Start` waited until the server was marked as loaded, then ran the round loop forever. The loader only marks the server as loaded after every `Start` has finished, so this `Start` waited on itself and never ended. The server never reached `=== LOADING FINISHED ===`, and because clients wait for the server, they never loaded either.

**Fix** (`RoundSystem/SystemPackage/RoundServerService.luau`): I moved the wait and the round loop into a separate function, `runRoundsAsync`, and `Start` now launches it on its own thread with `task.spawn`. `Start` returns right away, so the server can finish loading. The first round still doesn't begin until every other system is running.

What stays the same:
- The round timings (15 s intermission, 120 s building round).
- Clients still wait for the server to finish loading before they start.
- Blocks are still cleared at the end of each round.

To check it, start a playtest a few times and confirm that:
- The server output reaches `=== LOADING FINISHED ===`.
- No `>> Failed`, `Skipping :Start()` or `taking a while` lines mention these modules.
- Blocks place on every plot.