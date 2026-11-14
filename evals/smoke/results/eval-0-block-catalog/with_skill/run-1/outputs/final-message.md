I've added the block catalog at `src/ReplicatedStorage/Shared/BlockCatalog.luau`. I haven't type-checked or run it: the command to look for Luau tooling was blocked because it needed approval and nobody could approve it in this session.

`default.project.json` maps that folder to `ReplicatedStorage.Shared`, so both server and client can load it with `require(ReplicatedStorage.Shared.BlockCatalog)`.

| Block  | Color (RGB)   | Material   | Transparency |
|--------|---------------|------------|--------------|
| Brick  | 151, 0, 0     | Brick      | 0            |
| Dirt   | 110, 80, 50   | Ground     | 0            |
| Grass  | 75, 151, 75   | Grass      | 0            |
| Window | 200, 230, 255 | Glass      | 0.5          |
| Wood   | 160, 110, 60  | WoodPlanks | 0            |

- **Source of values:** the colors and materials come from the project's `block-catalog` house rules and its color reference.
- **Lookup:** the module returns a table you look up by block name (e.g. `BlockCatalog.Brick`).
- **Type:** it exports a `BlockType` type with `Name`, `Color`, `Material` and `Transparency` fields.
- **Read-only:** the catalog and every entry are frozen, so nothing on either server or client can change them at runtime.

To check it, open the file in Studio or run `luau-lsp`/`selene` if you have them.