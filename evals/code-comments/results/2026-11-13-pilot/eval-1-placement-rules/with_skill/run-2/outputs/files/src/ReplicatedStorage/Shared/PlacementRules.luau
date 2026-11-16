--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Block placement rules shared by the client's ghost preview and the
	server's placement handler, so both accept and reject the same spots.
]]

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type RejectReason =
	"UnknownBlockType"
	| "InvalidPosition"
	| "BelowGround"
	| "TooHigh"
	| "NoCharacter"
	| "TooFar"
	| "Occupied"

export type PlacementContext = {
	RootPart: BasePart?,
	BlocksFolder: Instance,
}

export type PlacementResult =
	{
		Ok: true,
		BlockType: BlockType,
		Position: Vector3,
	}
	| {
		Ok: false,
		Reason: RejectReason,
	}

const BLOCK_TYPES = table.freeze({ "Brick", "Dirt", "Grass", "Window", "Wood" } :: { BlockType })
const BLOCK_SIZE = 4
const HALF_BLOCK = BLOCK_SIZE / 2
-- Top of Workspace.Baseplate; keep in sync with default.project.json
const GROUND_Y = 0
const MAX_HEIGHT = 200
const MAX_REACH = 24
-- Shrinks the overlap query so blocks sharing a face don't count as overlapping
const OVERLAP_TOLERANCE = 0.1

local isBlockTypeSet: { [string]: true? } = {}
for _, blockType in BLOCK_TYPES do
	isBlockTypeSet[blockType] = true
end

local Module = {}

Module.BlockTypes = BLOCK_TYPES
Module.BlockSize = BLOCK_SIZE

local function isFinite(value: number): boolean
	-- value ~= value catches NaN, which passes every range check
	return value == value and math.abs(value) ~= math.huge
end

local function snapAxis(value: number, origin: number): number
	return origin + (math.floor((value - origin) / BLOCK_SIZE) + 0.5) * BLOCK_SIZE
end

local function isOccupied(center: Vector3, blocksFolder: Instance): boolean
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { blocksFolder }
	overlapParams.MaxParts = 1

	const size = Vector3.one * (BLOCK_SIZE - OVERLAP_TOLERANCE)
	return #workspace:GetPartBoundsInBox(CFrame.new(center), size, overlapParams) > 0
end

--[[
	Returns whether a value is one of the placeable block type names.
]]
function Module.isBlockType(value: unknown): boolean
	return typeof(value) == "string" and isBlockTypeSet[value] == true
end

--[[
	Returns the center of the grid cell that contains point. Pass a point
	inside the target cell, such as a raycast hit position plus its normal
	times half the block size: a point exactly on a face can round into the
	cell on the wrong side.
]]
function Module.snapToGrid(point: Vector3): Vector3
	return Vector3.new(snapAxis(point.X, 0), snapAxis(point.Y, GROUND_Y), snapAxis(point.Z, 0))
end

--[[
	Checks a placement request. blockType and position may be anything a
	client sent; position is snapped to the grid before it is checked, and on
	success the result holds the snapped position to place the block at.

	Never errors. Overlap uses a spatial query, so placed blocks must be in
	Workspace with CanQuery left on.
]]
function Module.check(
	blockType: unknown,
	position: unknown,
	context: PlacementContext
): PlacementResult
	if not Module.isBlockType(blockType) then
		return { Ok = false, Reason = "UnknownBlockType" }
	end

	if
		typeof(position) ~= "Vector3"
		or not isFinite(position.X)
		or not isFinite(position.Y)
		or not isFinite(position.Z)
	then
		return { Ok = false, Reason = "InvalidPosition" }
	end

	const center = Module.snapToGrid(position)
	if center.Y - HALF_BLOCK < GROUND_Y then
		return { Ok = false, Reason = "BelowGround" }
	end

	if center.Y + HALF_BLOCK > GROUND_Y + MAX_HEIGHT then
		return { Ok = false, Reason = "TooHigh" }
	end

	const rootPart = context.RootPart
	if not rootPart then
		return { Ok = false, Reason = "NoCharacter" }
	end

	if (center - rootPart.Position).Magnitude > MAX_REACH then
		return { Ok = false, Reason = "TooFar" }
	end

	if isOccupied(center, context.BlocksFolder) then
		return { Ok = false, Reason = "Occupied" }
	end

	return { Ok = true, BlockType = blockType :: BlockType, Position = center }
end

return Module
