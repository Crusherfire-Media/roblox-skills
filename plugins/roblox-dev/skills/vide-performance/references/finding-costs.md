# Finding the cost

The steps for finding a Vide UI cost, the probes for each row of the table in `SKILL.md`, and the
traps that faked results. The general
method (fair comparisons, budgets, which tool for which question, reading a MicroProfiler dump
from a live client) is in `roblox-performance/references/measuring.md`; this file adds what Vide
UI needs on top. Run client probes as Luau on the playtest's client, so they see the game's own
module copies. Drive the UI with real mouse clicks on the viewport so the click path is in the
number. Each probe below assumes these two lines at the top of the chunk:

```lua
const RunService = game:GetService("RunService")
const playerGui = game:GetService("Players").LocalPlayer.PlayerGui
```

## Steps

1. **Take the numbers players get:** with Vide's strict mode off for the run (the strict mode
   trap under Traps below), or from a published client's MicroProfiler dump (reading one is in
   `roblox-performance/references/measuring.md`).
2. **Name the frame.** For a spike, count instances added in that frame and profile only that
   action. For a slow stretch, probe layout and look for per-frame work. The probes are below.
3. **Change one thing, then measure the same workload,** as `roblox-dev:roblox-performance` sets out.
4. **Check that the look did not change.** Sample positions or counts frame by frame where a
   kept or reused view could differ from a new one, run the story check from `roblox-dev:vide-ui-labs`, and
   list for the user exactly what to check on screen.

## Frame times beside instances added

A creation spike shows here before any profile names it. Each row is one drawn frame; only rows
over the threshold or with more than 20 instances added or removed are kept.

```lua
local function frameLog(seconds: number, thresholdMs: number): string
	local added, removed = 0, 0
	local rows = {}
	local started = os.clock()
	local onAdd = playerGui.DescendantAdded:Connect(function()
		added += 1
	end)
	local onRemove = playerGui.DescendantRemoving:Connect(function()
		removed += 1
	end)
	local onFrame = RunService.PreRender:Connect(function(deltaTime)
		local ms = deltaTime * 1000
		if ms >= thresholdMs or added > 20 or removed > 20 then
			table.insert(rows, string.format("%.2fs %dms +%d -%d", os.clock() - started, ms, added, removed))
		end
		added, removed = 0, 0
	end)
	task.wait(seconds)
	onAdd:Disconnect()
	onRemove:Disconnect()
	onFrame:Disconnect()
	return table.concat(rows, "\n")
end
```

## Which UI the instances belong to

Group what was added in each frame by its path a few levels under PlayerGui. This named a
recipe picker (471 instances), four leaderboards (2,700), and two shop tab pages (710 and 836)
in one pass.

```lua
local function census(seconds: number, depth: number): string
	local frame = 0
	local perFrame: { [number]: { [string]: number } } = {}
	local onAdd = playerGui.DescendantAdded:Connect(function(instance)
		local chain = {}
		local node = instance
		while node and node ~= playerGui do
			table.insert(chain, 1, node.Name)
			node = node.Parent
		end
		local key = table.concat(chain, "/", 1, math.min(depth, #chain))
		perFrame[frame] = perFrame[frame] or {}
		perFrame[frame][key] = (perFrame[frame][key] or 0) + 1
	end)
	local onFrame = RunService.PreRender:Connect(function()
		frame += 1
	end)
	task.wait(seconds)
	onAdd:Disconnect()
	onFrame:Disconnect()

	local lines = {}
	for index, groups in perFrame do
		local parts = {}
		for key, count in groups do
			table.insert(parts, `{key}={count}`)
		end
		table.insert(lines, `frame {index}: {table.concat(parts, ", ")}`)
	end
	return table.concat(lines, "\n")
end
```

Reparenting a kept subtree fires `DescendantAdded` for every descendant, so a census row is not
proof of a build. Check that the instances are new before calling it a rebuild.

## Text that changes every frame

```lua
local function textChanges(root: Instance, seconds: number): string
	local counts: { [string]: number } = {}
	local connections = {}
	for _, label in root:GetDescendants() do
		if label:IsA("TextLabel") or label:IsA("TextButton") then
			table.insert(connections, label:GetPropertyChangedSignal("Text"):Connect(function()
				local key = label:GetFullName()
				counts[key] = (counts[key] or 0) + 1
			end))
		end
	end
	local frames = 0
	local onFrame = RunService.PreRender:Connect(function()
		frames += 1
	end)
	task.wait(seconds)
	onFrame:Disconnect()
	for _, connection in connections do
		connection:Disconnect()
	end
	local lines = { `{frames} frames` }
	for key, count in counts do
		table.insert(lines, `{count} {key}`)
	end
	return table.concat(lines, "\n")
end
```

`Changed` fires only on a real change, so a label written with the same text does not count.
Profile the action and sum `TextLabel.Text` by its callers (below) to see which binding writes it.

## The script behind one action

A profiler capture that blocks for its whole duration leaves the action outside it, since
nothing else runs until it returns. Start and stop `ScriptProfilerService` by hand around the
action, from Luau run on the playtest's server, and summarize on the server so the profile JSON
never has to come back to you whole. Use a key in `shared` that no other agent will pick, and
clear it when done.

