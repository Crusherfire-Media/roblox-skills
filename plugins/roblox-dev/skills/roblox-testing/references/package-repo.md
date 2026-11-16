# Specs in a shared package repo

A shared package's own behavior is specced in the repo that holds the package (a pesde workspace,
as the `rojo-workflow` skill's shared-packages reference lays out), outside every game repo. The
behaviors, seams, loop, and spec style in SKILL.md all hold, and specs run in a Studio place
through the Studio MCP. What changes is where they live and the place they run in. When the repo
has a `tests/README.md`, it is the source of truth for its layout, test place, and fakes; read it
before the first spec there.

## Where specs live

- A spec for `packages/<name>/src/<path>/<Module>` is `tests/Specs/<name>/<path>/<Module>.spec.luau`,
  outside `packages/<name>/`. A game installs a package by that folder, so specs kept outside it
  never ship with an installed package.
- A game repo keeps only its game-specific specs: its catalogs, its save schema, the setups and
  mediators that configure or wire a package, and gameplay journeys. A spec of a package's own
  rule found in a game moves here.
- A test project file (for example `test.project.json`) mounts the Jest packages, the specs, and
  the packages under test at the same paths a game uses, so specs require them the way a game's
  specs do (the Rojo reference's Packages in specs section).
- The package under test and the libraries it depends on run for real. A package it depends on
  that reaches saved data, purchases, or the network is the boundary: `jest.mock` its module with
  one of the repo's shared fakes, and reuse one before writing another.

## A package's first spec

1. Add the package to the root `pesde.toml`'s `[dev_dependencies]`, keyed by its alias:
   `<Alias> = { workspace = "<scope>/<name>", version = "^" }`.
2. Run `pesde install` from the repo root.
3. Commit `pesde.toml` and the updated `pesde.lock`.

## Running

1. Run `pesde install` after any change to the packages the specs use.
2. `rojo serve test.project.json` into an empty place (a new Baseplate, never a game's place),
   connect, and run the specs the change reaches there, filtered by path such as `Specs/<name>/`
   ([running-in-studio.md](running-in-studio.md)).
3. When the repo has CI, it runs the whole suite on every pull request on a server
   ([ci.md](ci.md)), and that is the only whole-suite run: a spec that depends on edit mode passes
   in Studio and fails there.
