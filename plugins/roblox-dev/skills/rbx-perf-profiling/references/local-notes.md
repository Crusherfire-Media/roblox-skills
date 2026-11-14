# Notes from live sessions

Behavior observed while driving LibMP in live Studio sessions, beyond the rules in `SKILL.md`
and what the upstream docs say.

## Stepping scopes seen in practice

`ALL-SCOPES.md` describes both a fixed-rate `gameFixedStepped` with sub-steps per frame and a
per-frame `gameStepped`. The captures checked in one production place showed `gameStepped` only.
Separately, in that place `PreAnimation`, `PreSimulation`, and `PostSimulation` fired two to four
times per drawn frame in one playtest and once per frame in another
(`roblox-performance/references/physics.md`, "Moving things"). Count the events against
`PreRender` instead of trusting either description.

## Probing gotcha

`LibMP.Control` is a userdata-style object whose methods arrive through a metatable, so
`for k in pairs(LibMP.Control)` lists only a couple of internal fields. `EnableProfiler`,
`EnableCapture`, `SetFrameLimit`, and the capture methods are still there: call them, or check
`references/api-reference.md`. The `LibMP.Session` table enumerates its full static API normally.

## Version drift

`LibMP.Versions` reports the module's `DataFormat` and `Library` versions. If a method described
in `references/api-reference.md` is missing at runtime, the copy of LibMP in the place is older
than these docs. Tell the user and suggest updating it from the
[LibMP releases](https://github.com/Roblox/libmp/releases) before assuming a doc error.

## Refreshing

Run `./update.sh` in the skill folder (bash and curl) to re-download the upstream documents into
`references/` (`libmp-guide.md`, `api-reference.md`, `ALL-SCOPES.md`) along with
`LICENSE-libmp.txt`. It rewrites the guide's Studio MCP tool name into a plain description and
warns if a tool name is left. It never touches `SKILL.md`, which is maintained by hand: its
frontmatter copies the upstream guide's description (with the name changed to match the folder),
and its "Essentials from the upstream guide" section condenses that guide. The script reports
when the guide or its description changed, so `SKILL.md` can be reviewed against the new copy,
and warns if `SKILL.md` has grown past 18,000 bytes.
