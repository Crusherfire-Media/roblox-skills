--!strict

const BLOCK_SIZE = 4
const MAX_HEIGHT = 200
const MAX_REACH = 24
-- Shrinks the overlap query so blocks that only share a face don't count
const TOUCH_TOLERANCE = 0.1

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type FailureReason =
	"InvalidBlockType"
	| "InvalidPosition"
	| "TooLow"
	| "TooHigh"
	| "NoCharacter"
	| "TooFar"
	| "Overlapping"

export type PlacementContext = {
	Baseplate: BasePart,
	-- Every placed block is a BasePart descendant with CanQuery left on
	BlocksFolder: Instance,
}

export type PlacementResult =
	{ Ok: true, BlockType: BlockType, Position: Vector3 }
	| { Ok: false, Reason: FailureReason }

const Module = {}

Module.BlockSize = BLOCK_SIZE
Module.BlockTypes = { "Brick", "Dirt", "Grass", "Window", "Wood" } :: { BlockType }

const IS_BLOCK_TYPE: { [string]: boolean? } = {}
for _, blockType in Module.BlockTypes do
	IS_BLOCK_TYPE[blockType] = true
end

local function isFiniteNumber(value: number): boolean
	-- value == value is false only for NaN
	return value == value and math.abs(value) ~= math.huge
end

local function isFiniteVector(vector: Vector3): boolean
	return isFiniteNumber(vector.X) and isFiniteNumber(vector.Y) and isFiniteNumber(vector.Z)
end

local function getGroundY(baseplate: BasePart): number
	return baseplate.Position.Y + baseplate.Size.Y / 2
end

local function snapAxis(value: number, origin: number): number
	local cellIndex = math.floor((value - origin) / BLOCK_SIZE)
	return origin + cellIndex * BLOCK_SIZE + BLOCK_SIZE / 2
end

local function overlapsPlacedBlock(position: Vector3, blocksFolder: Instance): boolean
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { blocksFolder }

	local querySize = Vector3.one * (BLOCK_SIZE - TOUCH_TOLERANCE)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(position), querySize, overlapParams)
	return #parts > 0
end

function Module.isBlockType(value: unknown): boolean
	return typeof(value) == "string" and IS_BLOCK_TYPE[value] == true
end

--[[
	Returns the center of the grid cell containing position. For a raycast
	hit, pass a point nudged off the surface along the normal, such as
	`result.Position + result.Normal * 0.5`, or a hit on the side of a
	block snaps into that block instead of next to it.
]]
function Module.snapPosition(position: Vector3, baseplate: BasePart): Vector3
	return Vector3.new(
		snapAxis(position.X, 0),
		snapAxis(position.Y, getGroundY(baseplate)),
		snapAxis(position.Z, 0)
	)
end

--[[
	Checks a placement request and never errors, so blockType and position
	can come straight from a remote. On success, Position is the snapped
	cell center to place the block at.
]]
function Module.validate(
	player: Player,
	blockType: unknown,
	position: unknown,
	context: PlacementContext
): PlacementResult
	if not Module.isBlockType(blockType) then
		return { Ok = false, Reason = "InvalidBlockType" }
	end
	if typeof(position) ~= "Vector3" or not isFiniteVector(position) then
		return { Ok = false, Reason = "InvalidPosition" }
	end

	local snappedPosition = Module.snapPosition(position, context.Baseplate)
	local groundY = getGroundY(context.Baseplate)
	if snappedPosition.Y - BLOCK_SIZE / 2 < groundY then
		return { Ok = false, Reason = "TooLow" }
	end
	if snappedPosition.Y + BLOCK_SIZE / 2 > groundY + MAX_HEIGHT then
		return { Ok = false, Reason = "TooHigh" }
	end

	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not rootPart or not rootPart:IsA("BasePart") then
		return { Ok = false, Reason = "NoCharacter" }
	end
	if (snappedPosition - rootPart.Position).Magnitude > MAX_REACH then
		return { Ok = false, Reason = "TooFar" }
	end

	if overlapsPlacedBlock(snappedPosition, context.BlocksFolder) then
		return { Ok = false, Reason = "Overlapping" }
	end

	return { Ok = true, BlockType = blockType :: BlockType, Position = snappedPosition }
end

return Module
