You are judging two attempts at the same task in a Roblox game project. The project is a Rojo
repo: Luau files under `src/` become scripts in the place, and Vide (a reactive UI library) is
installed as `ReplicatedStorage.Packages.Vide`. Each attempt started from the same files. You see
each attempt as a git diff of what it changed, plus the results of automatic checks (luau-lsp type
analysis, selene lint, StyLua formatting) on its changed Luau files.

The attempts are labeled A and B in random order. Judge only what is in front of you: don't guess
how either attempt was produced.

## Library facts

<library_facts>
These facts about the libraries in the project are verified against their source. Treat them as
true, and score code that relies on them as correct.

- **Vide 0.4.1 `create` defaults** (`vide/src/defaults.luau`, on while the `defaults` flag is true,
  which is its default): `create("ScreenGui")`, `create("BillboardGui")`, and
  `create("SurfaceGui")` get `ResetOnSpawn = false` and `ZIndexBehavior = Sibling`. Frames,
  buttons, labels, text boxes, and image objects get a white background and `BorderSizePixel = 0`.
  Text objects get `Font = SourceSans`, black text, and empty `Text`. Buttons get
  `AutoButtonColor = false`. List, grid, table, and page layouts get `SortOrder = LayoutOrder`.
  Parts get `Anchored = true`, `SmoothPlastic`, and size 1 x 1 x 1. Instances made with
  `Instance.new` get none of these.
- **Vide `mount(component, target)`** parents the component's result to `target` and returns a
  destroy function. Destroying it runs the scope's cleanups but leaves the mounted instance
  parented. A children binding (a function returning instances) unparents the instances it stops
  returning.
- **Vide `cleanup(value)`** registers a cleanup on the current scope: it disconnects connections,
  cancels threads, and calls `Destroy` on instances.
</library_facts>

## Task given to both attempts

<task>
I'm adding block placement to this place: players pick a block type (brick, dirt, grass, window, or wood) and click on the Baseplate to place it. Before I wire up the remote and the picker UI, I want the placement rules in one shared module at src/ReplicatedStorage/Shared/PlacementRules.luau, so the client can tint its ghost preview red on a bad spot and the server can reject bad requests with the same logic.

The rules:
- the block type has to be one of the five
- blocks are 4x4x4 and snap to a 4-stud grid that starts at the top of the Baseplate, so a block placed on the ground rests on it. Expose the snapping so the preview and the server agree
- nothing below the top of the Baseplate or more than 200 studs up
- within 24 studs of the player's HumanoidRootPart
- can't overlap a block that's already placed (placed blocks live in a folder the caller passes in). Blocks sitting right next to each other are fine
- the server will feed it whatever the client sends over the remote, so it has to cope with garbage (wrong types, NaN, huge numbers) without erroring

When a request fails, give back a short reason I can log on the server. Just the module for now, no remote or UI yet.
</task>

## Rubric

Score each criterion from 1 to 5 for each attempt (1 poor, 3 acceptable, 5 excellent):

1. Implements every rule correctly: the five block types, a 4-stud grid whose cells rest on the Baseplate top (Y = 0), the 0 to 200 stud height range, 24-stud reach from the HumanoidRootPart, no overlap with placed blocks while adjacent blocks are allowed, a short reason on failure, and the snapping exposed for the client.
2. Handles untrusted input without erroring: wrong types, NaN, and infinite numbers are rejected before any range check could let them through.
3. Comments explain why, not what: each comment carries something the code can't show (a constraint, a gotcha, the units or meaning of a literal, a sync obligation with other code, or why a tempting simpler version breaks), and none restates the next line, narrates steps, or repeats a name or type.
4. Comments are minimal: each one is as short as it can be while keeping its point, sits next to the line it governs, and there are no multi-line blocks that could be one line, no section banners inside functions or tables, no block-end markers such as 'end -- if', and no commented-out code.
5. Public functions carry a short doc comment that states what the signature can't show (what the return values mean, failure behavior, expectations on the inputs) without listing parameter names and types; private helpers and obvious lines carry none.
6. Comment text describes the code as it stands for a reader opening the file fresh: no change history, no references to the request or conversation (such as 'as requested' or 'new'), and no pointers to documents or specs that the reader can't see.
7. Stays in scope and is ready to merge: one shared module usable from client and server, no remote or UI, typed and readable Luau that passes the checks.

