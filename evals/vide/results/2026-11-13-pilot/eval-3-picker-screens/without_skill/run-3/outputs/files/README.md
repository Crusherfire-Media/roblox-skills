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

Client UI is built with Vide. Shared pieces live in `StarterPlayerScripts/UI`:

- `Screen` is the root for every screen. It wraps a ScreenGui that stays inside the safe area,
  survives respawns, and scales its contents with a UIScale.
- `Responsive` has reactive device state: `viewportSize`, `inputMode` (`"Touch"`, `"Gamepad"`,
  `"KeyboardMouse"`), `isTouch`, `isPortrait`, `isCompact`, `designSize`, `scale`, and
  `MIN_TOUCH_TARGET`.

Write sizes in design units (1 unit = 1 px at 1080p, or 1 pt on phones and tablets). Use
`Responsive` inside property functions when a layout needs to change shape, not just size, for
example moving out of the way of the touch thumbstick.

## Checks

Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:

```sh
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
luau-lsp analyze --platform=roblox --definitions:@roblox=globalTypes.d.luau --sourcemap=sourcemap.json --ignore=**/roblox_packages/** src
selene src
stylua --check src
```
