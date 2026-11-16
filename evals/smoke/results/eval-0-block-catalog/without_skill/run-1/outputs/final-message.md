I added the block type catalog as one shared module at `src/ReplicatedStorage/Shared/BlockTypes.luau`. Server and client code load it with `require(ReplicatedStorage.Shared.BlockTypes)`. The type check, lint and format checks all pass. I haven't run it in Studio.

| Block | Color (RGB) | Material | Transparency |
|---|---|---|---|
| Brick | 163, 75, 60 | `Brick` | 0 |
| Dirt | 120, 85, 55 | `Ground` | 0 |
| Grass | 85, 145, 60 | `Grass` | 0 |
| Window | 170, 215, 240 | `Glass` | 0.5 |
| Wood | 160, 115, 70 | `WoodPlanks` | 0 |

What the module gives you:
- **`BlockTypes.list`**: the five blocks in a fixed order, so the UI can show them in that order later.
- **`BlockTypes.byId`**: a lookup table from a block's name (like `"Brick"`) to its entry.
- **`BlockTypes.get(id)`**: safe to call with anything a client sends. It returns `nil` for anything that isn't a known block name, so the placement system can check requests with it.
- **`BlockTypes.isValidId(id)`**: a yes/no version of the same check.
- **Exported types** (`BlockTypeId`, `BlockType`): the editor catches a misspelled block name.
- **Read-only**: every table is locked, so neither the server nor the client can change the catalog while the game runs.

I picked the colors and the Window transparency myself, so change them if you have other values in mind. Each block also has a `displayName` field for the UI.

I haven't committed anything.