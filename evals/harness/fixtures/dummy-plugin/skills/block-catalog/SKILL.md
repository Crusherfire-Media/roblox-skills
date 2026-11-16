---
name: block-catalog
description: House rules for the block placement game's block type catalog. Load it before creating or editing the module that lists block types (brick, dirt, grass, window, wood).
---

# Block catalog rules

- The catalog is one ModuleScript at `src/ReplicatedStorage/Shared/BlockCatalog.luau`.
- Export a `BlockType` type with `Name: string`, `Color: Color3`, `Material: Enum.Material`, and
  `Transparency: number`.
- Return a table keyed by block name, frozen with `table.freeze`.
- Set `Transparency` to 0 for every block except Window, which uses 0.5 and `Enum.Material.Glass`.
- Take each block's color and material from `references/colors.md` (next to this file). Read it
  before writing the catalog.
