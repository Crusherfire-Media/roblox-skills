I fixed both problems. Both came from how the module loader runs startup: it calls `:Init()` on every module, then `:Start()` on every module, one call at a time. Modules with the same `LoaderPriority` run in no fixed order.

**1. "You can only build on a plot."**
`_PlotPlacementMediator` asked `PlotServerService` for the plots during its own `:Init()`. Neither module sets a priority, so the order changed from playtest to playtest. When the mediator ran first, the plots didn't exist yet. It crashed on the nil list and never added any build areas, so every placement was refused.

- `_PlotPlacementMediator.luau`: the work now happens in `:Start()` instead of `:Init()`. Every `Init` finishes before any `Start` runs, so the plots always exist by then, whatever the order.
- `PlotServerService.luau`: `GetPlots()` now stops with a clear message if anything calls it before `Init`, instead of handing back nil and failing somewhere else.

**2. Clients never finish loading**
`RoundServerService:Start()` waited for `IsServerLoaded()`. But the server is only marked loaded after every `Start` has returned, so it was waiting for itself and never returned. The server never reached `LOADING FINISHED`. Clients wait for that, so they never loaded either.

- `RoundServerService.luau`: `Start()` now runs the round loop in its own thread and returns straight away. That thread still waits until the server is fully loaded before the first round.

The round timings (15s intermission, 120s round) are unchanged, and clients still wait for the server to finish loading before they start.

`selene` and `stylua --check` pass on the gameplay systems. I didn't run the `luau-lsp` type check (it needs a fresh sourcemap generated first), and I can't playtest here, so please check it in Studio. A shell command I tried while looking around was blocked by the permission settings, but I got the same information with the file tools, so nothing was missed.