# Block game sandbox

A small Roblox game kept as files and synced into Studio with Rojo. The place is a Baseplate:
`Workspace.Baseplate` (a 2048 x 16 x 2048 anchored Part whose top is at Y = 0) and a
`SpawnLocation`.

## Layout

| Folder | Becomes |
|---|---|
| `src/ServerScriptService` | `ServerScriptService` |
| `src/ReplicatedStorage/Shared` | `ReplicatedStorage.Shared` (code for server and client) |
| `src/StarterPlayer/StarterPlayerScripts` | `StarterPlayer.StarterPlayerScripts` |
| `src/StarterGui` | `StarterGui` |
| `roblox_packages` (installed by pesde) | `ReplicatedStorage.Packages` |

`*.server.luau` files are Scripts, `*.client.luau` files are LocalScripts, and other `.luau` files
are ModuleScripts.

## Packages

pesde installs packages from `pesde.toml`. Vide 0.4.1 is installed:
`require(ReplicatedStorage.Packages.Vide)`.

## UI

UI is built with Vide and authored once, in offsets, for a screen 1080 pixels tall.

- Build every screen inside `UI/screenGui` (in `StarterPlayerScripts`). It adds one `UIScale`
  that grows the UI on screens taller than 1080 (2x at 4K, 1.25x on a TV) and keeps the UI clear
  of Roblox's topbar buttons.
- Read the screen from `UI/Screen`, never the camera directly. Its getters (`isTouchLayout`,
  `isPhone`, `isTouch`, `usableSize`) are live, so bind to them and layouts follow resizes,
  rotation, and input changes during a session.
- Phones and tablets keep a scale of 1 and change layout instead. A reusable component takes its
  layout as a prop (see `BlockPicker`'s `Layout`), and the screen that mounts it passes one
  derived from `Screen`.
- Stories for UI Labs live in `ServerScriptService/Stories`.

## Checks

Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:

```sh
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
luau-lsp analyze --platform=roblox --definitions:@roblox=globalTypes.d.luau --sourcemap=sourcemap.json --ignore=**/roblox_packages/** src
selene src
stylua --check src
```
