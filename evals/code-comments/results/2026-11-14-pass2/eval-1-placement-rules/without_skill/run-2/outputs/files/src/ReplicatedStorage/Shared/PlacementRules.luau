--[[
	Block placement rules shared by the client (ghost preview tint) and the server (request
	validation). Everything here must give the same answer on both sides, so the server can
	reject exactly the spots the client paints red.

	Grid: blocks are BLOCK_SIZE cubes in cells of BLOCK_SIZE studs. Cells start at
	GROUND_Y (the top of the Baseplate) on Y, and at multiples of BLOCK_SIZE on X/Z, so a cell's
	center is always at (4k + 2) on every axis and a block in the lowest layer rests on the
	Baseplate.
]]

local Workspace = game:GetService("Workspace")

local PlacementRules = {}

PlacementRules.BLOCK_SIZE = 4
-- Top of Workspace.Baseplate (Size.Y 16 at Position.Y -8, see default.project.json). Kept as a
-- constant rather than read from the part so requiring this module never depends on the
-- Baseplate having replicated yet.
PlacementRules.GROUND_Y = 0
-- Highest allowed point of a block, measured from GROUND_Y.
PlacementRules.MAX_HEIGHT = 200
-- Max distance from the player's HumanoidRootPart to the center of the placed block.
PlacementRules.MAX_REACH = 24

PlacementRules.BLOCK_TYPES = table.freeze({ "brick", "dirt", "grass", "window", "wood" })

local VALID_BLOCK_TYPES: { [string]: true } = {}
for _, blockType in PlacementRules.BLOCK_TYPES do
	VALID_BLOCK_TYPES[blockType] = true
end

local BLOCK_SIZE = PlacementRules.BLOCK_SIZE
local HALF = BLOCK_SIZE / 2
-- Overlap query box is shrunk slightly so a neighbour whose face exactly touches ours doesn't
-- count as overlapping.
local OVERLAP_BOX_SIZE = Vector3.one * (BLOCK_SIZE - 0.2)

local function isFiniteNumber(n: number): boolean
	-- NaN fails n == n; ±inf fails the abs check.
	return n == n and math.abs(n) ~= math.huge
end

local function snapAxis(value: number, origin: number): number
	return math.floor((value - origin) / BLOCK_SIZE) * BLOCK_SIZE + origin + HALF
end

--[[
	Returns the center of the grid cell containing `position`. Idempotent: snapping a cell
	center returns the same center. Expects a finite Vector3; use `check` for untrusted input.
]]
function PlacementRules.snap(position: Vector3): Vector3
	return Vector3.new(
		snapAxis(position.X, 0),
		snapAxis(position.Y, PlacementRules.GROUND_Y),
		snapAxis(position.Z, 0)
	)
end

--[[
	Cell for a block placed against a surface hit by a raycast. A hit point sits exactly on a
	cell boundary, so it is pushed half a block out along the surface normal first: clicking
	the Baseplate or the top of a block gives the cell above it, clicking a block's side gives
	the cell beside it.
]]
function PlacementRules.snapFromHit(hitPosition: Vector3, hitNormal: Vector3): Vector3
	return PlacementRules.snap(hitPosition + hitNormal * HALF)
end

local function getRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end
	return nil
end

--[[
	Checks whether `player` may place a block of `blockType` at `position`.

	`blockType` and `position` may be anything (they come straight off a remote). `position` is
	snapped before checking, so either a raw point or a cell center works. `blocksFolder` holds
	the already placed blocks; don't parent the ghost preview to it.

	Returns `true, nil, cellCenter` on success, or `false, reason` with a short loggable reason.
]]
function PlacementRules.check(
	player: Player,
	blockType: unknown,
	position: unknown,
	blocksFolder: Instance
): (boolean, string?, Vector3?)
	if type(blockType) ~= "string" or not VALID_BLOCK_TYPES[blockType] then
		return false, "invalid block type"
	end

	if typeof(position) ~= "Vector3" then
		return false, "position is not a Vector3"
	end
	local rawPosition = position :: Vector3
	if
		not (
			isFiniteNumber(rawPosition.X)
			and isFiniteNumber(rawPosition.Y)
			and isFiniteNumber(rawPosition.Z)
		)
	then
		return false, "position is not finite"
	end

	local cell = PlacementRules.snap(rawPosition)
	-- snap can still produce inf/NaN from values near the float limit.
	if not (isFiniteNumber(cell.X) and isFiniteNumber(cell.Y) and isFiniteNumber(cell.Z)) then
		return false, "position is not finite"
	end

	if cell.Y - HALF < PlacementRules.GROUND_Y then
		return false, "below ground"
	end
	if cell.Y + HALF > PlacementRules.GROUND_Y + PlacementRules.MAX_HEIGHT then
		return false, "above height limit"
	end

	local rootPart = getRootPart(player)
	if not rootPart then
		return false, "no character"
	end
	if (cell - rootPart.Position).Magnitude > PlacementRules.MAX_REACH then
		return false, "out of reach"
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { blocksFolder }
	overlapParams.MaxParts = 1
	local hits = Workspace:GetPartBoundsInBox(CFrame.new(cell), OVERLAP_BOX_SIZE, overlapParams)
	if #hits > 0 then
		return false, "overlaps a block"
	end

	return true, nil, cell
end

return table.freeze(PlacementRules)