```lua
-- Start (Luau run on the playtest's server):
const ScriptProfilerService = game:GetService("ScriptProfilerService")
local player = game:GetService("Players"):GetPlayers()[1]
shared.VidePerfProfile = shared.VidePerfProfile or {}
local state = shared.VidePerfProfile
state.Data = nil
state.Connection = state.Connection or ScriptProfilerService.OnNewData:Connect(function(_, json)
	state.Data = json
end)
ScriptProfilerService:ClientStart(player, 10000)

-- Stop, after the action:
ScriptProfilerService:ClientStop(player)
ScriptProfilerService:ClientRequestData(player)
-- then wait until state.Data is set, JSONDecode it, summarize, and finally:
-- state.Connection:Disconnect(); shared.VidePerfProfile = nil
```

The decoded profile has `Categories` (top nodes such as `Heartbeat`, `deferredThreads`, or
`AbsoluteSizeChanged`), `Nodes` with `TotalDuration` in microseconds plus `FunctionIds` and
`NodeIds` for their children, and `Functions` with `Source`, `Name`, and `Line`. Two summaries
answer most questions:

- **Focus:** find every node whose function label contains a name (`mountPicker`, `ticketButton`)
  and print its subtree a few levels deep, merged across call stacks. That showed a picker mount
  at 22 of a 29 ms open, with its tickets at 15.
- **Callers:** for an engine call (`TextLabel.Text`, `GuiBase2d.AbsoluteSize`), sum its time by
  the nearest game functions above it on the stack. That showed one clock source behind 127 ms
  of text writes, and size listeners behind 4.4 ms a frame of forced layout.

A long window dilutes one spike frame. Start the profiler a second before the action and stop it
a second or two after.

## Layout cost of a panel

Change the panel's `UIScale`, then time the first `AbsoluteSize` read after it: that read runs
the pending layout. Read every row too, so subtrees laid out on demand are counted.

```lua
local function layoutCost(scale: UIScale, rows: { GuiObject }): number
	local original = scale.Scale
	local total = 0
	for round = 1, 4 do
		scale.Scale = original * (if round % 2 == 0 then 0.99 else 0.995)
		local started = os.clock()
		for _, row in rows do
			local _ = row.AbsoluteSize
		end
		total += os.clock() - started
	end
	scale.Scale = original
	return total / 4 * 1000
end
```

Run it as the panel is, with suspect children hidden, and with them unparented, and put
everything back afterward. A scale that alternates between two values each frame for 60 frames,
against 60 untouched frames, gives the per-frame cost of a scale animation the same way. If Vide
binds that `UIScale`, its next rerun overwrites the probe's value, so probe while it is at rest.

## CanvasGroups that exist and that are drawn

```lua
local function isDrawn(instance: GuiObject): boolean
	local node: Instance? = instance
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return node ~= nil and (not node:IsA("ScreenGui") or (node :: ScreenGui).Enabled)
end

local function countCanvasGroups(): (number, number)
	local total, drawn = 0, 0
	for _, instance in playerGui:GetDescendants() do
		if not instance:IsA("CanvasGroup") then
			continue
		end
		total += 1
		if isDrawn(instance) then
			drawn += 1
		end
	end
	return total, drawn
end
```

The climb passes through `Folder`s, which hold rows taken out of the tree. Count at spawn, with
each panel open, and with every panel closed again, and group by name and ScreenGui to find the
owners.

## Sounds that load when cued

Read `IsLoaded` on the Sound a cue plays at the moment it starts. `false` means nothing kept it
cached and it waited on its asset. Then read the cache for one screen's sounds with the screen
open and closed, and once away from it: cached while open, released after.

```lua
-- <isCached> is the project's cache lookup (a counted cache's held-or-not check).
local function cacheState(soundIds: { string }, isCached: (soundId: string) -> boolean): string
	local lines = {}
	for _, soundId in soundIds do
		table.insert(lines, `{soundId} {if isCached(soundId) then "cached" else "released"}`)
	end
	return table.concat(lines, "\n")
end
```

A sound that reads cached away from its screen may be held by another screen, or share its sound
file with one: compare `SoundId`s before calling it a leak.

## Vide in a MicroProfiler dump

Vide's own work shows as `VIDE STEP` and `VIDE SPRING` under the script that required Vide. The
rest of a UI spike reads with the engine labels in `roblox-performance/references/measuring.md`.

## Traps

- **Strict mode.** Vide's strict mode runs every effect and derive twice. Time with it off: set
  `strict = false` on the game's own Vide module, from Luau run on the client, before the run,
  and set it back to its earlier value afterward.
- **Heartbeats per drawn frame.** `Heartbeat` can fire several times per drawn frame
  (`roblox-performance/references/physics.md`, "Moving things"), so per-Heartbeat work can count
  several times a frame. Record Heartbeats beside frames.
- **The baseline moves with the camera.** The same machine drew 8 ms frames at one spot and 20 ms
  at another. Compare runs taken at the same spot only (`roblox-performance/references/measuring.md`,
  "A fair comparison").
- **Your own listeners cost time.** A `DescendantAdded` listener adds a Lua call per instance,
  so leave it off when the number you want is the frame time of a large reparent.
- **Profiler start and stop each cost a long frame.** Keep them out of the window being judged.
- **Other sessions share the window.** Another agent's spec run freezes a playtest for seconds,
  and a playtest may be someone else's: check before trusting a run, and do not stop a playtest
  you did not start.
- **Studio cannot load other players' data.** To measure a view built from another player's
  data, temporarily replace the client-side fetch in the playtest's VM with one that returns a
  filled-in copy of your own, and put it back afterward.
- **Something invisible can take the clicks.** Before a probe clicks through UI, check that no
  invisible element, such as a closed panel's leftover hit area, sits over the target.
