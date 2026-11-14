# The map

For projects whose world comes from snapshot files: builders edit the map in a separate **Build
place** that Rojo never syncs into, and files such as `map/Map.rbxm` and `map/Environment.rbxm`
(often in Git LFS) are snapshots of it, mounted onto `Workspace.Map` and `Workspace.Environment`.
Rojo syncs them into each dev place, and `syncbackRules` keeps syncback from writing them, so the
map changes in Git only through a map pull. The repo's `CLAUDE.md` or README names the Build
place.

## Pulling the map

Do this when a branch needs the builders' latest work. Both the Build place and the dev place are
open in Studio, and `rojo serve` is running.

1. **Clean the Build place's copy.** Run Luau in the Build place's edit session (target that place
   explicitly when several are connected) to list what an export can't carry: instance-reference
   attributes, and reference properties (`ObjectValue.Value` and similar) pointing at instances
   outside the exported folder. Remove or convert them there (see No references inside the map),
   with a script that changes nothing on a second run.
2. **Export** each folder the project maps to `map/` (for example `Workspace.Map` and
   `Workspace.Environment`) from the Build place, each to its own `.rbxm` in a scratch folder:
   Studio's **Save to File**, or the MCP's export-a-model action. Export each map the game loads
   at runtime too (see below).
3. **Check the difference.** Git can't diff an `.rbxm`. Compare the old and new snapshots before
   copying: a repo tool that reads both files (a Lune script with `@lune/roblox`, say), or a
   summary from Luau in Studio (instance counts per class, the names under each top-level folder).
   What moved, appeared, or disappeared should be what the builders did. Check a surprising change
   in the Build place before reporting it. To compare against an older committed map in LFS, get
   the real file (`git show <rev>:map/Map.rbxm | git lfs smudge > <scratch>/old.rbxm`); `git show`
   alone gives the pointer.
4. **Copy** the exported files over `map/`. Rojo syncs them into the dev place.
5. **Commit** the map on its own ("Update the map from the Build place"), with no code in the
   commit.

Done when the commit holds only `map/` and the comparison listed only the builders' changes.

## Branches

Git can't merge two versions of an `.rbxm`. Land map pulls on `main` in small pull requests of
their own, and merge `main` into a branch that needs the map. When two branches pulled the map
anyway, take either side in the conflict and pull again: the Build place is always the source.

## Code that needs a new map piece

A tagged part, a spawner, an attribute a system reads: the builder adds it in the Build place, then
the developer pulls. When the code can't run without the pulled map, or the map without the code,
both go in one pull request, the map still in its own commit. A model a system clones at runtime
belongs to that system's assets in `src/`, outside the map.

## Maps the game loads at runtime

Round maps and levels are the exception: builders edit them, so each is its own map file, mounted
where the game keeps it, such as `ServerStorage.Maps.<Name>`. Make each a Model and have code
pivot it onto one tagged marker part where maps play, so moving the marker moves every map. Their
spot in the Build place then doesn't matter: keep them apart there, and pivot one onto the marker
to see it in place. Add a spec that checks every map is a Model and exactly one marker exists.

Exports come only from the Build place. A place Rojo syncs into collects engine artifacts and
synced-in state, and its map is a copy of `map/` anyway.

## No references inside the map

When a map file changes, live sync replaces its instances in the dev place, and an `ObjectValue`
or other reference property pointing at a replaced instance can come out empty or point at the old
copy. `rojo build` keeps references only within one map file. Code reading such a link can work in
builds and fail only in dev places, which looks like a code bug. Give the target an id attribute or
a tag and look it up in code instead, and convert set reference properties in step 1 of the pull.

## What the map holds

An instance in the map carries placement facts: its id, its layout, links to other instances by
id, and what differs between copies. Tuning values and player-facing text (prices, rewards,
display names, multipliers) go in a catalog in code, keyed by an id attribute on the instance, so
a balance change is a code change that review and CI see. Moving existing map data into a
catalog:

1. Generate the catalog from the Build place so nothing is retyped, and compare it field by field
   with the authored values before anything is removed.
2. In the Build place, set the id attribute where it is missing (the instance's name by default;
   keep an id a builder set) and remove the data the catalog now holds. Check every instance
   before changing any; when an instance carries data the catalog lacks, change nothing and list
   the values to add. A second run changes nothing.
3. When saves store instance names, make each id equal the old name and have code find instances
   by id, so a rename in the Build place can't orphan saved data.
4. To keep the change small, code may rebuild the old structure from the catalog at startup, so
   existing readers keep working; move readers onto the catalog later, one at a time.
5. Add a spec that checks the map against the catalog (the `roblox-testing` skill's Rojo
   reference, "Specs that read the map"). When CI builds with the map, it runs on every pull
   request.

## PackageLinks and Lighting

**PackageLinks in the map** never reach a dev place: a plugin can't create them. Rojo warns about
each one when the map file changes ("Could not reparent child PackageLink", "Instance ... not found
in InstanceMap during sync replacement"), and the warnings are harmless. With Git as the map's
source, a PackageLink only lets a package update change the Build place outside a map pull, so
remove them there unless the project still updates map models through Roblox packages.

**Lighting** goes the other way: the repo owns it (`src/Lighting` and Lighting's properties in
`default.project.json`), and Rojo syncs it into dev places. Start a lighting change in the repo,
and bring the Build place up to date from a fresh build afterward.
