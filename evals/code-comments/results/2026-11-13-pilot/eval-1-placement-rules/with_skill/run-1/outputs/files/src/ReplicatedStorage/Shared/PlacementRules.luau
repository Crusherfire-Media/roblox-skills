--!strict
--@author: Crusherfire
--@date: 11/13/2026
--[[@description:
	Block placement rules shared by the client's ghost preview and the
	server's placement handler, so both accept and reject the same spots.
]]

------------------------------
-- TYPES --
------------------------------

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type PlacementContext = {
	Baseplate: BasePart,
	-- Holds every placed block; checked for overlaps.
	BlocksFolder: Instance,
	-- The player placing the block; distance is measured from their
	-- HumanoidRootPart.
	Player: Player,
}

export type PlacementResult =
	{
		Success: true,
		BlockType: BlockType,
		Position: Vector3,
	}
	| {
		Success: false,
		Reason: string,
	}

------------------------------
-- VARIABLES --
------------------------------

const BLOCK_SIZE = 4
const MAX_HEIGHT = 200
const MAX_DISTANCE = 24
-- Absorbs float error in the height checks, and shrinks the overlap query so
-- blocks that share a face do not count as overlapping.
const EPSILON = 0.01

const BLOCK_TYPES: { [string]: BlockType? } = {
	Brick = "Brick",
	Dirt = "Dirt",
	Grass = "Grass",
	Window = "Window",
	Wood = "Wood",
}

local Module = {}

Module.BlockSize = BLOCK_SIZE

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------

local function isFiniteNumber(value: number): boolean
	-- value ~= value catches NaN, which passes every range check
	return value == value and math.abs(value) ~= math.huge
end

local function snapAxis(value: number, origin: number): number
	return (math.floor((value - origin) / BLOCK_SIZE) + 0.5) * BLOCK_SIZE + origin
end

local function getGroundY(baseplate: BasePart): number
	return baseplate.Position.Y + baseplate.Size.Y / 2
end

local function failure(reason: string): PlacementResult
	return { Success = false, Reason = reason }
end

------------------------------
-- PUBLIC FUNCTIONS --
------------------------------

--[[
	Returns the center of the grid cell that contains `position`. The grid is
	BLOCK_SIZE studs, aligned to the Baseplate's corner and top surface, so a
	block in the lowest layer rests on the Baseplate.

	A point exactly on a cell boundary belongs to the cell on its positive
	side. For a mouse hit, offset the hit position along the surface normal
	(for example by BLOCK_SIZE / 2) so the point lands in the cell in front of
	the face rather than inside the block that was clicked.
]]
function Module.snapPosition(position: Vector3, baseplate: BasePart): Vector3
	const corner = baseplate.Position - baseplate.Size / 2
	return Vector3.new(
		snapAxis(position.X, corner.X),
		snapAxis(position.Y, getGroundY(baseplate)),
		snapAxis(position.Z, corner.Z)
	)
end

--[[
	Checks a placement request and returns the snapped position to place the
	block at, or a short reason for rejecting it. `blockType` and `position`
	may be anything a client sends; this never errors on bad input.
]]
function Module.validatePlacement(
	blockType: unknown,
	position: unknown,
	context: PlacementContext
): PlacementResult
	if typeof(blockType) ~= "string" then
		return failure("block type is not a string")
	end
	const validBlockType = BLOCK_TYPES[blockType]
	if not validBlockType then
		return failure("unknown block type")
	end

	-- Vector3 stores 32-bit floats, so huge numbers arrive as infinity
	if typeof(position) ~= "Vector3" then
		return failure("position is not a Vector3")
	end
	if
		not isFiniteNumber(position.X)
		or not isFiniteNumber(position.Y)
		or not isFiniteNumber(position.Z)
	then
		return failure("position is not finite")
	end

	const snapped = Module.snapPosition(position, context.Baseplate)
	const groundY = getGroundY(context.Baseplate)
	const halfSize = BLOCK_SIZE / 2
	if snapped.Y - halfSize < groundY - EPSILON then
		return failure("below the Baseplate")
	end
	if snapped.Y + halfSize > groundY + MAX_HEIGHT + EPSILON then
		return failure("above the height limit")
	end

	const character = context.Player.Character
	const rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not rootPart or not rootPart:IsA("BasePart") then
		return failure("player has no character")
	end
	if (snapped - rootPart.Position).Magnitude > MAX_DISTANCE then
		return failure("too far from the player")
	end

	const overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { context.BlocksFolder }
	const querySize = Vector3.one * (BLOCK_SIZE - EPSILON * 2)
	const overlapping = workspace:GetPartBoundsInBox(CFrame.new(snapped), querySize, overlapParams)
	if #overlapping > 0 then
		return failure("overlaps a placed block")
	end

	return {
		Success = true,
		BlockType = validBlockType :: BlockType,
		Position = snapped,
	}
end

return Module
