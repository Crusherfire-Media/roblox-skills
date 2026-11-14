--!strict

const BLOCK_SIZE = 4
-- Top face of Workspace.Baseplate. Keep in sync with default.project.json.
const GROUND_HEIGHT = 0
const MAX_HEIGHT = GROUND_HEIGHT + 200
const MAX_REACH = 24
-- Bounds queries count touching faces as overlap, so neighbors would be rejected
const OVERLAP_SHRINK = 0.1

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type FailureReason =
	"InvalidBlockType"
	| "InvalidPosition"
	| "BelowGround"
	| "TooHigh"
	| "NoCharacter"
	| "TooFar"
	| "Overlaps"

export type PlacementResult =
	{
		Success: true,
		Position: Vector3,
	}
	| {
		Success: false,
		Reason: FailureReason,
	}

const BLOCK_TYPES: { BlockType } = { "Brick", "Dirt", "Grass", "Window", "Wood" }

const isBlockTypeName: { [string]: true? } = {}
for _, blockType in BLOCK_TYPES do
	isBlockTypeName[blockType] = true
end

local Module = {}

Module.BlockSize = BLOCK_SIZE
Module.BlockTypes = table.freeze(table.clone(BLOCK_TYPES))

local function isFiniteNumber(value: number): boolean
	-- value == value is false only for NaN
	return value == value and math.abs(value) ~= math.huge
end

local function snapAxis(value: number, origin: number): number
	return origin + (math.floor((value - origin) / BLOCK_SIZE) + 0.5) * BLOCK_SIZE
end

local function getRootPart(player: Player): BasePart?
	const character = player.Character
	if not character then
		return nil
	end
	const rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end
	return nil
end

local function overlapsPlacedBlock(center: Vector3, blocksFolder: Instance): boolean
	const overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { blocksFolder }
	overlapParams.MaxParts = 1

	const size = Vector3.one * (BLOCK_SIZE - OVERLAP_SHRINK)
	const parts = workspace:GetPartBoundsInBox(CFrame.new(center), size, overlapParams)
	return #parts > 0
end

function Module.isBlockType(value: unknown): boolean
	return typeof(value) == "string" and isBlockTypeName[value] == true
end

--[[
	Returns the center of the grid cell containing `point`. Cells are
	BLOCK_SIZE cubes whose bottom layer rests on the Baseplate.
]]
function Module.snapPosition(point: Vector3): Vector3
	return Vector3.new(snapAxis(point.X, 0), snapAxis(point.Y, GROUND_HEIGHT), snapAxis(point.Z, 0))
end

--[[
	Returns the center of the cell next to the surface a raycast hit. Use this
	for mouse placement: a hit lies exactly on a cell boundary, so snapping the
	raw hit position can pick the cell behind the surface.
]]
function Module.snapFromSurface(hitPosition: Vector3, hitNormal: Vector3): Vector3
	return Module.snapPosition(hitPosition + hitNormal * (BLOCK_SIZE / 2))
end

--[[
	Checks whether `player` may place a block of `blockType` at `position`.
	Both values may be anything a client sent; bad input fails with a reason
	instead of erroring. `position` is snapped to the grid first, and on
	success the result holds the snapped center to place the block at.
]]
function Module.validate(
	player: Player,
	blockType: unknown,
	position: unknown,
	blocksFolder: Instance
): PlacementResult
	if not Module.isBlockType(blockType) then
		return { Success = false, Reason = "InvalidBlockType" }
	end

	if typeof(position) ~= "Vector3" then
		return { Success = false, Reason = "InvalidPosition" }
	end
	if
		not (
			isFiniteNumber(position.X)
			and isFiniteNumber(position.Y)
			and isFiniteNumber(position.Z)
		)
	then
		return { Success = false, Reason = "InvalidPosition" }
	end

	const center = Module.snapPosition(position)
	const halfSize = BLOCK_SIZE / 2
	if center.Y - halfSize < GROUND_HEIGHT then
		return { Success = false, Reason = "BelowGround" }
	end
	if center.Y + halfSize > MAX_HEIGHT then
		return { Success = false, Reason = "TooHigh" }
	end

	const rootPart = getRootPart(player)
	if not rootPart then
		return { Success = false, Reason = "NoCharacter" }
	end
	if (rootPart.Position - center).Magnitude > MAX_REACH then
		return { Success = false, Reason = "TooFar" }
	end

	if overlapsPlacedBlock(center, blocksFolder) then
		return { Success = false, Reason = "Overlaps" }
	end

	return { Success = true, Position = center }
end

return Module
