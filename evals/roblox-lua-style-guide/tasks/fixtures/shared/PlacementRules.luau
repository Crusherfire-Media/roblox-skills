--!strict
-- Where a block may go. The client uses it to preview a placement and the server to accept one,
-- so both always agree.

local BlockTypes = require("./BlockTypes")

local PlacementRules = {}

PlacementRules.MaxHeight = 200
-- Studs from the HumanoidRootPart to the block's center.
PlacementRules.MaxReach = 24

--[[
	Returns the center of the grid cell that holds position. Cells start at the top of the
	Baseplate (Y = 0), so a block in the lowest row rests on it.
]]
function PlacementRules.snap(position: Vector3): Vector3
	local size = BlockTypes.BlockSize
	return Vector3.new(
		(math.floor(position.X / size) + 0.5) * size,
		(math.floor(position.Y / size) + 0.5) * size,
		(math.floor(position.Z / size) + 0.5) * size
	)
end

--[[
	Checks whether a block can go in the cell centered at center. Returns true, or false and a
	short reason. Parts inside blocksFolder count as placed blocks.
]]
function PlacementRules.check(
	center: Vector3,
	character: Model?,
	blocksFolder: Instance
): (boolean, string?)
	if center.Y < 0 or center.Y > PlacementRules.MaxHeight then
		return false, "OutOfHeightRange"
	end

	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return false, "NoCharacter"
	end
	if (root.Position - center).Magnitude > PlacementRules.MaxReach then
		return false, "OutOfReach"
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { blocksFolder }
	-- Shrink the box so blocks that only share a face don't count as overlapping.
	local box = Vector3.one * (BlockTypes.BlockSize - 0.1)
	if #workspace:GetPartBoundsInBox(CFrame.new(center), box, params) > 0 then
		return false, "Occupied"
	end

	return true, nil
end

return PlacementRules
