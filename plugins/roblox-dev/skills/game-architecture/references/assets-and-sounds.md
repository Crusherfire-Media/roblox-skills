# Assets and sounds

Where a system's assets live, and how a system keeps the sounds it plays cached.

## Assets

Assets that belong to a system (models and templates it clones, sounds, animations, UI
templates) live with that system, never in a shared assets folder, so a packaged system carries
everything it needs. Parent them under the system's `<Name>Types` module, which exports each one
with its type, so other modules reach an asset through the Types module instead of by path:

```lua
Module.DoorTemplate = script.DoorTemplate :: Model
```

A module's children relocate with it, and a Types module is shared, so its assets reach clients.
An asset that must stay on the server goes under one of the system's server-only modules instead.

## Sounds a system plays

A system that plays sounds keeps them cached for as long as it can play them, so each play
starts at once from the cache (why: `roblox-performance/references/rendering.md`, "Client
memory"). Hold them with a counted sound cache, such as the one in
`vide-performance/references/patterns.md` ("A counted sound cache"), whose hold returns its
release:

- in `Init` for sounds the system can play at any moment (its core loop, collecting, movement),
- or in the Trove of the context that plays them (a visit, a round, a nearby object), so the
  memory frees when it ends.

Holds are counted, so each owner takes its own and overlapping owners share one cached sound.
Sounds that UI plays follow the `vide-performance` skill.
