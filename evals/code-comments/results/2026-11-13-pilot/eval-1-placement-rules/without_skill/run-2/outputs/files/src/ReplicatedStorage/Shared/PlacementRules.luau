--[[
	Shared block placement rules, used by the client (ghost preview tint) and the server
	(validating remote requests). Both sides must call the same functions so they agree.

	Usage:
		-- Client, from a mouse/raycast hit:
		local cell = PlacementRules.snapFromSurface(result.Position, result.Normal)
		local ok = PlacementRules.validate(player, blockType, cell, placedFolder) ~= nil

		-- Server, with whatever arrived over the remote:
		local cell, reason = PlacementRules.validate(player, blockType, position, placedFolder)
		if not cell then
			warn(`{player.Name} placement rejected: {reason}`)
			return
		end
		-- place a block centred on `cell`
]]

local PlacementRules = {}

-- In the order the picker UI should show them.
PlacementRules.BLOCK_TYPES = table.freeze({ "Brick", "Dirt", "Grass", "Window", "Wood" })

PlacementRules.BLOCK_SIZE = 4
-- Y of the top face of Workspace.Baseplate (see default.project.json). The grid starts here.
PlacementRules.GROUND_Y = 0
PlacementRules.MAX_HEIGHT = 200 -- studs above GROUND_Y that a block's top may reach
PlacementRules.MAX_REACH = 24 -- studs from HumanoidRootPart to the block's centre

local VALID_TYPES: { [string]: true } = {}
for _, name in PlacementRules.BLOCK_TYPES do
	VALID_TYPES[name] = true
end

local SIZE = PlacementRules.BLOCK_SIZE
local HALF = SIZE / 2
-- Shrinks the overlap query box so blocks sharing a face don't count as overlapping.
local OVERLAP_INSET = 0.1

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

function PlacementRules.isValidBlockType(blockType: unknown): boolean
	return type(blockType) == "string" and VALID_TYPES[blockType] == true
end

--[[
	Returns the centre of the grid cell containing `position`. Cells are SIZE studs wide and
	aligned so their bottoms sit on GROUND_Y + n * SIZE, so a block on the ground rests on it.
]]
function PlacementRules.snap(position: Vector3): Vector3
	local function snapAxis(value: number, origin: number): number
		return math.floor((value - origin) / SIZE) * SIZE + origin + HALF
	end
	return Vector3.new(
		snapAxis(position.X, 0),
		snapAxis(position.Y, PlacementRules.GROUND_Y),
		snapAxis(position.Z, 0)
	)
end

--[[
	Snaps a raycast hit to the cell on the outside of the clicked face. A hit point lies exactly
	on a cell boundary, so it's nudged half a block along the surface normal first; otherwise
	clicking the side or underside of a block could pick the block's own cell.
]]
function PlacementRules.snapFromSurface(hitPosition: Vector3, normal: Vector3): Vector3
	return PlacementRules.snap(hitPosition + normal * HALF)
end

--[[
	Checks a placement request. `position` may be any point inside the target cell (it's snapped
	here) and both `blockType` and `position` may be untrusted garbage.

	Returns the snapped block centre on success, or nil and a short reason on failure.
]]
function PlacementRules.validate(
	player: Player,
	blockType: unknown,
	position: unknown,
	placedFolder: Instance
): (Vector3?, string?)
	if not PlacementRules.isValidBlockType(blockType) then
		return nil, "invalid block type"
	end

	if typeof(position) ~= "Vector3" then
		return nil, "position is not a Vector3"
	end
	local pos = position :: Vector3
	-- NaN would slip past every comparison below, so reject it (and infinities) up front.
	if not (isFinite(pos.X) and isFinite(pos.Y) and isFinite(pos.Z)) then
		return nil, "position is not finite"
	end

	local cell = PlacementRules.snap(pos)

	local bottom = cell.Y - HALF
	local top = cell.Y + HALF
	if bottom < PlacementRules.GROUND_Y then
		return nil, "below ground"
	end
	if top > PlacementRules.GROUND_Y + PlacementRules.MAX_HEIGHT then
		return nil, "too high"
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		return nil, "no character"
	end
	if (cell - rootPart.Position).Magnitude > PlacementRules.MAX_REACH then
		return nil, "out of reach"
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { placedFolder }
	local inset = SIZE - OVERLAP_INSET * 2
	local hits =
		workspace:GetPartBoundsInBox(CFrame.new(cell), Vector3.new(inset, inset, inset), params)
	if #hits > 0 then
		return nil, "space occupied"
	end

	return cell, nil
end

return table.freeze(PlacementRules)
