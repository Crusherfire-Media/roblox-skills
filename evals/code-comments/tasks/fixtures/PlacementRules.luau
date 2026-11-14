--!strict
local BlockTypes = require(script.Parent.BlockTypes)

local PlacementRules = {}

PlacementRules.BLOCK_SIZE = 4
PlacementRules.MAX_HEIGHT = 200
PlacementRules.MAX_REACH = 24 -- studs, from the HumanoidRootPart to the block's center

local function isFiniteNumber(value: number): boolean
	-- value == value is false only for NaN, which passes every range check
	return value == value and math.abs(value) ~= math.huge
end

--[[
	Returns the center of the grid cell that contains position. Cells start at the top of the
	Baseplate (Y = 0), so a block placed there rests on it.
]]
function PlacementRules.snap(position: Vector3): Vector3
	local size = PlacementRules.BLOCK_SIZE
	return Vector3.new(
		(math.floor(position.X / size) + 0.5) * size,
		(math.floor(position.Y / size) + 0.5) * size,
		(math.floor(position.Z / size) + 0.5) * size
	)
end

--[[
	Checks a placement request. Safe to call with raw remote arguments. Returns true and the
	snapped center, or false and a reason for the server log. Blocks already in blocksFolder
	count as occupied.
]]
function PlacementRules.validate(
	blockType: unknown,
	position: unknown,
	character: Model?,
	blocksFolder: Instance
): (boolean, Vector3 | string)
	if not BlockTypes.isBlockType(blockType) then
		return false, "unknown block type"
	end
	if typeof(position) ~= "Vector3" then
		return false, "position is not a Vector3"
	end
	if
		not (
			isFiniteNumber(position.X)
			and isFiniteNumber(position.Y)
			and isFiniteNumber(position.Z)
		)
	then
		return false, "position is not finite"
	end

	local center = PlacementRules.snap(position)
	if center.Y < 0 or center.Y > PlacementRules.MAX_HEIGHT then
		return false, "out of height range"
	end

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false, "no character"
	end
	if (root.Position - center).Magnitude > PlacementRules.MAX_REACH then
		return false, "out of reach"
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { blocksFolder }
	-- Shrink the box so blocks that only share a face don't count as overlapping
	local box = Vector3.one * (PlacementRules.BLOCK_SIZE - 0.1)
	if #workspace:GetPartBoundsInBox(CFrame.new(center), box, params) > 0 then
		return false, "cell is occupied"
	end

	return true, center
end

return PlacementRules
