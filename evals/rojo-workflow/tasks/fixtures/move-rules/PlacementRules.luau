--[[
	Decides whether a block may be placed. MaxReach and MaxHeight are attributes on this
	ModuleScript so designers can tune them in Studio's Properties window.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local MAX_REACH: number = script:GetAttribute("MaxReach")
local MAX_HEIGHT: number = script:GetAttribute("MaxHeight")
assert(typeof(MAX_REACH) == "number", "PlacementRules needs a MaxReach attribute")
assert(typeof(MAX_HEIGHT) == "number", "PlacementRules needs a MaxHeight attribute")

local PlacementRules = {}

local function snapAxis(value: number): number
	local size = BlockTypes.BlockSize
	return (math.floor(value / size) + 0.5) * size
end

--[[
	Returns the center of the grid cell that contains position.
]]
function PlacementRules.snap(position: Vector3): Vector3
	return Vector3.new(snapAxis(position.X), snapAxis(position.Y), snapAxis(position.Z))
end

--[[
	Checks a placement request. Returns true and the cell's center, or false and a reason for the
	server log.
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
	if typeof(position) ~= "Vector3" or position ~= position then
		return false, "bad position"
	end

	local center = PlacementRules.snap(position)
	if center.Y < 0 or center.Y > MAX_HEIGHT then
		return false, "out of height range"
	end
	if rootPosition == nil or (rootPosition - center).Magnitude > MAX_REACH then
		return false, "out of reach"
	end
	if occupied[center] then
		return false, "cell is occupied"
	end

	return true, center
end

return PlacementRules