## Attempt A

<attempt_a_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] The module is at src/ReplicatedStorage/Shared/PlacementRules.luau
- [pass] Convention: no comment in a Luau file under src contains an em dash or a double hyphen used as a dash
- [pass] Convention: every Luau block comment under src puts --[[ and ]] on their own lines (the --[[@description: header line excepted)
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/ReplicatedStorage/Shared/PlacementRules.luau b/src/ReplicatedStorage/Shared/PlacementRules.luau
new file mode 100644
index 0000000..07466bc
--- /dev/null
+++ b/src/ReplicatedStorage/Shared/PlacementRules.luau
@@ -0,0 +1,166 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	Block placement rules shared by the client's ghost preview and the server's
+	request handler, so both accept and reject exactly the same spots.
+]]
+
+------------------------------
+-- TYPES --
+------------------------------
+export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"
+
+export type FailureReason =
+	"InvalidBlockType"
+	| "InvalidPosition"
+	| "BelowBaseplate"
+	| "TooHigh"
+	| "NoCharacter"
+	| "TooFar"
+	| "Occupied"
+
+export type PlacementResult =
+	{
+		Ok: true,
+		BlockType: BlockType,
+		Position: Vector3,
+	}
+	| {
+		Ok: false,
+		Reason: FailureReason,
+	}
+
+export type PlacementContext = {
+	Baseplate: BasePart,
+	BlocksFolder: Instance,
+	RootPart: BasePart?,
+}
+
+------------------------------
+-- VARIABLES --
+------------------------------
+const BLOCK_SIZE = 4
+const MAX_HEIGHT = 200
+const MAX_REACH = 24
+-- Shrinks the overlap query so blocks that only share a face don't count
+const OVERLAP_INSET = 0.1
+
+const BLOCK_TYPES = table.freeze({ "Brick", "Dirt", "Grass", "Window", "Wood" } :: { BlockType })
+
+local isBlockType: { [string]: boolean? } = {}
+for _, blockType in BLOCK_TYPES do
+	isBlockType[blockType] = true
+end
+
+local Module = {}
+
+Module.BlockSize = BLOCK_SIZE
+Module.BlockTypes = BLOCK_TYPES
+
+------------------------------
+-- PRIVATE FUNCTIONS --
+------------------------------
+
+local function isFiniteNumber(value: number): boolean
+	-- value == value rejects NaN, which passes every range check
+	return value == value and math.abs(value) ~= math.huge
+end
+
+local function getGridOrigin(baseplate: BasePart): Vector3
+	local halfSize = baseplate.Size / 2
+	return baseplate.Position + Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z)
+end
+
+local function snapAxis(value: number, origin: number): number
+	return origin + (math.floor((value - origin) / BLOCK_SIZE) + 0.5) * BLOCK_SIZE
+end
+
+local function isOccupied(center: Vector3, blocksFolder: Instance): boolean
+	local overlapParams = OverlapParams.new()
+	overlapParams.FilterType = Enum.RaycastFilterType.Include
+	overlapParams.FilterDescendantsInstances = { blocksFolder }
+	overlapParams.MaxParts = 1
+
+	local size = Vector3.one * (BLOCK_SIZE - OVERLAP_INSET)
+	return #workspace:GetPartBoundsInBox(CFrame.new(center), size, overlapParams) > 0
+end
+
+------------------------------
+-- PUBLIC FUNCTIONS --
+------------------------------
+
+--[[
+	Returns the center of the grid cell that contains `position`. The grid's
+	cells are BLOCK_SIZE studs wide and start at the top face of the
+	(unrotated) Baseplate, so a block in the bottom layer rests on it.
+
+	A point exactly on a cell boundary snaps to the cell above or beside it, so
+	for a raycast hit pass `hitPosition + hitNormal * (BlockSize / 2)` to land
+	in the cell next to the clicked face.
+]]
+function Module.snapToGrid(position: Vector3, baseplate: BasePart): Vector3
+	local origin = getGridOrigin(baseplate)
+	return Vector3.new(
+		snapAxis(position.X, origin.X),
+		snapAxis(position.Y, origin.Y),
+		snapAxis(position.Z, origin.Z)
+	)
+end
+
+--[[
+	Checks a placement request. `blockType` and `position` may be anything a
+	client sent over a remote; they are validated rather than trusted, and the
+	function never errors on them. `position` is snapped with snapToGrid
+	before the checks, and on success the result carries the snapped center.
+
+	A missing `context.RootPart` (no character, or a dead one) fails with
+	"NoCharacter".
+]]
+function Module.validate(
+	blockType: unknown,
+	position: unknown,
+	context: PlacementContext
+): PlacementResult
+	if typeof(blockType) ~= "string" or not isBlockType[blockType] then
+		return { Ok = false, Reason = "InvalidBlockType" }
+	end
+
+	if
+		typeof(position) ~= "Vector3"
+		or not isFiniteNumber(position.X)
+		or not isFiniteNumber(position.Y)
+		or not isFiniteNumber(position.Z)
+	then
+		return { Ok = false, Reason = "InvalidPosition" }
+	end
+
+	local center = Module.snapToGrid(position, context.Baseplate)
+	local groundY = getGridOrigin(context.Baseplate).Y
+	local halfBlock = BLOCK_SIZE / 2
+
+	if center.Y - halfBlock < groundY then
+		return { Ok = false, Reason = "BelowBaseplate" }
+	end
+
+	if center.Y + halfBlock > groundY + MAX_HEIGHT then
+		return { Ok = false, Reason = "TooHigh" }
+	end
+
+	local rootPart = context.RootPart
+	if not rootPart then
+		return { Ok = false, Reason = "NoCharacter" }
+	end
+
+	if (center - rootPart.Position).Magnitude > MAX_REACH then
+		return { Ok = false, Reason = "TooFar" }
+	end
+
+	if isOccupied(center, context.BlocksFolder) then
+		return { Ok = false, Reason = "Occupied" }
+	end
+
+	return { Ok = true, BlockType = blockType :: BlockType, Position = center }
+end
+
+return Module

