# Block placement

- `ServerScriptService.BlockPlacement` owns the `PlaceBlock` remote and places the parts.
- `ServerScriptService.Placement.PlacementRules` decides whether a placement is allowed. Tune
  `MaxReach` and `MaxHeight` in its attributes.
- `ServerScriptService.ClearBlocks` adds the `/clearblocks` admin command.
- Specs: `ServerScriptService.Tests.Specs.Placement.PlacementRules.spec`.
