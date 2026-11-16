I've fixed the mappings in `default.project.json` and written the guide, but **one fix is still needed: the file starts with a byte order mark (BOM), and I couldn't remove it.** Rojo can't parse a project file that starts with one, so `rojo sourcemap` will keep failing until it's stripped. I also couldn't run `rojo` to check the result, because commands needing approval were blocked here.

## What the merge broke

Compared with the commit before the merge, the conflict resolution did four things wrong:

1. **Jest packages in the wrong place.** `test_packages/roblox_packages` was mounted as `ReplicatedStorage.TestPackages` instead of `ServerScriptService.Tests.Packages`. That's why teammates say Jest can't find its packages.
2. **The `globIgnorePaths` entry for `src/ServerScriptService/Tests` was dropped.** Without it, the `ServerScriptService` mount adds a second `Tests` folder alongside the explicit one.
3. **A typo in a path.** `src/StarterPlayer/StarterPlayerScript` (missing the `s`) points at a folder that doesn't exist.
4. **A BOM was added** at the start of the file. This is what makes `rojo sourcemap` fail.

The file is now the pre-merge version plus `"servePort": 34872`, which the other side of the merge added. That setting does no harm and the guide refers to it. `git diff HEAD~1 -- default.project.json` confirms the mappings and the extra line are the only content differences, and they match every row of the README's Layout table.

## To finish

In Git Bash, from the repo root:
```sh
sed -i '1s/^\xEF\xBB\xBF//' default.project.json
od -An -tx1 -N3 default.project.json   # should no longer print "ef bb bf"
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
```
Then check that `sourcemap.json` shows `ServerScriptService` > `Tests` > `Specs` and `Packages`, and run the specs once in a dev place.

## The guide

`docs/rojo-workflow.md` covers:
- **Setup:** installing the tools and packages, and creating your own dev place.
- **Daily routine** and a table of which folder each kind of change goes in.
- **What to check while `rojo serve` runs:**
  - your edit actually reached Studio
  - the server is still running after you delete, move or rename files (Rojo 7.7.0/7.7.1 can crash on these)
  - stop it before checkouts, pulls and installs
- **Keeping the project file safe:**
  - update it and the README table together
  - keep `globIgnorePaths`
  - keep every mount from both sides when resolving a conflict
  - save it without a BOM
  - run `rojo sourcemap` before pushing

Nothing is committed.