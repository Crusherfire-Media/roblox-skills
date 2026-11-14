I added the catalog in `src/ReplicatedStorage/Shared/BlockTypes.luau`, so the server and client can both load it as `require(ReplicatedStorage.Shared.BlockTypes)`. The type checker, linter and formatter all pass. I haven't run it in Studio yet.

| Block | Color (RGB) | Material | Transparency |
|---|---|---|---|
| Brick | 151, 61, 46 | `Brick` | 0 |
| Dirt | 110, 78, 52 | `Ground` | 0 |
| Grass | 76, 145, 64 | `Grass` | 0 |
| Window | 175, 215, 235 | `Glass` | 0.5 |
| Wood | 160, 112, 70 | `WoodPlanks` | 0 |

The colors and the window's 0.5 transparency are my picks, so change them to whatever you want. Dirt uses `Ground` because Roblox has no Dirt material for parts.

The module gives you three ways to read it:
- **`list`:** the five blocks in a fixed order, for the build UI later.
- **`byId`:** look up a block by its id (e.g. `byId.Wood`).
- **`get(id)`:** returns the block, or `nil` if the id isn't one of the five. The server can use this to check block ids sent by players before it places anything.

Each block also has an `id` and a `displayName` that the UI can show. All the tables are locked so nothing can change the catalog while the game runs.

I haven't committed anything.