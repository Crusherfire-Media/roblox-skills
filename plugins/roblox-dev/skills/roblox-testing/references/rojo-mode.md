# Specs in a Rojo repo

In a Rojo repo the behaviors, seams, loop, and spec style in SKILL.md all hold, and specs still
run in the dev place through the Studio MCP. What changes is that specs are files, shared code is
installed by pesde, and CI runs the whole suite. The `rojo-workflow` skill covers how files map
into the place.

## Spec files

- The `Tests` tree is `src/ServerScriptService/Tests/`: `Specs/jest.config.luau`, specs mirroring
  the Modules tree, and any helpers. A spec for `Modules/<path>/<Name>` is the file
  `Specs/<path>/<Name>.spec.luau`, which becomes the ModuleScript `<Name>.spec`.
- Jest Roblox comes from Wally (`roblox/jest` and `roblox/jest-globals`, one pinned version). Read
  `default.project.json` and `pesde.toml` for how this repo provides it: committed under
  `Tests/Packages/` (built as [setup.md](setup.md) describes), or installed through pesde's Wally
  support and mounted at `ServerScriptService.Tests.Packages`. Keep it out of any folder the Module
  Loader loads or relocates.
- The game's specs cover what the game owns: its catalogs, its save schema, the setups and
  mediators that configure or wire a package, and gameplay journeys. A shared package's own
  behavior is specced in its package repo ([package-repo.md](package-repo.md)). When a module moves
  from the game into a package, its specs move there in the same change and leave the game. A spec
  of a game module that wraps a package covers only what the wrapper adds.

## Packages in specs

- Require a package the way game code does, through the link pesde writes for its alias
  (`require("@game/<Packages folder path>/<Alias>")`), and a system's service as a field of its
  index. This replaces SKILL.md's "anything with a `PackageLink` ancestor": an installed package is
  anything under the `Packages` folder that mounts `roblox_packages`.
- Never write a `.pesde/...` path into a spec: pesde puts every package under a folder named after
  its version, so that path changes with every upgrade.
- To `jest.mock` a package, mock its link ModuleScript (`<Packages folder>.<Alias>`), which is what
  game code requires.
- A package is a boundary for a game spec: fake it through its registration or injection API, as
  for any boundary, and assert the game's side (what the setup registers, or what the game does
  with the package's answer). A spec never edits an installed package.
- If a spec fails to load with an error about a `..` path inside `roblox_packages`, Jest's
  sandboxed require rejected one of pesde's dependency links (`require("./../../...")`). Report it
  to the user: the project needs an install step that rewrites those links without the leading
  `./`.

## Running

1. Save the spec and the code under test, and confirm Rojo synced them, as the `rojo-workflow`
   skill's Changing code steps say.
2. Run the spec in progress, then the affected specs, in the dev place
   ([running-in-studio.md](running-in-studio.md)). The whole suite runs in CI on every pull
   request, on a server ([ci.md](ci.md)), and that run is the only whole-suite run: when it
   reports a failure, rerun that spec file in Studio by its path.
3. A new spec file reaches the place only through Rojo, so a load error saying a module is missing
   usually means the sync hasn't happened yet or `rojo serve` stopped.

## Specs that read the map

When CI tests a build that includes the map (the `rojo-workflow` skill's map reference), a spec may
read `workspace` the way a catalog spec reads its catalog: never changing it, and collecting
offenders. Pair each catalog keyed by map ids with a spec that checks the two against each other
(ids present, unique, resolvable). When saves store those ids and the project keeps save fixtures,
add a test that every fixture id is still in the catalog, so a renamed or removed id fails CI
instead of orphaning saved progress.
