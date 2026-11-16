I added the block catalog at `src/ReplicatedStorage/Shared/BlockCatalog.luau`. It's in ReplicatedStorage, so both server and client code can `require` it.

- It exports a `BlockType` type with `Name`, `Color`, `Material` and `Transparency`.
- The five blocks are listed by name: `BlockCatalog.Brick`, `BlockCatalog.Window`, and so on. The catalog and each block entry are frozen, so other code can't change them by accident.
- The values come from the project's block color reference:

| Block | Color (RGB) | Material | Transparency |
|---|---|---|---|
| Brick | 151, 0, 0 | Brick | 0 |
| Dirt | 110, 80, 50 | Ground | 0 |
| Grass | 75, 151, 75 | Grass | 0 |
| Window | 200, 230, 255 | Glass | 0.5 |
| Wood | 160, 110, 60 | WoodPlanks | 0 |

The file passes the formatter check (stylua) and the linter (selene, no warnings). Nothing uses it yet, so I haven't run it in Studio. I haven't committed it.