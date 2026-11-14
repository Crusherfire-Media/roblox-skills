# Architecture in a Rojo repo

In a Rojo repo the layout, categories, lifecycle, realms, and dependency direction in SKILL.md all
hold. What changes is that code is files, shared systems are pesde packages, and SystemPackages
reach outside themselves with string requires instead of attribute references. Each rule below
replaces the SKILL.md rule it names. The `rojo-workflow` skill covers how files map into the place,
how changes travel, and how Module Loader is installed through pesde.

## Where things live

- The two `Start` scripts are `src/ServerScriptService/Start.server.luau` and
  `src/StarterPlayer/StarterPlayerScripts/Start.client.luau`. Each requires Module Loader from
  where `default.project.json` mounts it (under ReplicatedStorage). `LOAD_MODULE` tags sit in the
  `Tags` property of a folder's `init.meta.json`; a `Packages` folder the loader handles gets its
  tag and attributes from `default.project.json`.
- A system is a directory, `src/ServerScriptService/Modules/Systems/<Category>/<Name>System/`,
  holding `SystemPackage/` and `Implementation/`. A module with children is a folder with an
  `init.luau`; its children are the folder's other files.
- **A shared system's SystemPackage is a pesde package**, installed into `roblox_packages` and
  required through its alias link. In the game repo that system's folder holds only
  `Implementation/`. Game-only systems keep both halves in the game repo. Moving a game system
  into a shared package repo follows the `rojo-workflow` skill's shared-packages reference.
- Library and data root folders keep their attributes in `init.meta.json`.

## Attributes and tints

Every attribute and folder tint goes in a `.meta.json` file (the `rojo-workflow` skill shows
one): Rojo replaces a Studio change on its next sync. Realm flags and `LoaderPriority` sit in
`<Module>.meta.json` beside the module, and a folder's attributes and tint in its
`init.meta.json`. `IconTint` is a property, written as a Color3's components from 0 to 1: red
`[1, 0, 0]` for `SystemPackage`, light blue `[0, 0.6666666865348816, 1]` for `Implementation`.

```json
{
  "properties": {
    "IconTint": [1, 0, 0]
  }
}
```

## Requires

This table replaces the one in SKILL.md's Requires section. `<Packages>` is the path of the folder
that mounts `roblox_packages` (read `default.project.json`).

| From | To | Write |
|---|---|---|
| Any module | its own child | `require("@self/_Child")` |
| Inside a system | a module in the same system | relative: `require("./DoorNetwork")`, `require("../SystemPackage/DoorSharedService")` |
| Any game module | a game system or game library | absolute: `require("@game/ServerScriptService/Modules/Systems/Gameplay/DoorSystem/SystemPackage/DoorSharedService")` |
| Any game module | a shared library | `require("@game/<Packages>/TableUtils")` |
| Any game module | a shared system's service | `require("@game/<Packages>/InventorySystem").InventoryService` |

- A game-only SystemPackage uses the absolute `@game/...` form for every outside dependency,
  where Studio mode uses an attribute reference, which Rojo can't carry.
- A shared system's index is its only entry point. Its services are fields of it, and it
  re-exports the shared types of its modules (`InventorySystem.ItemData`), so annotate with those
  instead of requiring a module for its types.
- Never require into `<Packages>/.pesde/...`: those paths name the installed version and change
  with every upgrade.
- A shared package reaches game code only through a slot, a game module at a fixed path that the
  package documents. Keep a slot module at its path with its shape.

The dependency rules are unchanged: direction, leaves, no cycles, injection for generic modules.
A shared package's settings for this game come from a setup module calling its registration API,
or the attributes the package documents, never from edits to the installed copy.

## Verifying

Verify as SKILL.md says, in the dev place through the Studio MCP, once Rojo has synced the files.
A loader failure on a module inside `Packages` is a package bug: fix it in the package's own repo,
never in the installed copy.