</attempt_a_diff>

## Attempt B

<attempt_b_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] The module is at src/ReplicatedStorage/Shared/PlacementRules.luau
- [pass] Convention: no comment in a Luau file under src contains an em dash or a double hyphen used as a dash
- [pass] Convention: every Luau block comment under src puts --[[ and ]] on their own lines (the --[[@description: header line excepted)
</attempt_b_checks>

<attempt_b_diff>
diff --git a/src/ReplicatedStorage/Shared/PlacementRules.luau b/src/ReplicatedStorage/Shared/PlacementRules.luau
new file mode 100644
index 0000000..bf57f9e
--- /dev/null
+++ b/src/ReplicatedStorage/Shared/PlacementRules.luau
@@ -0,0 +1,156 @@
+--!strict
+-- Block placement rules shared by the client (ghost preview) and the server (request validation).
+-- Both sides must call the same functions so a spot the preview shows as valid is one the server
+-- accepts.
+
+local PlacementRules = {}
+
+export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"
+
+local blockTypes: { BlockType } = { "Brick", "Dirt", "Grass", "Window", "Wood" }
+PlacementRules.BLOCK_TYPES = table.freeze(blockTypes)
+
+-- Edge length of a block, and the grid spacing.
+PlacementRules.BLOCK_SIZE = 4
+-- Top surface of Workspace.Baseplate (see default.project.json). Hard-coded rather than read from
+-- the Baseplate so the client doesn't depend on that part having streamed in.
+PlacementRules.GROUND_Y = 0
+-- No part of a block may be higher than this many studs above the ground.
+PlacementRules.MAX_HEIGHT = 200
+-- Max distance from the HumanoidRootPart to the block's center.
+PlacementRules.MAX_REACH = 24
+
+local BLOCK_SIZE = PlacementRules.BLOCK_SIZE
+local HALF_BLOCK = BLOCK_SIZE / 2
+local GROUND_Y = PlacementRules.GROUND_Y
+local MAX_TOP_Y = GROUND_Y + PlacementRules.MAX_HEIGHT
+local MAX_REACH = PlacementRules.MAX_REACH
+
+-- Shapes closer than this along an axis count as touching, not overlapping, which absorbs float
+-- error on blocks whose faces share a plane.
+local OVERLAP_TOLERANCE = 0.01
+
+local blockTypeSet: { [string]: true } = {}
+for _, name in PlacementRules.BLOCK_TYPES do
+	blockTypeSet[name] = true
+end
+
+local function isFinite(n: number): boolean
+	-- NaN fails n == n; infinities fail the abs check.
+	return n == n and math.abs(n) ~= math.huge
+end
+
+local function isFiniteVector(v: Vector3): boolean
+	return isFinite(v.X) and isFinite(v.Y) and isFinite(v.Z)
+end
+
+local function snapAxis(value: number, origin: number): number
+	return math.floor((value - origin) / BLOCK_SIZE) * BLOCK_SIZE + origin + HALF_BLOCK
+end
+
+function PlacementRules.isBlockType(value: unknown): boolean
+	return type(value) == "string" and blockTypeSet[value] == true
+end
+
+-- Returns the center of the grid cell containing `position`. Cells are BLOCK_SIZE cubes whose
+-- bottoms sit at GROUND_Y + k * BLOCK_SIZE, so a block in the lowest layer rests on the Baseplate.
+--
+-- Pass the raycast hit normal when snapping a mouse hit: the point is pushed half a block out of the
+-- clicked surface first, so clicking any face of an existing block picks the cell next to that face
+-- instead of the block's own cell. Snapping a cell center again returns the same center, so the
+-- server can safely re-snap whatever the client sends.
+function PlacementRules.snap(position: Vector3, surfaceNormal: Vector3?): Vector3
+	if surfaceNormal then
+		position += surfaceNormal * HALF_BLOCK
+	end
+	return Vector3.new(
+		snapAxis(position.X, 0),
+		snapAxis(position.Y, GROUND_Y),
+		snapAxis(position.Z, 0)
+	)
+end
+
+-- World-space center and half-extents of the axis-aligned box around `instance`, or nil if it isn't
+-- a part or model.
+local function getBounds(instance: Instance): (Vector3?, Vector3?)
+	local cframe: CFrame, size: Vector3
+	if instance:IsA("BasePart") then
+		cframe, size = instance.CFrame, instance.Size
+	elseif instance:IsA("Model") then
+		cframe, size = instance:GetBoundingBox()
+	else
+		return nil, nil
+	end
+	-- Project the (possibly rotated) box onto the world axes.
+	local half = size / 2
+	local right, up, back = cframe.XVector, cframe.YVector, cframe.ZVector
+	local extents = Vector3.new(
+		math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(back.X) * half.Z,
+		math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(back.Y) * half.Z,
+		math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(back.Z) * half.Z
+	)
+	return cframe.Position, extents
+end
+
+local function overlapsPlacedBlock(center: Vector3, blocksFolder: Instance): boolean
+	local limit = HALF_BLOCK - OVERLAP_TOLERANCE
+	for _, child in blocksFolder:GetChildren() do
+		local otherCenter, otherHalf = getBounds(child)
+		if otherCenter and otherHalf then
+			local gap = (otherCenter - center):Abs()
+			if
+				gap.X < limit + otherHalf.X
+				and gap.Y < limit + otherHalf.Y
+				and gap.Z < limit + otherHalf.Z
+			then
+				return true
+			end
+		end
+	end
+	return false
+end
+
+-- Checks whether `player` may place `blockType` at `position`. Arguments other than `player` and
+-- `blocksFolder` can be anything a client sent over a remote; bad values are rejected, never
+-- errored on.
+--
+-- On success returns the snapped cell center to place the block at. On failure returns nil and a
+-- short reason for logging.
+function PlacementRules.check(
+	player: Player,
+	blockType: unknown,
+	position: unknown,
+	blocksFolder: Instance
+): (Vector3?, string?)
+	if not PlacementRules.isBlockType(blockType) then
+		return nil, "invalid block type"
+	end
+	if typeof(position) ~= "Vector3" or not isFiniteVector(position) then
+		return nil, "invalid position"
+	end
+
+	local center = PlacementRules.snap(position)
+	if center.Y - HALF_BLOCK < GROUND_Y then
+		return nil, "below ground"
+	end
+	if center.Y + HALF_BLOCK > MAX_TOP_Y then
+		return nil, "too high"
+	end
+
+	local character = player.Character
+	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
+	if not (rootPart and rootPart:IsA("BasePart")) then
+		return nil, "no character"
+	end
+	if (center - rootPart.Position).Magnitude > MAX_REACH then
+		return nil, "out of reach"
+	end
+
+	if overlapsPlacedBlock(center, blocksFolder) then
+		return nil, "overlaps a block"
+	end
+
+	return center, nil
+end
+
+return table.freeze(PlacementRules)

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
