--[[
	Placement rules for the block game. Shared so the client can preview whether the server will
	accept a placement. Pure functions: they read no instances and no engine state.
]]

local BlockTypes = require(script.Parent.BlockTypes)

local PlacementRules = {}

-- Highest a cell's center may be, in studs above the Baseplate's top (Y = 0).
PlacementRules.MaxHeight = 200
-- Farthest a cell's center may be from the player's HumanoidRootPart, in studs.
PlacementRules.MaxReach = 24

local function isFinite(value: number): boolean
	-- NaN is the only value not equal to itself.
	return value == value and math.abs(value) ~= math.huge
end

local function snapAxis(value: number): number
	local size = BlockTypes.BlockSize
	return (math.floor(value / size) + 0.5) * size
end

--[[
	Returns the center of the grid cell that contains position. Cells are BlockTypes.BlockSize
	studs on each side and line up with the origin, so the cell resting on the Baseplate has its
	center at Y = BlockSize / 2.
]]
function PlacementRules.snap(position: Vector3): Vector3
	return Vector3.new(snapAxis(position.X), snapAxis(position.Y), snapAxis(position.Z))
end

--[[
	Checks a placement request. Safe to call with raw remote arguments.

	A request is accepted when all of these hold:
	- blockTypeName names a block type in BlockTypes.
	- position is a Vector3 with finite components.
	- the snapped cell's center is above the Baseplate (Y > 0) and no higher than MaxHeight.
	- the player has a character (rootPosition is not nil) whose root is within MaxReach studs of
	  the cell's center. A cell exactly MaxReach away is in reach.
	- occupied doesn't already hold the cell's center.

	Returns true and the cell's center, or false and a short reason for the server log. Never
	changes occupied; the caller marks the cell once the block exists.
]]
function PlacementRules.validate(
	blockTypeName: unknown,
	position: unknown,
	rootPosition: Vector3?,
	occupied: { [Vector3]: boolean }
): (boolean, Vector3 | string)
	if typeof(blockTypeName) ~= "string" or not BlockTypes.ByName[blockTypeName] then
		return false, "unknown block type"
	end
	if typeof(position) ~= "Vector3" then
		return false, "position is not a Vector3"
	end
	if not (isFinite(position.X) and isFinite(position.Y) and isFinite(position.Z)) then
		return false, "position is not finite"
	end

	local center = PlacementRules.snap(position)
	if center.Y < 0 or center.Y > PlacementRules.MaxHeight then
		return false, "out of height range"
	end

	if rootPosition == nil then
		return false, "no character"
	end
	if (rootPosition - center).Magnitude >= PlacementRules.MaxReach then
		return false, "out of reach"
	end

	if occupied[center] then
		return false, "cell is occupied"
	end

	return true, center
end

return PlacementRules
