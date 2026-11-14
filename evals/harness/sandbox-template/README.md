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

## Checks

Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:

```sh
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
luau-lsp analyze --platform=roblox --definitions:@roblox=globalTypes.d.luau --sourcemap=sourcemap.json --ignore=**/roblox_packages/** src
selene src
stylua --check src
```
