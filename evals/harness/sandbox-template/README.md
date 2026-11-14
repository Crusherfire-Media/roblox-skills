# Block game sandbox

A small Roblox game kept as files and synced into Studio with Rojo. The place is a Baseplate:
`Workspace.Baseplate` (a 2048 x 16 x 2048 anchored Part whose top is at Y = 0) and a
`SpawnLocation`.

## Layout

| Folder | Becomes |
|---|---|
| `src/ServerScriptService` | `ServerScriptService` |
| `src/ServerScriptService/Tests/Specs` | `ServerScriptService.Tests.Specs` (Jest specs and `jest.config`) |
| `src/ReplicatedStorage/Shared` | `ReplicatedStorage.Shared` (code for server and client) |
| `src/StarterPlayer/StarterPlayerScripts` | `StarterPlayer.StarterPlayerScripts` |
| `src/StarterGui` | `StarterGui` |
| `roblox_packages` (installed by pesde) | `ReplicatedStorage.Packages` |
| `test_packages/roblox_packages` (installed by pesde) | `ServerScriptService.Tests.Packages` |

`*.server.luau` files are Scripts, `*.client.luau` files are LocalScripts, and other `.luau` files
are ModuleScripts (`Foo.spec.luau` becomes the ModuleScript `Foo.spec`).

## Packages

pesde installs the packages in `pesde.toml`, and the Jest packages in `test_packages/pesde.toml`.
All of them come from Wally through pesde. Require each one through its link, never through a
`.pesde/...` path:

| Package | Version | Require |
|---|---|---|
| Vide (`centau/vide`) | 0.4.1 | `require(ReplicatedStorage.Packages.Vide)` |
| Charm (`littensy/charm`) | 0.11.1 | `require(ReplicatedStorage.Packages.Charm)` |
| vide-charm (`littensy/vide-charm`) | 0.4.1 | `require(ReplicatedStorage.Packages.VideCharm)` |
| CharmSync (`littensy/charm-sync`) | 0.4.1 | `require(ReplicatedStorage.Packages.CharmSync)` |
| UI Labs utilities (`pepeeltoro41/ui-labs`) | 2.4.2 | `require(ReplicatedStorage.Packages.UILabs)` |
| Module Loader (`crusherfire/module-loader`) | 4.0.1 | `require(ReplicatedStorage.Packages.ModuleLoader)` |
| Jest Roblox (`roblox/jest`) | 3.20.1 | `require(ServerScriptService.Tests.Packages.Jest)` |
| Jest globals (`roblox/jest-globals`) | 3.20.1 | `require(ServerScriptService.Tests.Packages.JestGlobals)` |

String requires work too, for example `require("@game/ReplicatedStorage/Packages/Vide")`.

## Tests

Jest specs live under `src/ServerScriptService/Tests/Specs`, beside `jest.config.luau`, whose
`testMatch` picks up every ModuleScript named `*.spec`. Specs run only in Studio, which this
project can't reach, so check specs with the commands below like any other file.

## Checks

Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:

```sh
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
luau-lsp analyze --platform=roblox --definitions:@roblox=globalTypes.d.luau --sourcemap=sourcemap.json --ignore=**/roblox_packages/** src
selene src
stylua --check src
```
