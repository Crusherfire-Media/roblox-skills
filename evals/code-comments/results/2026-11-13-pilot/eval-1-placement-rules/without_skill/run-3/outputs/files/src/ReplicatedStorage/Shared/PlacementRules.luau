--!strict
-- Block placement rules shared by the client (ghost preview) and the server (request validation).
-- Both sides must call the same functions so a spot the preview shows as valid is one the server
-- accepts.

local PlacementRules = {}

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

local blockTypes: { BlockType } = { "Brick", "Dirt", "Grass", "Window", "Wood" }
PlacementRules.BLOCK_TYPES = table.freeze(blockTypes)

-- Edge length of a block, and the grid spacing.
PlacementRules.BLOCK_SIZE = 4
-- Top surface of Workspace.Baseplate (see default.project.json). Hard-coded rather than read from
-- the Baseplate so the client doesn't depend on that part having streamed in.
PlacementRules.GROUND_Y = 0
-- No part of a block may be higher than this many studs above the ground.
PlacementRules.MAX_HEIGHT = 200
-- Max distance from the HumanoidRootPart to the block's center.
PlacementRules.MAX_REACH = 24

local BLOCK_SIZE = PlacementRules.BLOCK_SIZE
local HALF_BLOCK = BLOCK_SIZE / 2
local GROUND_Y = PlacementRules.GROUND_Y
local MAX_TOP_Y = GROUND_Y + PlacementRules.MAX_HEIGHT
local MAX_REACH = PlacementRules.MAX_REACH

-- Shapes closer than this along an axis count as touching, not overlapping, which absorbs float
-- error on blocks whose faces share a plane.
local OVERLAP_TOLERANCE = 0.01

local blockTypeSet: { [string]: true } = {}
for _, name in PlacementRules.BLOCK_TYPES do
	blockTypeSet[name] = true
end

local function isFinite(n: number): boolean
	-- NaN fails n == n; infinities fail the abs check.
	return n == n and math.abs(n) ~= math.huge
end

local function isFiniteVector(v: Vector3): boolean
	return isFinite(v.X) and isFinite(v.Y) and isFinite(v.Z)
end

local function snapAxis(value: number, origin: number): number
	return math.floor((value - origin) / BLOCK_SIZE) * BLOCK_SIZE + origin + HALF_BLOCK
end

function PlacementRules.isBlockType(value: unknown): boolean
	return type(value) == "string" and blockTypeSet[value] == true
end

-- Returns the center of the grid cell containing `position`. Cells are BLOCK_SIZE cubes whose
-- bottoms sit at GROUND_Y + k * BLOCK_SIZE, so a block in the lowest layer rests on the Baseplate.
--
-- Pass the raycast hit normal when snapping a mouse hit: the point is pushed half a block out of the
-- clicked surface first, so clicking any face of an existing block picks the cell next to that face
-- instead of the block's own cell. Snapping a cell center again returns the same center, so the
-- server can safely re-snap whatever the client sends.
function PlacementRules.snap(position: Vector3, surfaceNormal: Vector3?): Vector3
	if surfaceNormal then
		position += surfaceNormal * HALF_BLOCK
	end
	return Vector3.new(
		snapAxis(position.X, 0),
		snapAxis(position.Y, GROUND_Y),
		snapAxis(position.Z, 0)
	)
end

-- World-space center and half-extents of the axis-aligned box around `instance`, or nil if it isn't
-- a part or model.
local function getBounds(instance: Instance): (Vector3?, Vector3?)
	local cframe: CFrame, size: Vector3
	if instance:IsA("BasePart") then
		cframe, size = instance.CFrame, instance.Size
	elseif instance:IsA("Model") then
		cframe, size = instance:GetBoundingBox()
	else
		return nil, nil
	end
	-- Project the (possibly rotated) box onto the world axes.
	local half = size / 2
	local right, up, back = cframe.XVector, cframe.YVector, cframe.ZVector
	local extents = Vector3.new(
		math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(back.X) * half.Z,
		math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(back.Y) * half.Z,
		math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(back.Z) * half.Z
	)
	return cframe.Position, extents
end

local function overlapsPlacedBlock(center: Vector3, blocksFolder: Instance): boolean
	local limit = HALF_BLOCK - OVERLAP_TOLERANCE
	for _, child in blocksFolder:GetChildren() do
		local otherCenter, otherHalf = getBounds(child)
		if otherCenter and otherHalf then
			local gap = (otherCenter - center):Abs()
			if
				gap.X < limit + otherHalf.X
				and gap.Y < limit + otherHalf.Y
				and gap.Z < limit + otherHalf.Z
			then
				return true
			end
		end
	end
	return false
end

-- Checks whether `player` may place `blockType` at `position`. Arguments other than `player` and
-- `blocksFolder` can be anything a client sent over a remote; bad values are rejected, never
-- errored on.
--
-- On success returns the snapped cell center to place the block at. On failure returns nil and a
-- short reason for logging.
function PlacementRules.check(
	player: Player,
	blockType: unknown,
	position: unknown,
	blocksFolder: Instance
): (Vector3?, string?)
	if not PlacementRules.isBlockType(blockType) then
		return nil, "invalid block type"
	end
	if typeof(position) ~= "Vector3" or not isFiniteVector(position) then
		return nil, "invalid position"
	end

	local center = PlacementRules.snap(position)
	if center.Y - HALF_BLOCK < GROUND_Y then
		return nil, "below ground"
	end
	if center.Y + HALF_BLOCK > MAX_TOP_Y then
		return nil, "too high"
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		return nil, "no character"
	end
	if (center - rootPart.Position).Magnitude > MAX_REACH then
		return nil, "out of reach"
	end

	if overlapsPlacedBlock(center, blocksFolder) then
		return nil, "overlaps a block"
	end

	return center, nil
end

return table.freeze(PlacementRules)
