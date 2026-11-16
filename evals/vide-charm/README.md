# vide-charm evals (M12)

Four tasks and a trigger set for the `vide-charm` skill. Every task starts from the sandbox plus
the block placement fixtures in `tasks/fixtures/shared/` (copied from `../vide/`): `BlockTypes`,
`BlockPlacement.server.luau`, and `BlockPlacer`. Task fixtures add a hotbar (`BlockPicker`) and
whatever Charm code the task starts from. With-skill trials also load `vide` and `vide-ui-labs`,
since the skill gate requires them for Vide UI edits. How to run them is in `../README.md`.

## Tasks

| Task | What it tests |
|---|---|
| `selection-signal` | Moving the selected block type from a plain local plus `BlockTypeChanged` into a Charm signal owned by `BlockPlacer`: a private setter, a Vide bridge (`useSignalState`) created inside the mounted scope rather than at top level, not passing the raw Charm getter as a Vide prop (the outline would freeze), and a non-UI reader (`PlacementPreview`) moved to `Charm.listen`. |
| `block-stock` | Client stock per block type from a `StockChanged(name, count)` remote: one owning Charm module updated by copying, a value both `BlockPlacer` and the UI need defined once, per-tile counts and a gray-out bridged into Vide, and no Charm getter read inside a Vide binding. |
| `sync-blocks-left` | Getting a server-owned per-player count to the client with CharmSync: server state in Charm, `connect` once, per-player keys, `removeClient` on leave, client `addSignals` before `patch`, a first payload that can't be missed, a shared limit, and a UI that never writes the synced signal. |
| `fix-counter` | Fixing a HUD fed by a Charm store (`tasks/fixtures/fix-counter/`). Reported: a count stuck at 0 (an in-place `table.insert` on the stored table, which errors in Studio where Charm freezes tables), a "Last:" label that calls the Charm getter inside a Vide binding, and a click that plays once more after every hide and show (a `Charm.subscribe` in the component body with no `cleanup`). Unreported, under "anything else": `clear()` has the same in-place bug. |

Checks on `fix-counter` confirm each planted pattern is gone. The other checks are sanity checks
(BlockPlacer requires Charm, `BlockTypeChanged` removed, the stock remote handled on the client,
the CharmSync calls present). Hand-made answers for `selection-signal`, `sync-blocks-left`, and
`fix-counter` passed luau-lsp, selene, StyLua, and every check; the starting points fail every
check that needs work.

## Judge facts

Each task carries the Charm, vide-charm, CharmSync, and Vide facts its correct answer relies on,
checked against the sandbox's package source and named with their files. The one most likely to
matter: Vide tracks only Vide sources and Charm only Charm reads, so a Charm getter read in a Vide
binding never updates (`vide/src/source.luau`, `charm/src/init.luau`).

## Triggers

`triggers.json` holds 10 queries that should load the skill and 10 near misses. The near misses
are Charm without Vide UI (a server computed, CharmSync feeding a music system, a Rodux migration,
`peek` versus `untracked`, a server effect running hot), Vide without Charm (a health bar reading
`Humanoid.Health`, UI-only state with no state library, a UI Labs story for a props-only label), and
neighboring libraries (Reflex with react-lua, Fusion). The description's "together with the vide
skill whenever Vide UI reads or writes Charm state" makes both halves necessary, so each negative
leaves out exactly one of Charm and Vide UI.
